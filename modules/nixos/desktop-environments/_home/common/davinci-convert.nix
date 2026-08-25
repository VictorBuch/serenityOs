{
  config,
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
let
  optPath = [ "home" "desktop" "common" "davinci-convert" ];
  cfg = lib.attrByPath optPath { enable = false; } config;

  convertDir = "${config.home.homeDirectory}/Videos/convert_queue";
  convertedDir = "${config.home.homeDirectory}/Videos/converted";
  progressDir = "${config.home.homeDirectory}/.local/state/davinci-convert";

  # The main conversion script
  davinciConvertScript = pkgs.writeShellScriptBin "davinci-convert" ''
    #!/usr/bin/env bash

    # DaVinci Resolve Studio (Linux) media conditioner.
    #
    # Studio decodes H.264/H.265 natively, so the video stream is copied
    # untouched whenever possible. What Resolve on Linux still cannot read is
    # compressed audio (AAC, MP3, AC3, Opus, Vorbis, ...) — those tracks are
    # re-encoded to PCM and the result is written to a .mov container.
    #
    # Usage: davinci-convert [file ...]
    #   With no arguments it processes everything in the queue directory.

    set -o pipefail

    media_in="${convertDir}"
    media_out="${convertedDir}"

    PROGRESS_DIR="${progressDir}"
    PROGRESS_FILE="$PROGRESS_DIR/progress.json"
    mkdir -p "$media_in" "$media_out" "$PROGRESS_DIR"

    ffmpeg="${pkgs.ffmpeg}/bin/ffmpeg"
    ffprobe="${pkgs.ffmpeg}/bin/ffprobe"
    notify_send="${pkgs.libnotify}/bin/notify-send"

    # Clean up progress file on exit
    cleanup() {
      rm -f "$PROGRESS_FILE" "$PROGRESS_FILE.tmp"
    }
    trap cleanup EXIT

    notify_success () { "$notify_send" -i video-x-generic "$1" "$2"; }
    notify_error   () { "$notify_send" -u critical -i dialog-error "$1" "$2"; }

    # Video codecs DaVinci Resolve Studio decodes natively on Linux.
    # Anything else (AV1, VP8/VP9, ...) gets transcoded to DNxHR.
    supported_video="h264 hevc prores dnxhd mjpeg mpeg4 cfhd"
    # Containers Resolve will open. Matroska/WebM/AVI always need a remux.
    supported_container="mov mp4"
    # Audio: Resolve on Linux only reads uncompressed PCM, so every
    # compressed audio codec is re-encoded.

    in_list () {
      local needle="$1" item
      for item in $2; do
        [ "$item" = "$needle" ] && return 0
      done
      return 1
    }

    probe () {
      local file="$1"
      shift
      "$ffprobe" -v error "$@" -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null
    }

    # Escape a string for embedding in the progress JSON
    json_escape () {
      printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
    }

    # Progress writer — parses ffmpeg -progress output into a JSON state file.
    # Depends on outer scope: $current_file, $file_index, $total, $codec_name
    write_progress() {
      local total_duration_us percent=0 speed="N/A" json_name
      json_name="$(json_escape "$current_file_name")"
      total_duration_us=$(probe "$current_file" -show_entries format=duration | \
        awk '{printf "%.0f", $1 * 1000000}')

      while IFS='=' read -r key value; do
        case "$key" in
          out_time_us)
            if [ "$total_duration_us" -gt 0 ] 2>/dev/null; then
              percent=$(( value * 100 / total_duration_us ))
              # Clamp to 0-100
              [ "$percent" -lt 0 ] 2>/dev/null && percent=0
              [ "$percent" -gt 100 ] 2>/dev/null && percent=100
            fi
            ;;
          speed)
            speed="$value"
            ;;
          progress)
            if [ "$value" = "end" ]; then
              percent=100
            fi
            printf '{"file":"%s","percent":%d,"speed":"%s","index":%d,"total":%d,"codec":"%s","gpu":false}\n' \
              "$json_name" "$percent" "$speed" "$file_index" "$total" "$codec_name" \
              > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
            ;;
        esac
      done
    }

    # ---------------------------------------------------------------
    # Build the work list
    # ---------------------------------------------------------------

    queue=()
    if [ "$#" -gt 0 ]; then
      queue=("$@")
    else
      shopt -s nullglob
      queue=("$media_in"/*)
      shopt -u nullglob
    fi

    if [ "''${#queue[@]}" -eq 0 ]; then
      notify_error "The queue is empty" "Drop files into $media_in first."
      echo "Nothing to do — $media_in is empty."
      exit 3
    fi

    todo_files=()
    todo_vmode=()
    todo_amode=()
    todo_label=()

    echo "-----------------------------"
    echo "Inspecting ''${#queue[@]} file(s)"
    echo "-----------------------------"

    for file in "''${queue[@]}"; do
      [ -f "$file" ] || continue
      name="$(basename "$file")"

      container="$(probe "$file" -show_entries format=format_name | head -1)"
      if [ -z "$container" ]; then
        echo "  skip     $name (not a media file)"
        continue
      fi

      vcodec="$(probe "$file" -select_streams v:0 -show_entries stream=codec_name | head -1)"
      acodec="$(probe "$file" -select_streams a:0 -show_entries stream=codec_name | head -1)"

      # ffprobe reports comma-separated container lists, e.g. "mov,mp4,m4a,..."
      container_ok=false
      for c in ''${container//,/ }; do
        if in_list "$c" "$supported_container"; then
          container_ok=true
          break
        fi
      done

      vmode="copy"
      if [ -n "$vcodec" ] && ! in_list "$vcodec" "$supported_video"; then
        vmode="dnxhr"
      fi

      amode="copy"
      case "$acodec" in
        "" ) ;;                  # no audio track
        pcm_* ) ;;               # already uncompressed
        * ) amode="pcm" ;;
      esac

      if [ "$vmode" = "copy" ] && [ "$amode" = "copy" ] && [ "$container_ok" = true ]; then
        echo "  ok       $name ($vcodec / ''${acodec:-no audio}) — already Resolve-ready"
        continue
      fi

      if [ "$vmode" = "dnxhr" ]; then
        label="DNxHR"
        [ "$amode" = "pcm" ] && label="DNxHR+PCM"
      elif [ "$amode" = "pcm" ]; then
        label="PCM"
      else
        label="Remux"
      fi

      echo "  convert  $name ($vcodec / ''${acodec:-no audio}) → $label"
      todo_files+=("$file")
      todo_vmode+=("$vmode")
      todo_amode+=("$amode")
      todo_label+=("$label")
    done

    total="''${#todo_files[@]}"

    if [ "$total" -eq 0 ]; then
      notify_success "Nothing to convert" "Every file is already compatible with Resolve."
      echo ""
      echo "Everything is already compatible — nothing to do."
      exit 0
    fi

    # ---------------------------------------------------------------
    # Convert
    # ---------------------------------------------------------------

    echo ""
    failures=0
    file_index=0

    for i in "''${!todo_files[@]}"; do
      current_file="''${todo_files[$i]}"
      current_file_name="$(basename "$current_file")"
      vmode="''${todo_vmode[$i]}"
      amode="''${todo_amode[$i]}"
      codec_name="''${todo_label[$i]}"
      file_index=$(( i + 1 ))

      # Always land in a .mov container — it is the only one that carries
      # PCM audio alongside H.264/H.265 or DNxHR without complaints.
      output_file="$media_out/''${current_file_name%.*}.mov"

      vargs=()
      if [ "$vmode" = "copy" ]; then
        vargs=( -c:v copy )
      else
        vargs=( -vf format=yuv422p -c:v dnxhd -profile:v dnxhr_hq )
      fi

      aargs=()
      if [ "$amode" = "copy" ]; then
        aargs=( -c:a copy )
      else
        aargs=( -c:a pcm_s16le )
      fi

      notify_success "Converting $file_index/$total" "$current_file_name → $codec_name"
      echo "[$file_index/$total] $current_file_name → $(basename "$output_file") ($codec_name)"

      err_log="$(mktemp)"
      "$ffmpeg" -hide_banner -nostdin -y -i "$current_file" \
        -map 0:V? -map 0:a? -map_metadata 0 \
        "''${vargs[@]}" "''${aargs[@]}" \
        -progress pipe:1 \
        "$output_file" 2>"$err_log" | write_progress

      status="''${PIPESTATUS[0]}"
      if [ "$status" -ne 0 ]; then
        failures=$(( failures + 1 ))
        echo "  failed:"
        tail -n 10 "$err_log" | sed 's/^/    /'
        notify_error "Encode failed" "$current_file_name ($codec_name)"
        rm -f "$output_file"
      fi
      rm -f "$err_log"
    done

    echo ""
    if [ "$failures" -gt 0 ]; then
      notify_error "Finished with errors" "$failures of $total file(s) failed."
      echo "Finished with $failures failure(s) out of $total."
    else
      notify_success "Converting finished" "$total file(s) are ready for Resolve."
      echo "Done — $total file(s) written to $media_out."
    fi

    # Keep the floating terminal around long enough to read the summary
    if [ -t 0 ]; then
      read -r -p "Press Enter to close..." _
    fi

    [ "$failures" -eq 0 ]
  '';

  # Status check script for the bar widget
  davinciConvertStatus = pkgs.writeShellScriptBin "davinci-convert-status" ''
    #!/bin/bash
    CONVERT_DIR="${convertDir}"
    CONVERTED_DIR="${convertedDir}"
    PROGRESS_FILE="${progressDir}/progress.json"

    queue_count=0
    converted_count=0

    if [ -d "$CONVERT_DIR" ] && [ "$(ls -A "$CONVERT_DIR" 2>/dev/null)" ]; then
      queue_count=$(ls -A "$CONVERT_DIR" | wc -l)
    fi

    if [ -d "$CONVERTED_DIR" ] && [ "$(ls -A "$CONVERTED_DIR" 2>/dev/null)" ]; then
      converted_count=$(ls -A "$CONVERTED_DIR" | wc -l)
    fi

    # Include encoding progress if active
    if [ -f "$PROGRESS_FILE" ]; then
      progress=$(cat "$PROGRESS_FILE" 2>/dev/null)
      echo "{\"queue\": $queue_count, \"converted\": $converted_count, \"encoding\": $progress}"
    else
      echo "{\"queue\": $queue_count, \"converted\": $converted_count, \"encoding\": null}"
    fi
  '';

  # === Noctalia 5 plugin (Luau, plugin_api 3) ================================
  # Noctalia 5 dropped the old QML/manifest.json plugin format in favour of
  # plugin.toml + Luau entry points, so the bar widget is a Luau script that
  # polls davinci-convert-status and renders its JSON.

  pluginId = "serenityos/davinci-convert";
  pluginWidgetType = "${pluginId}:davinci-convert";

  # Absolute store paths: noctalia's Luau host runs commands through
  # `/bin/sh -c`, so nothing here should depend on the session PATH.
  statusCmd = "${davinciConvertStatus}/bin/davinci-convert-status";
  convertCmd = "${davinciConvertScript}/bin/davinci-convert";
  # The --app-id is what the mango/niri float rules match on, so the terminal
  # is launched directly instead of via noctalia.runInTerminal().
  terminalCmd = "${pkgs.foot}/bin/foot --app-id=davinci-convert --title='DaVinci Convert' -e ${convertCmd}";
  openQueueCmd = "${pkgs.xdg-utils}/bin/xdg-open '${convertDir}'";

  pluginToml = pkgs.writeText "plugin.toml" ''
    id           = "${pluginId}"
    name         = "DaVinci Convert"
    version      = "3.0.0"
    plugin_api   = 3
    icon         = "movie"
    author       = "serenityOs"
    license      = "MIT"
    description  = "Conversion queue status for DaVinci Resolve Studio"
    tags         = [ "video", "utility" ]

    [[widget]]
    id    = "davinci-convert"
    entry = "davinci_convert.luau"
  '';

  pluginWidget = pkgs.writeText "davinci_convert.luau" ''
    -- DaVinci Convert — conversion queue status for the noctalia bar.
    --
    -- Polls davinci-convert-status and mirrors whatever the queue is doing:
    -- live encode progress while ffmpeg runs, otherwise the queue/output
    -- counts. Hidden entirely when both folders are empty.
    --
    -- Left click  → run the converter in a floating terminal
    -- Right click → open the queue folder

    local IDLE_MS = 5000
    local BUSY_MS = 1000

    local interval = IDLE_MS
    local polling = false

    -- The host's default tick is not ours to assume, so state it up front.
    noctalia.setUpdateInterval(IDLE_MS)

    local function setInterval(ms: number)
      if interval ~= ms then
        interval = ms
        noctalia.setUpdateInterval(ms)
      end
    end

    local function show(glyph: string, text: string, color: string, tooltip: string)
      barWidget.setVisible(true)
      barWidget.setGlyph(glyph)
      barWidget.setText(text)
      barWidget.setColor(color)
      barWidget.setGlyphColor(color)
      barWidget.setTooltip(tooltip)
    end

    local function render(status)
      local encoding = status.encoding
      if encoding ~= nil then
        setInterval(BUSY_MS)
        local percent = math.floor(tonumber(encoding.percent) or 0)
        show(
          "transform",
          `{encoding.codec} {percent}%`,
          "primary",
          `{encoding.file} — {percent}% at {encoding.speed} (file {encoding.index}/{encoding.total})`
        )
        return
      end

      setInterval(IDLE_MS)
      local queue = tonumber(status.queue) or 0
      local converted = tonumber(status.converted) or 0

      if queue > 0 then
        show("video-plus", tostring(queue), "primary", `{queue} file(s) queued — click to convert for Resolve`)
      elseif converted > 0 then
        show("video", "", "on_surface", `{converted} converted file(s) ready in the output folder`)
      else
        barWidget.setVisible(false)
      end
    end

    -- Hooks
    function update()
      if polling then
        return
      end
      polling = true
      noctalia.runAsync("${statusCmd}", function(res)
        polling = false
        -- Anything unreadable drops the widget and falls back to the slow
        -- tick; a broken status command must not poll once a second forever.
        if res.exitCode ~= 0 then
          setInterval(IDLE_MS)
          barWidget.setVisible(false)
          return
        end
        local ok, status = pcall(noctalia.json.decode, res.stdout)
        if ok and type(status) == "table" then
          render(status)
        else
          setInterval(IDLE_MS)
          barWidget.setVisible(false)
        end
      end)
    end

    function onClick()
      noctalia.runAsync("${terminalCmd}")
    end

    function onRightClick()
      noctalia.runAsync("${openQueueCmd}")
    end
  '';

  # Path plugin sources are scanned as <root>/<plugin>/plugin.toml, so the
  # package is a directory of plugins rather than the plugin itself.
  noctaliaPlugin = pkgs.runCommand "noctalia-plugin-davinci-convert" { } ''
    install -Dm444 ${pluginToml} "$out/davinci-convert/plugin.toml"
    install -Dm444 ${pluginWidget} "$out/davinci-convert/davinci_convert.luau"
  '';
in
{
  options = lib.setAttrByPath optPath {
    enable = lib.mkEnableOption "DaVinci Resolve conversion script and Noctalia bar widget";

    pluginPackage = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      default = noctaliaPlugin;
      description = ''
        Root directory of a noctalia "path" plugin source containing the
        DaVinci Convert bar widget. Consumed by the noctalia module.
      '';
    };

    pluginId = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = pluginId;
      description = "Noctalia plugin id to list in plugins.enabled.";
    };

    widgetType = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = pluginWidgetType;
      description = "Noctalia bar widget type string for the plugin widget.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the scripts to PATH
    home.packages = [
      davinciConvertScript
      davinciConvertStatus
      pkgs.ffmpeg
      pkgs.foot
      pkgs.libnotify
    ];

    # Create the required video directories
    home.activation.createVideoConvertDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${convertDir}"
      mkdir -p "${convertedDir}"
      mkdir -p "${progressDir}"
    '';
  };
}

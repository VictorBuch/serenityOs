{
  config,
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
let
  optPath = [ "home" "desktop-environments" "niri" "davinci-convert" ];
  cfg = lib.attrByPath optPath { enable = false; } config;
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (
    lib.mkEnableOption "DaVinci Resolve video conversion script and Noctalia bar widget"
  );

  config = lib.mkIf cfg.enable (
    let
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

      # Noctalia plugin manifest
      pluginManifest = builtins.toJSON {
        id = "davinci-convert";
        name = "DaVinci Convert";
        version = "3.0.0";
        author = "serenityOs";
        license = "MIT";
        description = "Conditions media for DaVinci Resolve Studio — PCM audio conversion with queue status";
        entryPoints = {
          barWidget = "BarWidget.qml";
        };
        dependencies = {
          plugins = [ ];
        };
        metadata = {
          defaultSettings = { };
        };
      };

      # Noctalia bar widget QML
      barWidgetQml = ''
        import QtQuick
        import QtQuick.Layouts
        import Quickshell
        import Quickshell.Io
        import qs.Commons
        import qs.Widgets
        import qs.Services.UI

        Item {
          id: root

          // Plugin API (injected by PluginService)
          property var pluginApi: null

          // Required properties for bar widgets
          property ShellScreen screen
          property string widgetId: ""
          property string section: ""

          // Per-screen bar properties
          readonly property string screenName: screen?.name ?? ""
          readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
          readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
          readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
          readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

          // Status tracking
          property int queueCount: 0
          property int convertedCount: 0
          property string statusText: ""
          property string statusIcon: "video"

          // Encoding progress tracking
          property var encodingData: null
          property bool isEncoding: encodingData !== null && encodingData !== undefined
          property real encodePercent: isEncoding ? encodingData.percent : 0
          property int nullPollCount: 0

          // Content dimensions
          readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
          readonly property real contentHeight: capsuleHeight

          implicitWidth: contentWidth
          implicitHeight: contentHeight

          // Poll status: 1s during encode, 5s when idle (after 3 consecutive null polls)
          Timer {
            id: pollTimer
            interval: root.isEncoding ? 1000 : 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: statusProcess.running = true
          }

          Process {
            id: statusProcess
            command: ["davinci-convert-status"]
            stdout: SplitParser {
              onRead: data => {
                try {
                  let result = JSON.parse(data);
                  root.queueCount = result.queue;
                  root.convertedCount = result.converted;
                  root.encodingData = result.encoding;

                  if (root.isEncoding) {
                    root.nullPollCount = 0;
                    root.statusText = root.encodingData.codec + " " + root.encodePercent + "%";
                    root.statusIcon = "video-plus";
                  } else {
                    root.nullPollCount++;
                    if (result.queue > 0) {
                      root.statusText = "New";
                      root.statusIcon = "video-plus";
                    } else if (result.converted > 0) {
                      root.statusText = "Done";
                      root.statusIcon = "video";
                    } else {
                      root.statusText = "";
                      root.statusIcon = "video";
                    }
                  }
                } catch (e) {
                  Logger.e("DaVinciConvert", "Failed to parse status:", e);
                }
              }
            }
          }

          // Visual capsule
          Rectangle {
            id: visualCapsule
            x: Style.pixelAlignCenter(parent.width, width)
            y: Style.pixelAlignCenter(parent.height, height)
            width: root.contentWidth
            height: root.contentHeight
            color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
            radius: Style.radiusL
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth

            // Encode progress bar (fills behind content)
            Rectangle {
              visible: root.isEncoding
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * (root.encodePercent / 100)
              color: Color.mPrimary
              opacity: 0.3
              radius: Style.radiusL

              Behavior on width {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
              }
            }

            RowLayout {
              id: row
              anchors.centerIn: parent
              spacing: Style.marginS

              NIcon {
                icon: root.statusIcon
                color: root.isEncoding || root.queueCount > 0 ? Color.mPrimary : Color.mOnSurface
              }

              NText {
                visible: root.statusText !== ""
                text: root.statusText
                color: root.isEncoding || root.queueCount > 0 ? Color.mPrimary : Color.mOnSurface
                pointSize: barFontSize
                font.weight: Font.Medium
              }
            }
          }

          // Launch script in a floating terminal
          Process {
            id: launchProcess
            command: ["foot", "--app-id=davinci-convert", "--title=DaVinci Convert", "-e", "davinci-convert"]
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              launchProcess.running = true;
            }

            onEntered: {
              let tip;
              if (root.isEncoding) {
                tip = root.encodingData.codec + " " + root.encodePercent + "% (" + root.encodingData.speed + ") | " + root.encodingData.index + "/" + root.encodingData.total;
              } else {
                tip = "Queue: " + root.queueCount + " | Converted: " + root.convertedCount;
              }
              TooltipService.show(root, tip, BarService.getTooltipDirection());
            }
            onExited: {
              TooltipService.hide();
            }
          }

          Component.onCompleted: {
            Logger.i("DaVinciConvert", "Bar widget loaded (v3.0 — Resolve Studio audio conditioning)");
          }
        }
      '';
    in
    {
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

      # Install the Noctalia plugin
      xdg.configFile."noctalia/plugins/davinci-convert/manifest.json".text = pluginManifest;
      xdg.configFile."noctalia/plugins/davinci-convert/BarWidget.qml".text = barWidgetQml;
    }
  );
}

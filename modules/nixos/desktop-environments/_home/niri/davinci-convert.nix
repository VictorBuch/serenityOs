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
        #!/bin/bash

        # DaVinci Resolve video conversion script
        # Re-encodes videos to/from codecs compatible with DaVinci Resolve
        # Supports VAAPI GPU acceleration on AMD GPUs

        # Media folders
        media_in="${convertDir}"
        media_out="${convertedDir}"

        # Progress state
        PROGRESS_DIR="${progressDir}"
        PROGRESS_FILE="$PROGRESS_DIR/progress.json"
        mkdir -p "$media_in" "$media_out" "$PROGRESS_DIR"

        # Clean up progress file on exit
        cleanup() {
          rm -f "$PROGRESS_FILE" "$PROGRESS_FILE.tmp"
        }
        trap cleanup EXIT

        # Desktop notifications
        icons_dir="/usr/share/icons/Papirus/64x64/places"
        icon_success="folder-cat-mocha-blue-video.svg"
        icon_error="folder-cat-mocha-peach-video.svg"

        notify_success () {
          notify-send -i "$icons_dir/$icon_success" "$1" "$2"
        }

        notify_error () {
          notify-send -u critical -i "$icons_dir/$icon_error" "$1" "$2"
        }

        # Detect VAAPI encode support per codec
        VAAPI_INFO="$(${pkgs.libva-utils}/bin/vainfo 2>/dev/null || echo "")"
        HAS_H264_VAAPI=false
        HAS_HEVC_VAAPI=false
        HAS_AV1_VAAPI=false

        if echo "$VAAPI_INFO" | grep -q "VAProfileH264.*VAEntrypointEncSlice"; then
          HAS_H264_VAAPI=true
        fi
        if echo "$VAAPI_INFO" | grep -q "VAProfileHEVC.*VAEntrypointEncSlice"; then
          HAS_HEVC_VAAPI=true
        fi
        if echo "$VAAPI_INFO" | grep -q "VAProfileAV1.*VAEntrypointEncSlice"; then
          HAS_AV1_VAAPI=true
        fi

        # Progress writer — parses ffmpeg -progress output into JSON state file
        # Depends on outer scope: $current_file, $file_index, $total, $codec_name, $using_gpu
        write_progress() {
          local total_duration_us percent=0 speed="N/A"
          total_duration_us=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$current_file" | \
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
                printf '{"file":"%s","percent":%d,"speed":"%s","index":%d,"total":%d,"codec":"%s","gpu":%s}\n' \
                  "$current_file_name" "$percent" "$speed" "$file_index" "$total" "$codec_name" "$using_gpu" \
                  > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
                ;;
            esac
          done
        }

        # The number of videos in the input folder
        total="$( ls -A "$media_in" | wc -l )"

        # Display the main menu
        echo "--------------------------"
        echo "What would you like to do?"
        echo "--------------------------"
        echo "1) Import an incompatible video"
        echo "2) Render the final video"
        echo "3) Exit the script"

        read main_choice

        case $main_choice in
          1)  # Set input codecs that will be converted
              input_codecs=("h264" "hevc")
              using_gpu=false

              echo "-----------------------------------------"
              echo "Select the output codec for queued videos"
              echo "-----------------------------------------"
              echo "1) DNxHR HQX (CPU encode, GPU decode)"
              if [ "$HAS_AV1_VAAPI" = true ]; then
                echo "2) AV1 (GPU accelerated - VAAPI)"
                echo "3) AV1 (CPU - libsvtav1)"
              else
                echo "2) AV1 (CPU - libsvtav1)"
              fi
              echo "4) MPEG-4 part 2 (CPU)"
              echo "5) Exit"

              read encoder_choice

              if [ "$HAS_AV1_VAAPI" = true ]; then
                case $encoder_choice in
                  1)  video_enc="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128"
                      video_enc_out="-c:v dnxhd -profile:v 4 -pix_fmt yuv422p10le"
                      out_format="mov"
                      codec_name="DNxHR"
                      ;;
                  2)  video_enc="-vaapi_device /dev/dri/renderD128"
                      video_enc_out="-vf format=nv12,hwupload -c:v av1_vaapi -qp 23"
                      out_format="mp4"
                      codec_name="AV1"
                      using_gpu=true
                      ;;
                  3)  video_enc=""
                      video_enc_out="-c:v libsvtav1 -preset 6 -crf 23 -pix_fmt yuv420p10le"
                      out_format="mp4"
                      codec_name="AV1"
                      ;;
                  4)  video_enc=""
                      video_enc_out="-c:v mpeg4 -q:v 2"
                      out_format="mov"
                      codec_name="MPEG4"
                      ;;
                  5) echo "Exiting..." ; exit 0;;
                  *) notify_error "You entered an invalid value" "Try running the script again." ; exit 1;;
                esac
              else
                case $encoder_choice in
                  1)  video_enc="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128"
                      video_enc_out="-c:v dnxhd -profile:v 4 -pix_fmt yuv422p10le"
                      out_format="mov"
                      codec_name="DNxHR"
                      ;;
                  2)  video_enc=""
                      video_enc_out="-c:v libsvtav1 -preset 6 -crf 23 -pix_fmt yuv420p10le"
                      out_format="mp4"
                      codec_name="AV1"
                      ;;
                  4)  video_enc=""
                      video_enc_out="-c:v mpeg4 -q:v 2"
                      out_format="mov"
                      codec_name="MPEG4"
                      ;;
                  5) echo "Exiting..." ; exit 0;;
                  *) notify_error "You entered an invalid value" "Try running the script again." ; exit 1;;
                esac
              fi
              ;;
          2)  input_codecs=("dnxhd" "prores")
              using_gpu=false

              echo "-----------------------------------------"
              echo "Select the output codec for queued videos"
              echo "-----------------------------------------"

              opt=1
              declare -A menu_map

              if [ "$HAS_H264_VAAPI" = true ]; then
                echo "$opt) H.264 (GPU - VAAPI)"
                menu_map[$opt]="h264_gpu"
                opt=$((opt + 1))
              fi
              echo "$opt) H.264 (CPU - libx264)"
              menu_map[$opt]="h264_cpu"
              opt=$((opt + 1))

              if [ "$HAS_HEVC_VAAPI" = true ]; then
                echo "$opt) H.265 (GPU - VAAPI)"
                menu_map[$opt]="hevc_gpu"
                opt=$((opt + 1))
              fi
              echo "$opt) H.265 (CPU - libx265)"
              menu_map[$opt]="hevc_cpu"
              opt=$((opt + 1))

              if [ "$HAS_AV1_VAAPI" = true ]; then
                echo "$opt) AV1 (GPU - VAAPI)"
                menu_map[$opt]="av1_gpu"
                opt=$((opt + 1))
              fi
              echo "$opt) AV1 (CPU - libsvtav1)"
              menu_map[$opt]="av1_cpu"
              opt=$((opt + 1))

              echo "$opt) Exit"
              menu_map[$opt]="exit"

              read encoder_choice

              selected="''${menu_map[$encoder_choice]:-invalid}"

              case "$selected" in
                h264_gpu)
                  video_enc="-vaapi_device /dev/dri/renderD128"
                  video_enc_out="-vf format=nv12,hwupload -c:v h264_vaapi -qp 20 -movflags +faststart"
                  out_format="mp4"
                  codec_name="H264"
                  using_gpu=true
                  ;;
                h264_cpu)
                  video_enc=""
                  video_enc_out="-c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -movflags +faststart"
                  out_format="mp4"
                  codec_name="H264"
                  ;;
                hevc_gpu)
                  video_enc="-vaapi_device /dev/dri/renderD128"
                  video_enc_out="-vf format=nv12,hwupload -c:v hevc_vaapi -qp 22 -movflags +faststart"
                  out_format="mp4"
                  codec_name="H265"
                  using_gpu=true
                  ;;
                hevc_cpu)
                  video_enc=""
                  video_enc_out="-c:v libx265 -preset slow -crf 20 -movflags +faststart"
                  out_format="mov"
                  codec_name="H265"
                  ;;
                av1_gpu)
                  video_enc="-vaapi_device /dev/dri/renderD128"
                  video_enc_out="-vf format=nv12,hwupload -c:v av1_vaapi -qp 23 -movflags +faststart"
                  out_format="mp4"
                  codec_name="AV1"
                  using_gpu=true
                  ;;
                av1_cpu)
                  video_enc=""
                  video_enc_out="-c:v libsvtav1 -preset 3 -crf 25 -pix_fmt yuv420p10le -svtav1-params tune=0:fast-decode=1 -movflags +faststart"
                  out_format="mp4"
                  codec_name="AV1"
                  ;;
                exit)
                  echo "Exiting..." ; exit 0
                  ;;
                *)
                  notify_error "You entered an invalid value" "Try running the script again." ; exit 1
                  ;;
              esac
              ;;
          3) echo "Exiting..." ; exit 0;;
          *) notify_error "You entered an invalid value" "Try running the script again." ; exit 1;;
        esac

        # Check if ffmpeg is installed
        if ! command -v ffmpeg &> /dev/null; then
          notify_error "FFmpeg not found" "You need to install ffmpeg to use this script."
          exit 2
        fi

        # Check if input directory is empty
        if [[ -z $(ls -A "$media_in") ]]; then
          notify_error "The queue is empty" "There are currently no videos in the queue."
          exit 3
        fi

        # Encoding
        file_index=0

        for file in "$media_in"/*; do
          current_file="$file"
          current_file_name="$(basename "$file")"
          # Use ffprobe to detect container format
          container_format="$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$file" | head -1)"
          video_codec="$(ffprobe -v error -show_entries stream=codec_name -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 "$file")"
          audio_codec="$(ffprobe -v error -show_entries stream=codec_name -select_streams a:0 -of default=noprint_wrappers=1:nokey=1 "$file")"

          # Detect file extension from ffprobe format name
          case "$container_format" in
            *mp4*|*m4a*) file_ext=".mp4";;
            *mov*|*quicktime*) file_ext=".mov";;
            *matroska*) file_ext=".mkv";;
            *webm*) file_ext=".webm";;
            *) file_ext=".''${current_file_name##*.}"
               file_ext="$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')"
               ;;
          esac

          if [[ $audio_codec == "aac" ]]; then
            audio_enc="-c:a pcm_s16le"
          else
            audio_enc="-c:a copy"
          fi

          if [[ "''${input_codecs[*]}" =~ "$video_codec" ]]; then
            file_index=$(( file_index + 1 ))
            output_file="$media_out/$(basename "$current_file_name" "$file_ext").$out_format"

            notify_success "Converting $file_index/$total" "$current_file_name → $codec_name"

            # Run ffmpeg with progress output (no inner terminal wrapper)
            ffmpeg $video_enc -i "$file" $video_enc_out $audio_enc \
              -progress pipe:1 \
              "$output_file" 2>/dev/null | write_progress

            if [ $? -ne 0 ]; then
              notify_error "Encode failed" "$current_file_name failed with $codec_name. Try CPU fallback."
            fi
          fi
        done

        notify_success "Converting finished" "The videos have been successfully converted."
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
        version = "2.0.0";
        author = "serenityOs";
        license = "MIT";
        description = "Video conversion queue status with GPU acceleration for DaVinci Resolve";
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
                    root.statusIcon = root.encodingData.gpu ? "gpu" : "cpu";
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
            Logger.i("DaVinciConvert", "Bar widget loaded (v2.0 with GPU acceleration)");
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
        pkgs.libva-utils
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

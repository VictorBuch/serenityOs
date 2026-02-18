args@{
  config,
  pkgs,
  lib,
  osConfig ? { },
  mkHomeModule,
  ...
}:

mkHomeModule {
  name = "davinci-convert";
  optionPath = "home.desktop-environments.niri.davinci-convert";
  description = "DaVinci Resolve video conversion script and Noctalia bar widget";

  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      convertDir = "${config.home.homeDirectory}/Videos/convert_queue";
      convertedDir = "${config.home.homeDirectory}/Videos/converted";

      # The main conversion script
      davinciConvertScript = pkgs.writeShellScriptBin "davinci-convert" ''
        #!/bin/bash

        # DaVinci Resolve video conversion script
        # Re-encodes videos to/from codecs compatible with DaVinci Resolve

        # Media folders
        media_in="${convertDir}"
        media_out="${convertedDir}"

        # Create directories if they don't exist
        mkdir -p "$media_in" "$media_out"

        # The number of videos in the input folder
        total="$( ls -A "$media_in" | wc -l )"

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

              echo "-----------------------------------------"
              echo "Select the output codec for queued videos"
              echo "-----------------------------------------"
              echo "1) DNHXR HQX"
              echo "2) AV1"
              echo "3) MPEG-4 part 2"

              read encoder_choice

              case $encoder_choice in
                1)  video_enc="-c:v dnxhd -profile:v 4 -pix_fmt yuv422p10le"
                    out_format="mov"
                    ;;
                2)  video_enc="-c:v libsvtav1 -preset 6 -crf 23 -pix_fmt yuv420p10le"
                    out_format="mp4"
                    ;;
                3)  video_enc="-c:v mpeg4 -q:v 2"
                    out_format="mov"
                    ;;
                4) echo "Exiting..." ; exit 0;;
                *) notify_error "You entered an invalid value" "Try running the script again." ; exit 1;;
              esac
              ;;
          2)  input_codecs=("dnxhd" "prores")

              echo "-----------------------------------------"
              echo "Select the output codec for queued videos"
              echo "-----------------------------------------"
              echo "1) H.264"
              echo "2) H.265"
              echo "3) AV1"

              read encoder_choice

              case $encoder_choice in
                1)  video_enc="-c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -x264-params opencl=true -movflags +faststart"
                    out_format="mp4"
                    ;;
                2)  video_enc="-c:v libx265 -preset slow -crf 20 -movflags +faststart"
                    out_format="mov"
                    ;;
                3)  video_enc="-c:v libsvtav1 -preset 3 -crf 25 -pix_fmt yuv420p10le -svtav1-params tune=0:fast-decode=1 -movflags +faststart"
                    out_format="mp4"
                    ;;
                4) echo "Exiting..." ; exit 0;;
                *) notify_error "You entered an invalid value" "Try running the script again." ; exit 1;;
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
          file_name="$(basename "$file")"
          # Use ffprobe to detect container format (more reliable than the `file` command)
          container_format="$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$file" | head -1)"
          video_codec="$(ffprobe -v error -show_entries stream=codec_name -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 "$file")"
          audio_codec="$(ffprobe -v error -show_entries stream=codec_name -select_streams a:0 -of default=noprint_wrappers=1:nokey=1 "$file")"
          frame_rate="$(ffprobe -v error -show_entries stream=r_frame_rate -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 "$file" | head -1)"
          # Convert fractional frame rate (e.g. 30000/1001) to integer
          frame_rate="$(echo "$frame_rate" | ${pkgs.bc}/bin/bc -l | cut -d. -f1)"
          keyframe_interval="$(($frame_rate * 10))"

          if [[ $enc_sel -eq 2 ]]; then
            video_enc="$video_enc -g $keyframe_interval"
          fi

          # Detect file extension from ffprobe format name
          case "$container_format" in
            *mp4*|*m4a*) file_ext=".mp4";;
            *mov*|*quicktime*) file_ext=".mov";;
            *matroska*) file_ext=".mkv";;
            *webm*) file_ext=".webm";;
            *) # Fallback: use the actual file extension
               file_ext=".''${file_name##*.}"
               file_ext="$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')"
               ;;
          esac

          if [[ $audio_codec == "aac" ]]; then
            audio_enc="-c:a pcm_s16le"
          else
            audio_enc="-c:a copy"
          fi

          if [[ "''${input_codecs[*]}" =~ "$video_codec" ]]; then
            file_index=$(( $file_index + 1 ))
            notify_success "Converting... $file_index/$total"
            ${lib.getExe pkgs.foot} ffmpeg -i "$file" $video_enc $audio_enc "$media_out/$(basename "$file_name" "$file_ext").$out_format"
          fi
        done

        notify_success "Converting finished" "The videos have been successfully converted."
      '';

      # Status check script for the bar widget
      davinciConvertStatus = pkgs.writeShellScriptBin "davinci-convert-status" ''
        #!/bin/bash
        CONVERT_DIR="${convertDir}"
        CONVERTED_DIR="${convertedDir}"

        queue_count=0
        converted_count=0

        if [ -d "$CONVERT_DIR" ] && [ "$(ls -A "$CONVERT_DIR" 2>/dev/null)" ]; then
          queue_count=$(ls -A "$CONVERT_DIR" | wc -l)
        fi

        if [ -d "$CONVERTED_DIR" ] && [ "$(ls -A "$CONVERTED_DIR" 2>/dev/null)" ]; then
          converted_count=$(ls -A "$CONVERTED_DIR" | wc -l)
        fi

        # Output JSON for the widget to parse
        echo "{\"queue\": $queue_count, \"converted\": $converted_count}"
      '';

      # Noctalia plugin manifest
      pluginManifest = builtins.toJSON {
        id = "davinci-convert";
        name = "DaVinci Convert";
        version = "1.0.0";
        author = "serenityOs";
        license = "MIT";
        description = "Video conversion queue status for DaVinci Resolve";
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

          // Content dimensions
          readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
          readonly property real contentHeight: capsuleHeight

          implicitWidth: contentWidth
          implicitHeight: contentHeight

          // Poll status every 5 seconds
          Timer {
            id: pollTimer
            interval: 5000
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

            RowLayout {
              id: row
              anchors.centerIn: parent
              spacing: Style.marginS

              NIcon {
                icon: root.statusIcon
                color: root.queueCount > 0 ? Color.mPrimary : Color.mOnSurface
              }

              NText {
                visible: root.statusText !== ""
                text: root.statusText
                color: root.queueCount > 0 ? Color.mPrimary : Color.mOnSurface
                pointSize: barFontSize
                font.weight: Font.Medium
              }
            }
          }

          // Launch script in a floating terminal
          Process {
            id: launchProcess
            command: ["ghostty", "--title=DaVinci Convert", "--class=davinci-convert", "-e", "davinci-convert"]
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
              let tip = "Queue: " + root.queueCount + " | Converted: " + root.convertedCount;
              TooltipService.show(root, tip, BarService.getTooltipDirection());
            }
            onExited: {
              TooltipService.hide();
            }
          }

          Component.onCompleted: {
            Logger.i("DaVinciConvert", "Bar widget loaded");
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
        pkgs.libnotify
      ];

      # Create the required video directories
      home.activation.createVideoConvertDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${convertDir}"
        mkdir -p "${convertedDir}"
      '';

      # Install the Noctalia plugin
      xdg.configFile."noctalia/plugins/davinci-convert/manifest.json".text = pluginManifest;
      xdg.configFile."noctalia/plugins/davinci-convert/BarWidget.qml".text = barWidgetQml;
    };
} args

{ pkgs, ... }:

{
  # This automatically provides all the tools your script needs!
  environment.systemPackages = with pkgs; [
    ffmpeg
    bc
    imagemagick
    chafa
    trash-cli

    # This creates your global 'compressall' command
    (pkgs.writeShellScriptBin "compressall" ''


  # ==========================================
  # SCRIPT START
  # ==========================================
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg
    bc
    imagemagick
    chafa
    trash-cli  # Required for the trash command

    (pkgs.writeShellScriptBin "compressall" ''
      #!/bin/bash
      echo "Compress all script (Trash Edition) 08/01-26"

      # Get the name of the current directory for the final rename
      current_folder_name=$(basename "$PWD")

      # Find video files - Changed '' to "" to fix the Nix error
      mapfile -d "" video_files < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.3gp" -o -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" -o -iname "*.mpeg" -o -iname "*.mpg" -o -iname "*.divx" \) ! -iname "*compressed*" ! -iname "*smaller*" ! -iname "*cannotcompress*" -print0)

      # Find image files
      mapfile -d "" image_files < <(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -iname "*compressed*" ! -iname "*smaller*" ! -iname "*cannotcompress*" -print0)

      # Escaped the ${} with ''${} so Nix ignores them
      files=("''${video_files[@]}" "''${image_files[@]}")
      total_files=''${#files[@]}
      current_file=0
      original_size=0
      compressed_size=0
      skipped_files=0

      if [ ''$total_files -eq 0 ]; then
        echo "No video or image files found."
        exit 1
      fi

      echo "Found ''${#video_files[@]} video(s) and ''${#image_files[@]} image(s)."

      show_progress_bar() {
        local duration=''$1
        local elapsed=''$2
        local progress=$((100 * elapsed / duration))
        local bar_width=50
        local filled=$((bar_width * progress / 100))
        local empty=$((bar_width - filled))
        printf "\r["
        [ ''$filled -gt 0 ] && printf "%0.s=" $(seq 1 ''$filled)
        [ ''$empty -gt 0 ] && printf "%0.s " $(seq 1 ''$empty)
        printf "] %3d%%" ''$progress
      }

      for input in "''${files[@]}"; do
        input_basename="''${input##*/}"
        basename_lower=$(echo "''$input_basename" | tr '[:upper:]' '[:lower:]')

        if [[ "''$basename_lower" == *"compressed"* ]] || [[ "''$basename_lower" == *"smaller"* ]] || [[ "''$basename_lower" == *"cannotcompress"* ]]; then
          echo "✓ Skipping: ''$input_basename"
          continue
        fi

        ((current_file++))
        echo -e "\nProcessing file ''$current_file of ''$total_files: ''$input_basename"

        input_size=$(stat -c%s "''$input" 2>/dev/null || stat -f%z "''$input")
        input_size_mb=$(echo "scale=2; ''$input_size / 1024 / 1024" | bc)
        original_size=$((original_size + input_size))
        extension="''${input##*.}"
        extension_lower=$(echo "''$extension" | tr '[:upper:]' '[:lower:]')

        if [[ "''$extension_lower" == "mp4" || "''$extension_lower" == "mov" || "''$extension_lower" == "avi" || "''$extension_lower" == "mkv" || "''$extension_lower" == "3gp" || "''$extension_lower" == "webm" || "''$extension_lower" == "flv" || "''$extension_lower" == "wmv" || "''$extension_lower" == "m4v" || "''$extension_lower" == "mpeg" || "''$extension_lower" == "mpg" || "''$extension_lower" == "divx" ]]; then
          duration=$(ffprobe -i "''$input" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null | awk '{print int($1)}')
          [ -z "''$duration" ] || [ "''$duration" -eq 0 ] && duration=1
          
          if command -v chafa &> /dev/null; then
            thumbnail_time=$(echo "if (''$duration * 0.1 < 5) ''$duration * 0.1 else 5" | bc)
            ffmpeg -i "''$input" -ss "''$thumbnail_time" -vframes 1 -f image2pipe -vcodec png - 2>/dev/null | chafa --size 60x30 -
          fi

          output_file="''${input%.*}-smaller-crf28.mp4"
          ffmpeg -i "''$input" -vcodec libx265 -crf 28 "''$output_file" -progress pipe:1 2>&1 | while IFS= read -r line; do
            if [[ "''$line" == "out_time_ms="* ]]; then
              elapsed=$(echo "''$line" | cut -d= -f2 | awk '{print int($1 / 1000000)}')
              show_progress_bar ''$duration ''$elapsed
            fi
          done
          echo ""

        elif [[ "''$extension_lower" == "jpg" || "''$extension_lower" == "jpeg" || "''$extension_lower" == "png" ]]; then
          output_file="''${input%.*}-smaller.''${extension}"
          [ -x "''$(command -v chafa)" ] && chafa --size 60x30 "''$input"
          convert "''$input" -resize '1080x1080>' -quality 85 -strip "''$output_file" 2>&1
        else
          continue
        fi

        if [ -f "''$output_file" ] && [ -s "''$output_file" ]; then
          output_size=$(stat -c%s "''$output_file" 2>/dev/null || stat -f%z "''$output_file")
          if [ ''$output_size -ge ''$input_size ]; then
            rm "''$output_file"
            mv "''$input" "''${input%.*}-cannotcompress.''${extension}"
            ((skipped_files++))
          else
            # TRASH LOGIC: Sends original to KDE Trash instead of an 'old' folder
            if trash-put "''$input"; then
              compressed_size=$((compressed_size + output_size))
              echo -e "\n✅ SUCCESS: Original sent to Trash 🗑️"
            fi
          fi
        fi
      done

      # Rename parent folder logic
      parent_dir=$(dirname "$PWD")
      if [[ ! "''$current_folder_name" =~ \ -\ COMP$ ]]; then
        new_dir_name="''${current_folder_name} - COMP"
        cd "''$parent_dir" && mv "''$current_folder_name" "''$new_dir_name" 2>/dev/null && echo "Folder renamed to ''$new_dir_name"
      fi
    '')
  ];
}

  # ==========================================
  # SCRIPT END
  # ==========================================






    '')
  ];
}

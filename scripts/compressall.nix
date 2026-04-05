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


#!/bin/bash

echo "Compress all script 08/01-26"

# Get the name of the current directory
current_folder_name=$(basename "$PWD")
old_folder_name="${current_folder_name} - OLD"

# Create the specific old directory if it doesn't exist
mkdir -p "$old_folder_name"

# Find all video files (including DivX) - excluding files with "compressed" or "smaller" in name
mapfile -d '' video_files < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.3gp" -o -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" -o -iname "*.mpeg" -o -iname "*.mpg" -o -iname "*.divx" \) ! -iname "*compressed*" ! -iname "*smaller*" ! -iname "*cannotcompress*" -print0)

# Find all image files - excluding files with "compressed" or "smaller" in name
mapfile -d '' image_files < <(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -iname "*compressed*" ! -iname "*smaller*" ! -iname "*cannotcompress*" -print0)

# Combine all files
files=("${video_files[@]}" "${image_files[@]}")

# Count total files
total_files=${#files[@]}
current_file=0
original_size=0
compressed_size=0
skipped_files=0

# Check if there are files to process
if [ $total_files -eq 0 ]; then
  echo "No video or image files found in the current directory."
  echo "(Files with 'compressed' or 'smaller' in the name are automatically skipped)"
  exit 1
fi

echo "Found ${#video_files[@]} video(s) and ${#image_files[@]} image(s) to process."
echo "(Skipping any files with 'compressed' or 'smaller' in the name)"
echo ""
echo "=== Files found: ==="
for f in "${files[@]}"; do
  echo "  - ${f##*/}"
done
echo "=========================================="
echo ""

# Function to display the progress bar
show_progress_bar() {
  local duration=$1
  local elapsed=$2
  local progress=$((100 * elapsed / duration))
  local bar_width=50
  local filled=$((bar_width * progress / 100))
  local empty=$((bar_width - filled))

  # Build the progress bar
  printf "\r["
  if [ $filled -gt 0 ]; then
    printf "%0.s=" $(seq 1 $filled)
  fi
  if [ $empty -gt 0 ]; then
    printf "%0.s " $(seq 1 $empty)
  fi
  printf "] %3d%%" $progress
}

# Process each file
for input in "${files[@]}"; do
  input_basename="${input##*/}"
  basename_lower=$(echo "$input_basename" | tr '[:upper:]' '[:lower:]')

  if [[ "$basename_lower" == *"compressed"* ]] || [[ "$basename_lower" == *"smaller"* ]] || [[ "$basename_lower" == *"cannotcompress"* ]]; then
    echo "✓ Skipping already processed file: $input_basename"
    echo ""
    continue
  fi

  ((current_file++))
  echo -e "\n=========================================="
  echo "Processing file $current_file of $total_files"
  echo "File: $input_basename"

  input_size=$(stat -c%s "$input" 2>/dev/null || stat -f%z "$input")
  input_size_mb=$(echo "scale=2; $input_size / 1024 / 1024" | bc)
  original_size=$((original_size + input_size))

  extension="${input##*.}"
  extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

  if [[ "$extension_lower" == "mp4" || "$extension_lower" == "mov" || "$extension_lower" == "avi" || "$extension_lower" == "mkv" || "$extension_lower" == "3gp" || "$extension_lower" == "webm" || "$extension_lower" == "flv" || "$extension_lower" == "wmv" || "$extension_lower" == "m4v" || "$extension_lower" == "mpeg" || "$extension_lower" == "mpg" || "$extension_lower" == "divx" ]]; then
    duration=$(ffprobe -i "$input" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null | awk '{print int($1)}')
    if [ -z "$duration" ] || [ "$duration" -eq 0 ]; then duration=1; fi

    if command -v chafa &> /dev/null; then
      echo ""
      thumbnail_time=$(echo "if ($duration * 0.1 < 5) $duration * 0.1 else 5" | bc)
      ffmpeg -i "$input" -ss "$thumbnail_time" -vframes 1 -f image2pipe -vcodec png - 2>/dev/null | chafa --size 60x30 -
      echo ""
    fi
    echo "=========================================="
    echo ""
    echo "Original size: ${input_size_mb} MB"

    output_file="${input%.*}-smaller-crf28.mp4"

    echo "Compressing video with H.265 encoding (CRF 28)..."
    ffmpeg -i "$input" -vcodec libx265 -crf 28 "$output_file" -progress pipe:1 2>&1 | while IFS= read -r line; do
      if [[ "$line" == "out_time_ms="* ]]; then
        elapsed=$(echo "$line" | cut -d= -f2 | awk '{print int($1 / 1000000)}')
        show_progress_bar $duration $elapsed
      fi
    done
    echo "" 

  elif [[ "$extension_lower" == "jpg" || "$extension_lower" == "jpeg" || "$extension_lower" == "png" ]]; then
    output_file="${input%.*}-smaller.${extension}"
    if command -v chafa &> /dev/null; then
      echo ""
      echo "Preview:"
      chafa --size 60x30 "$input"
      echo ""
    fi
    echo "Resizing and optimizing image..."
    convert "$input" -resize '1080x1080>' -quality 85 -strip "$output_file" 2>&1
  else
    echo "Unknown file type, skipping..."
    continue
  fi

  if [ -f "$output_file" ] && [ -s "$output_file" ]; then
    output_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file")
    output_size_mb=$(echo "scale=2; $output_size / 1024 / 1024" | bc)
    echo "Compressed size: ${output_size_mb} MB"

    if [ $output_size -ge $input_size ]; then
      size_diff=$((output_size - input_size))
      size_diff_mb=$(echo "scale=2; $size_diff / 1024 / 1024" | bc)
      percentage=$(echo "scale=1; ($output_size - $input_size) * 100 / $input_size" | bc)
      echo ""
      echo "⚠️  COMPRESSION INEFFECTIVE"
      echo "Compressed file is ${size_diff_mb} MB larger (+${percentage}%)"
      rm "$output_file"
      new_name="${input%.*}-cannotcompress.${extension}"
      mv "$input" "$new_name"
      ((skipped_files++))
    else
      # Move the original file to the NEW named folder
      if mv "$input" "$old_folder_name/"; then
        compressed_size=$((compressed_size + output_size))
        file_space_saved=$((input_size - output_size))
        file_space_saved_mb=$(echo "scale=2; $file_space_saved / 1024 / 1024" | bc)
        percentage=$(echo "scale=1; $file_space_saved * 100 / $input_size" | bc)
        echo ""
        echo "✅ COMPRESSION SUCCESSFUL"
        echo "Space saved: ${file_space_saved_mb} MB (${percentage}% reduction)"
        echo "Original moved to: $old_folder_name/${input##*/}"
        echo "Compressed file: ${output_file##*/}"
      else
        echo ""
        echo "⚠️  Warning: Compression succeeded but couldn't move original to '$old_folder_name'"
        compressed_size=$((compressed_size + output_size))
      fi
    fi
  else
    echo ""
    echo "❌ COMPRESSION FAILED"
    [ -f "$output_file" ] && rm "$output_file"
  fi
done

# Calculate space saved
space_saved=$((original_size - compressed_size))
space_saved_mb=$(echo "scale=2; $space_saved / 1024 / 1024" | bc)
original_size_mb=$(echo "scale=2; $original_size / 1024 / 1024" | bc)
compressed_size_mb=$(echo "scale=2; $compressed_size / 1024 / 1024" | bc)

echo -e "\n=========================================="
echo "All files processed!"
echo "=========================================="
echo -e "Original size: ${original_size_mb} MB"
echo -e "Compressed size: ${compressed_size_mb} MB"
echo -e "Space saved: ${space_saved_mb} MB"
if [ $skipped_files -gt 0 ]; then
  echo -e "Files that couldn't be compressed: ${skipped_files}"
fi

# Finally, rename parent folder by adding " - COMP" suffix
# Note: $current_folder_name was set at the very beginning
parent_dir=$(dirname "$PWD")

if [[ ! "$current_folder_name" =~ \ -\ COMP$ ]]; then
  new_dir_name="${current_folder_name} - COMP"
  new_path="${parent_dir}/${new_dir_name}"
  echo -e "\nRenaming folder '${current_folder_name}' to '${new_dir_name}'..."
  cd "$parent_dir"
  if mv "$current_folder_name" "$new_dir_name" 2>/dev/null; then
    echo "Folder renamed successfully!"
    echo "New location: ${new_path}"
  else
    echo "Warning: Could not rename folder."
  fi
else
  echo -e "\nFolder already has ' - COMP' suffix, skipping rename."
fi


  # ==========================================
  # SCRIPT END
  # ==========================================






    '')
  ];
}


{ pkgs, ... }:

{
  # This automatically provides all the tools your script needs!
  environment.systemPackages = with pkgs; [
    ffmpeg
    bc
    imagemagick
    chafa

    # This creates your global 'compressall' command
    (pkgs.writeShellScriptBin "compressall" ''


  # ==========================================
  # SCRIPT START
  # ==========================================


#!/bin/bash

# ============================================================================
# VIDEO AND IMAGE COMPRESSION SCRIPT (DEC 20. 2025 v3.1)
# ============================================================================
# This script compresses videos (.mp4, .mov, .avi) and images (.jpg, .jpeg, .png)
# - Videos: Compressed using H.265 encoding
# - Images: Resized to max 1080px (maintaining aspect ratio) and optimized
# - If compressed file is larger than original, it's deleted and original renamed
# Original files are moved to an "old" folder after successful compression
# Files with "compressed" or "smaller" in the filename are ignored
#
# INSTALLATION INSTRUCTIONS
# ============================================================================

# 1. Save this script as a file named "compressall" (no extension)

# 2. Make it executable (so it can be run as a program):
#    chmod +x compressall

# 3. Install it system-wide so it can be run from anywhere:
#    sudo cp compressall /usr/local/bin/

# 4. Ensure the installed copy is executable (important):
#    sudo chmod +x /usr/local/bin/compressall

# 5. Install required tools:
#    Ubuntu/Debian: sudo apt install ffmpeg bc imagemagick chafa
#    Fedora/RHEL:   sudo dnf install ffmpeg bc ImageMagick chafa
#    Arch:          sudo pacman -S ffmpeg bc imagemagick chafa
#    macOS:         brew install ffmpeg bc imagemagick chafa
#
#    Note: chafa is used to display video thumbnails in the terminal
#
# USAGE:
# ============================================================================
# Navigate to any folder containing video/image files and run:
#    compressall
#
# The script will compress all media and move originals to "old/" subfolder
# ============================================================================

echo "Compress all script 08/01-26"

# Create the old directory if it doesn't exist
mkdir -p old

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
  # Double-check: Skip files with "compressed" or "smaller" in the name (case-insensitive)
  # Use parameter expansion to get basename, which handles special chars better
  input_basename="${input##*/}"
  basename_lower=$(echo "$input_basename" | tr '[:upper:]' '[:lower:]')

  # Debug output
  # echo "DEBUG: Checking file: '$input_basename'"
  # echo "DEBUG: Lowercase version: '$basename_lower'"

  if [[ "$basename_lower" == *"compressed"* ]] || [[ "$basename_lower" == *"smaller"* ]] || [[ "$basename_lower" == *"cannotcompress"* ]]; then
    echo "✓ Skipping already processed file: $input_basename"
    echo ""
    continue
  fi

  ((current_file++))
  echo -e "\n=========================================="
  echo "Processing file $current_file of $total_files"
  echo "File: $input_basename"
  # echo "=========================================="

  # Get the size of the original file in bytes
  input_size=$(stat -c%s "$input" 2>/dev/null || stat -f%z "$input")
  input_size_mb=$(echo "scale=2; $input_size / 1024 / 1024" | bc)
  # echo "Original size: ${input_size_mb} MB"
  original_size=$((original_size + input_size))

  # Get file extension
  extension="${input##*.}"
  extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

  # Determine if it's a video or image
  if [[ "$extension_lower" == "mp4" || "$extension_lower" == "mov" || "$extension_lower" == "avi" || "$extension_lower" == "mkv" || "$extension_lower" == "3gp" || "$extension_lower" == "webm" || "$extension_lower" == "flv" || "$extension_lower" == "wmv" || "$extension_lower" == "m4v" || "$extension_lower" == "mpeg" || "$extension_lower" == "mpg" || "$extension_lower" == "divx" ]]; then
    # PROCESS VIDEO
    # Get the total duration of the input file in seconds
    duration=$(ffprobe -i "$input" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null | awk '{print int($1)}')

    if [ -z "$duration" ] || [ "$duration" -eq 0 ]; then
      duration=1  # Avoid division by zero
    fi

    # Show video thumbnail if chafa is available
    if command -v chafa &> /dev/null; then
      echo ""
      # echo "Preview:"
      # Extract frame at 10% of video duration (or 5 seconds, whichever is less)
      thumbnail_time=$(echo "if ($duration * 0.1 < 5) $duration * 0.1 else 5" | bc)
      ffmpeg -i "$input" -ss "$thumbnail_time" -vframes 1 -f image2pipe -vcodec png - 2>/dev/null | chafa --size 60x30 -
      echo ""
    fi
      echo "=========================================="
      echo ""
      echo "Original size: ${input_size_mb} MB"

    # Compress the file using ffmpeg and capture progress
    # Output as .mp4 for better compatibility
    output_file="${input%.*}-smaller-crf28.mp4"

    echo "Compressing video with H.265 encoding (CRF 28)..."
    ffmpeg -i "$input" -vcodec libx265 -crf 28 "$output_file" -progress pipe:1 2>&1 | while IFS= read -r line; do
      if [[ "$line" == "out_time_ms="* ]]; then
        elapsed=$(echo "$line" | cut -d= -f2 | awk '{print int($1 / 1000000)}')
        show_progress_bar $duration $elapsed
      fi
    done
    echo ""  # New line after progress bar

  elif [[ "$extension_lower" == "jpg" || "$extension_lower" == "jpeg" || "$extension_lower" == "png" ]]; then
    # PROCESS IMAGE
    output_file="${input%.*}-smaller.${extension}"

    # Show image preview if chafa is available
    if command -v chafa &> /dev/null; then
      echo ""
      echo "Preview:"
      chafa --size 60x30 "$input"
      echo ""
    fi

    # Resize to max 1080px (maintaining aspect ratio) and optimize
    echo "Resizing and optimizing image..."
    convert "$input" -resize '1080x1080>' -quality 85 -strip "$output_file" 2>&1

  else
    echo "Unknown file type, skipping..."
    continue
  fi

  # Check if compression succeeded
  if [ -f "$output_file" ] && [ -s "$output_file" ]; then
    # Get the size of the compressed file in bytes
    output_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file")
    output_size_mb=$(echo "scale=2; $output_size / 1024 / 1024" | bc)

    echo "Compressed size: ${output_size_mb} MB"

    # Compare file sizes
    if [ $output_size -ge $input_size ]; then
      # Compressed file is larger or equal - compression failed
      size_diff=$((output_size - input_size))
      size_diff_mb=$(echo "scale=2; $size_diff / 1024 / 1024" | bc)
      percentage=$(echo "scale=1; ($output_size - $input_size) * 100 / $input_size" | bc)

      echo ""
      echo "⚠️  COMPRESSION INEFFECTIVE"
      echo "Compressed file is ${size_diff_mb} MB larger (+${percentage}%)"

      # Delete the compressed file
      rm "$output_file"

      # Rename original file (stays in current directory)
      new_name="${input%.*}-cannotcompress.${extension}"
      mv "$input" "$new_name"
      echo "Action: Deleted compressed file, renamed original"
      echo "New name: ${new_name##*/}"

      # Don't count this in compressed size
      ((skipped_files++))
    else
      # Compression successful - file is smaller
      # NOW move the original file to the old folder (after compression is verified)
      if mv "$input" old/; then
        compressed_size=$((compressed_size + output_size))

        # Calculate space saved for this file
        file_space_saved=$((input_size - output_size))
        file_space_saved_mb=$(echo "scale=2; $file_space_saved / 1024 / 1024" | bc)
        percentage=$(echo "scale=1; $file_space_saved * 100 / $input_size" | bc)

        echo ""
        echo "✅ COMPRESSION SUCCESSFUL"
        echo "Space saved: ${file_space_saved_mb} MB (${percentage}% reduction)"
        echo "Compression ratio: $(echo "scale=2; $input_size / $output_size" | bc):1"
        echo "Original moved to: old/${input##*/}"
        echo "Compressed file: ${output_file##*/}"
      else
        echo ""
        echo "⚠️  Warning: Compression succeeded but couldn't move original to 'old' folder"
        echo "Compressed file created: $output_file"
        # Still count the compressed file
        compressed_size=$((compressed_size + output_size))
      fi
    fi
  else
    echo ""
    echo "❌ COMPRESSION FAILED"
    echo "Output file was not created or is empty"
    echo "Original file preserved: $input_basename"
    # Remove failed output file if it exists
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

# Rename parent folder by adding " - COMP" suffix
current_dir=$(basename "$PWD")
parent_dir=$(dirname "$PWD")

# Check if folder name doesn't already end with " - COMP"
if [[ ! "$current_dir" =~ \ -\ COMP$ ]]; then
  new_dir_name="${current_dir} - COMP"
  new_path="${parent_dir}/${new_dir_name}"

  echo -e "\nRenaming folder '${current_dir}' to '${new_dir_name}'..."

  # Move to parent directory before renaming
  cd "$parent_dir"

  if mv "$current_dir" "$new_dir_name" 2>/dev/null; then
    echo "Folder renamed successfully!"
    echo "New location: ${new_path}"
  else
    echo "Warning: Could not rename folder. You may need to do this manually."
  fi
else
  echo -e "\nFolder already has ' - COMP' suffix, skipping rename."
fi


  # ==========================================
  # SCRIPT START
  # ==========================================






    '')
  ];
}


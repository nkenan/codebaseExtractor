#!/bin/bash

# Codebase Extractor Script - FIXED VERSION
# Creates a TXT file with the entire content of a codebase for LLM analysis

# Configuration
OUTPUT_FILE="codebase_export.txt"
MAX_FILE_SIZE=1048576  # 1MB in bytes
TARGET_PATHS=()  # Array for specific paths
DRY_RUN=false
INCLUDE_METADATA=false

# Error handling
set -euo pipefail
trap 'echo "Error occurred at line $LINENO"' ERR

# Blacklist for folders and files
BLACKLIST_DIRS=(
    "vendor"
    "node_modules"
    ".git"
    ".svn"
    ".hg"
    "dist"
    "build"
    "target"
    "__pycache__"
    ".pytest_cache"
    ".vscode"
    ".idea"
    "tmp"
    "temp"
    "cache"
    "logs"
    ".next"
    ".nuxt"
    "coverage"
    ".nyc_output"
    "public/uploads"
    "storage"
    "var/cache"
    "var/log"
    "uploads"
)

BLACKLIST_FILES=(
    "*.env"
    "*.log"
    "*.tmp"
    "*.cache"
    "*.lock"
    "package-lock.json"
    "yarn.lock"
    "composer.lock"
    "Pipfile.lock"
    "poetry.lock"
    ".DS_Store"
    "Thumbs.db"
    "*.pid"
    "*.swp"
    "*.swo"
    "*~"
)

# Web server file extensions (include)
INCLUDE_EXTENSIONS=(
    "php" "html" "htm" "css" "scss" "sass" "less"
    "js" "jsx" "ts" "tsx" "vue" "svelte"
    "py" "rb" "java" "c" "cpp" "cs" "go" "rs"
    "json" "xml" "yaml" "yml" "toml" "ini" "conf"
    "sql" "md" "txt" "htaccess" "gitignore"
    "dockerfile" "makefile" "sh" "bat" "ps1"
    "twig" "blade" "smarty" "handlebars" "mustache"
    "asp" "aspx" "jsp" "erb" "ejs" "pug" "jade"
    "env" "graphql" "gql" "proto" "tf" "ipynb"
)

# Media file extensions (exclude)
EXCLUDE_EXTENSIONS=(
    "jpg" "jpeg" "png" "gif" "bmp" "svg" "webp" "ico"
    "mp4" "avi" "mov" "wmv" "flv" "webm" "mkv"
    "mp3" "wav" "ogg" "flac" "aac" "wma"
    "pdf" "doc" "docx" "xls" "xlsx" "ppt" "pptx"
    "zip" "rar" "tar" "gz" "7z" "bz2"
    "exe" "dll" "so" "dylib" "bin"
    "ttf" "otf" "woff" "woff2" "eot"
)

# Function: Load configuration file if exists
load_config() {
    local config_file=".codebase-extractor.conf"
    if [[ -f "$config_file" ]]; then
        echo "Loading configuration from $config_file..."
        source "$config_file"
    fi
}

# Function: Get file size cross-platform
get_file_size() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$file" 2>/dev/null || echo 0
    else
        stat -c%s "$file" 2>/dev/null || echo 0
    fi
}

# Function: Get file metadata
get_file_metadata() {
    local file="$1"
    local size=$(get_file_size "$file")
    local human_size=""
    
    # Convert to human readable
    if [[ $size -lt 1024 ]]; then
        human_size="${size}B"
    elif [[ $size -lt 1048576 ]]; then
        human_size="$((size / 1024))KB"
    else
        human_size="$((size / 1048576))MB"
    fi
    
    # Get modification time
    local mod_time=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mod_time=$(stat -f"%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || echo "unknown")
    else
        mod_time=$(stat -c"%y" "$file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
    fi
    
    # Get permissions
    local perms=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        perms=$(stat -f"%Sp" "$file" 2>/dev/null || echo "unknown")
    else
        perms=$(stat -c"%A" "$file" 2>/dev/null || echo "unknown")
    fi
    
    echo "Size: $human_size | Modified: $mod_time | Permissions: $perms"
}

# Function: Check if file is binary
is_binary_file() {
    local file="$1"
    # Check if file command exists
    if command -v file >/dev/null 2>&1; then
        file -b "$file" | grep -qE "binary|executable|data|compressed"
        return $?
    fi
    # Fallback: check for null bytes in first 1KB
    head -c 1024 "$file" 2>/dev/null | grep -q $'\x00'
    return $?
}

# Function: Checks if path is blacklisted
is_blacklisted() {
    local path="$1"
    local basename=$(basename "$path")
    
    # Check folder blacklist
    for blacklist_dir in "${BLACKLIST_DIRS[@]}"; do
        if [[ "$path" == *"/$blacklist_dir"* ]] || [[ "$basename" == "$blacklist_dir" ]]; then
            return 0
        fi
    done
    
    # Check file blacklist (wildcards) - FIXED
    for pattern in "${BLACKLIST_FILES[@]}"; do
        # Handle wildcard patterns properly
        if [[ "$pattern" == *.* ]]; then
            # Pattern like *.env
            local ext="${pattern#*.}"
            if [[ "$basename" == .$ext ]] || [[ "$basename" == *.$ext ]]; then
                return 0
            fi
        else
            # Exact match
            if [[ "$basename" == "$pattern" ]]; then
                return 0
            fi
        fi
    done
    
    return 1
}

# Function: Checks if file extension is allowed
is_allowed_extension() {
    local file="$1"
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    # Check if file has an extension
    if [[ "$file" == "$extension" ]]; then
        # No extension - check if it's a known configuration file
        local basename=$(basename "$file")
        case "$basename" in
            "Dockerfile"|"Makefile"|"Rakefile"|"Gemfile"|"Procfile"|"requirements.txt"|".gitignore"|".htaccess"|"env")
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
    
    # Check excluded extensions
    for ext in "${EXCLUDE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 1
        fi
    done
    
    # Check included extensions
    for ext in "${INCLUDE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 0
        fi
    done
    
    return 1
}

# FIXED: Create tree structure function
create_tree_structure() {
    echo "=== FOLDER STRUCTURE ==="
    echo ""
    
    if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
        # Show current directory structure
        echo "Current directory: $(pwd)"
        echo ""
        
        # Find all directories (excluding blacklisted ones)
        find . -type d -not -path './.*' 2>/dev/null | sort | while read -r dir; do
            if ! is_blacklisted "$dir"; then
                # Calculate depth for indentation
                local depth=$(echo "$dir" | sed 's|[^/]||g' | wc -c)
                local indent=""
                for ((i=1; i<depth; i++)); do
                    indent+="  "
                done
                local dirname=$(basename "$dir")
                if [[ "$dir" == "." ]]; then
                    echo "."
                else
                    echo "${indent}${dirname}/"
                fi
            fi
        done
    else
        # Only show specific paths
        for target_path in "${TARGET_PATHS[@]}"; do
            if [[ -d "$target_path" ]]; then
                echo "Folder: $target_path/"
                find "$target_path" -type d 2>/dev/null | while read -r dir; do
                    if ! is_blacklisted "$dir"; then
                        relative_dir="${dir#$target_path/}"
                        if [[ "$relative_dir" != "$dir" ]]; then
                            echo "  $relative_dir/"
                        fi
                    fi
                done
            elif [[ -f "$target_path" ]]; then
                echo "File: $target_path"
            fi
        done
    fi
    
    echo ""
    echo "=== FILES ==="
    echo ""
}

# FIXED: Collect files function
collect_files() {
    local temp_file=$(mktemp)
    
    if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
        # Find all files in current directory
        find . -type f 2>/dev/null | sort > "$temp_file"
    else
        # Handle specific paths
        for target_path in "${TARGET_PATHS[@]}"; do
            if [[ -f "$target_path" ]]; then
                echo "$target_path" >> "$temp_file"
            elif [[ -d "$target_path" ]]; then
                find "$target_path" -type f 2>/dev/null >> "$temp_file"
            else
                echo "Warning: Path not found: $target_path" >&2
            fi
        done
        sort -u "$temp_file" -o "$temp_file"
    fi
    
    echo "$temp_file"
}

# Function: Processes a file with streaming
process_file() {
    local file="$1"
    local relative_path="${file#./}"
    
    echo "Processing: $relative_path" >&2
    
    # Check file size
    local file_size=$(get_file_size "$file")
    
    if [[ $file_size -gt $MAX_FILE_SIZE ]]; then
        echo "--- $relative_path BEGINNING ---"
        if [[ "$INCLUDE_METADATA" == true ]]; then
            echo "[METADATA: $(get_file_metadata "$file")]"
        fi
        echo "[FILE TOO LARGE: $(($file_size / 1024))KB - SKIPPED]"
        echo ""
        echo "--- $relative_path END ---"
        echo ""
        return
    fi
    
    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        echo "--- $relative_path BEGINNING ---"
        if [[ "$INCLUDE_METADATA" == true ]]; then
            echo "[METADATA: $(get_file_metadata "$file")]"
        fi
        echo "[FILE NOT READABLE - SKIPPED]"
        echo ""
        echo "--- $relative_path END ---"
        echo ""
        return
    fi
    
    # Check if file is binary
    if is_binary_file "$file"; then
        echo "--- $relative_path BEGINNING ---"
        if [[ "$INCLUDE_METADATA" == true ]]; then
            echo "[METADATA: $(get_file_metadata "$file")]"
        fi
        echo "[BINARY FILE - SKIPPED]"
        echo ""
        echo "--- $relative_path END ---"
        echo ""
        return
    fi
    
    echo "--- $relative_path BEGINNING ---"
    if [[ "$INCLUDE_METADATA" == true ]]; then
        echo "[METADATA: $(get_file_metadata "$file")]"
    fi
    
    # Special handling for Jupyter notebooks
    if [[ "${file##*.}" == "ipynb" ]]; then
        echo "[JUPYTER NOTEBOOK - Showing JSON structure]"
    fi
    
    # Stream file content
    cat "$file" 2>/dev/null || echo "[ERROR: Could not read file content]"
    echo ""
    echo "--- $relative_path END ---"
    echo ""
}

# Main function
main() {
    # Load configuration if exists
    load_config
    
    echo "Codebase Extractor started..." >&2
    echo "Output file: $OUTPUT_FILE" >&2
    echo "Dry run: $DRY_RUN" >&2
    echo "Include metadata: $INCLUDE_METADATA" >&2
    echo "" >&2
    
    if [[ "$DRY_RUN" == false ]]; then
        # Delete old output file
        rm -f "$OUTPUT_FILE"
    fi
    
    # Create header
    local header_content=$(cat <<EOF
CODEBASE EXPORT
Created on: $(date)
Directory: $(pwd)
Options: Dry-run=$DRY_RUN, Metadata=$INCLUDE_METADATA

===============================================

EOF
)
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "$header_content"
        create_tree_structure
    else
        {
            echo "$header_content"
            create_tree_structure
        } > "$OUTPUT_FILE"
    fi
    
    # Find and process all files
    echo "Collecting files..." >&2
    local temp_file_list=$(collect_files)
    
    if [[ -f "$temp_file_list" ]]; then
        # Count total files for progress
        local total_files=$(wc -l < "$temp_file_list")
        local current_file=0
        local processed_count=0
        local skipped_count=0
        
        echo "Found $total_files files to check" >&2
        
        while IFS= read -r file; do
            # Skip empty lines
            [[ -z "$file" ]] && continue
            
            # Skip output file itself
            if [[ "$file" == "./$OUTPUT_FILE" ]] || [[ "$file" == "$OUTPUT_FILE" ]]; then
                continue
            fi
            
            ((current_file++))
            
            # Check blacklist
            if is_blacklisted "$file"; then
                echo "Skipping (blacklisted): $file" >&2
                ((skipped_count++))
                continue
            fi
            
            # Check file extension
            if ! is_allowed_extension "$file"; then
                echo "Skipping (extension not allowed): $file" >&2
                ((skipped_count++))
                continue
            fi
            
            echo "Processing [$current_file/$total_files]: $file" >&2
            
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would process: $file"
                if [[ "$INCLUDE_METADATA" == true ]]; then
                    echo "  Metadata: $(get_file_metadata "$file")"
                fi
            else
                process_file "$file" >> "$OUTPUT_FILE"
            fi
            
            ((processed_count++))
        done < "$temp_file_list"
        
        # Clean up temporary file
        rm -f "$temp_file_list"
        
        echo "" >&2
        echo "Export completed!" >&2
        echo "Files processed: $processed_count" >&2
        echo "Files skipped: $skipped_count" >&2
        
        if [[ "$DRY_RUN" == false ]]; then
            echo "Output file: $OUTPUT_FILE" >&2
            if command -v du >/dev/null 2>&1; then
                echo "File size: $(du -h "$OUTPUT_FILE" 2>/dev/null | cut -f1 || echo "Unknown")" >&2
            else
                echo "File size: Unknown" >&2
            fi
        fi
    else
        echo "Error: Could not create temporary file list" >&2
        exit 1
    fi
}

# Help text
show_help() {
    echo "Codebase Extractor Script - Fixed Version"
    echo ""
    echo "USAGE:"
    echo "  $0 [OPTIONS] [PATHS...]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help       Shows this help"
    echo "  -o, --output     Output file (default: $OUTPUT_FILE)"
    echo "  -d, --dry-run    Show what would be extracted without creating file"
    echo "  -m, --metadata   Include file metadata (size, modified date, permissions)"
    echo ""
    echo "PATHS:"
    echo "  Without paths: Exports all files in the current directory"
    echo "  With paths:    Exports only the specified files/folders"
    echo "                 Folders are processed recursively"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                           # Exports entire directory"
    echo "  $0 -o code.txt src/ docs/    # Exports src/ and docs/ folders"
    echo "  $0 file.php config.json      # Exports only these files"
    echo "  $0 -d                        # Dry run to see what would be processed"
    echo ""
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -m|--metadata)
            INCLUDE_METADATA=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # All remaining arguments are paths
            TARGET_PATHS+=("$1")
            shift
            ;;
    esac
done

# Execute script
main

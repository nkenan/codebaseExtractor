#!/bin/bash

# Codebase Extractor Script
# Creates a TXT file with the entire content of a codebase for LLM analysis

# Configuration
OUTPUT_FILE="codebase_export.txt"
MAX_FILE_SIZE=1048576  # 1MB in bytes
TARGET_PATHS=()  # Array for specific paths

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
    
    # Check file blacklist (wildcards)
    for pattern in "${BLACKLIST_FILES[@]}"; do
        if [[ "$basename" == $pattern ]]; then
            return 0
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
            "Dockerfile"|"Makefile"|"Rakefile"|"Gemfile"|"Procfile"|"requirements.txt"|".gitignore"|".htaccess")
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

# Extended create_tree_structure function:
create_tree_structure() {
    echo "=== FOLDER STRUCTURE ==="
    echo ""
    
    if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
        # Original code for entire directory
        find . -type d | while read -r dir; do
            if ! is_blacklisted "$dir"; then
                depth=$(echo "$dir" | grep -o "/" | wc -l)
                indent=""
                for ((i=0; i<depth; i++)); do
                    indent+="  "
                done
                echo "${indent}$(basename "$dir")/"
            fi
        done
    else
        # Only show specific paths
        for target_path in "${TARGET_PATHS[@]}"; do
            if [[ -d "$target_path" ]]; then
                echo "Folder: $target_path/"
                find "$target_path" -type d | while read -r dir; do
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

# Fixed function for collecting files:
collect_files() {
    local temp_file=$(mktemp)
    
    if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
        # Original code - all files in current directory
        find . -type f | sort > "$temp_file"
    else
        # Process specific paths
        for target_path in "${TARGET_PATHS[@]}"; do
            if [[ -f "$target_path" ]]; then
                # Single file
                echo "$target_path" >> "$temp_file"
            elif [[ -d "$target_path" ]]; then
                # Folder recursively
                find "$target_path" -type f | sort >> "$temp_file"
            else
                echo "Warning: Path not found: $target_path" >&2
            fi
        done
    fi
    
    echo "$temp_file"
}

# Function: Processes a file
process_file() {
    local file="$1"
    local relative_path="${file#./}"
    
    # Check file size - Fixed for better compatibility
    local file_size=0
    if command -v stat >/dev/null 2>&1; then
        if stat -f%z "$file" >/dev/null 2>&1; then
            file_size=$(stat -f%z "$file" 2>/dev/null)
        elif stat -c%s "$file" >/dev/null 2>&1; then
            file_size=$(stat -c%s "$file" 2>/dev/null)
        fi
    fi
    
    if [[ $file_size -gt $MAX_FILE_SIZE ]]; then
        echo "--- $relative_path BEGINNING ---"
        echo "[FILE TOO LARGE: $(($file_size / 1024))KB - SKIPPED]"
        echo ""
        echo "--- $relative_path END ---"
        echo ""
        return
    fi
    
    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        echo "--- $relative_path BEGINNING ---"
        echo "[FILE NOT READABLE - SKIPPED]"
        echo ""
        echo "--- $relative_path END ---"
        echo ""
        return
    fi
    
    # Check if file is binary - Fixed for better compatibility
    if command -v file >/dev/null 2>&1; then
        if file "$file" 2>/dev/null | grep -q "binary\|executable\|data"; then
            echo "--- $relative_path BEGINNING ---"
            echo "[BINARY FILE - SKIPPED]"
            echo ""
            echo "--- $relative_path END ---"
            echo ""
            return
        fi
    fi
    
    echo "--- $relative_path BEGINNING ---"
    # Indent content with tab
    cat "$file" | sed 's/^/\t/'
    echo ""
    echo "--- $relative_path END ---"
    echo ""
}

# Main function
main() {
    echo "Codebase Extractor started..."
    echo "Output file: $OUTPUT_FILE"
    echo ""
    
    # Delete old output file
    rm -f "$OUTPUT_FILE"
    
    # Create header
    {
        echo "CODEBASE EXPORT"
        echo "Created on: $(date)"
        echo "Directory: $(pwd)"
        echo ""
        echo "==============================================="
        echo ""
        
        # Create folder structure
        create_tree_structure
        
    } > "$OUTPUT_FILE"
    
    # Find and process all files - Fixed approach
    local temp_file_list=$(collect_files)
    
    if [[ -f "$temp_file_list" ]]; then
        while IFS= read -r file; do
            # Skip empty lines
            [[ -z "$file" ]] && continue
            
            # Skip output file itself
            if [[ "$file" == "./$OUTPUT_FILE" ]] || [[ "$file" == "$OUTPUT_FILE" ]]; then
                continue
            fi
            
            # Check blacklist
            if is_blacklisted "$file"; then
                continue
            fi
            
            # Check file extension
            if ! is_allowed_extension "$file"; then
                continue
            fi
            
            echo "Processing: $file"
            process_file "$file" >> "$OUTPUT_FILE"
        done < "$temp_file_list"
        
        # Clean up temporary file
        rm -f "$temp_file_list"
    else
        echo "Error: Could not create temporary file list"
        exit 1
    fi
    
    echo ""
    echo "Export completed!"
    echo "Output file: $OUTPUT_FILE"
    if command -v du >/dev/null 2>&1; then
        echo "File size: $(du -h "$OUTPUT_FILE" 2>/dev/null | cut -f1 || echo "Unknown")"
    else
        echo "File size: Unknown"
    fi
}

# Help text
show_help() {
    echo "Codebase Extractor Script"
    echo ""
    echo "USAGE:"
    echo "  $0 [OPTIONS] [PATHS...]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Shows this help"
    echo "  -o, --output   Output file (default: $OUTPUT_FILE)"
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
    echo "  $0 src/ README.md            # Exports src/ folder + README.md"
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

#!/bin/bash

# Simple Working Codebase Extractor
# Simplified version that focuses on actually working

OUTPUT_FILE="codebase_export.txt"
DRY_RUN=false

# Simple blacklist - only the essential ones
BLACKLIST_DIRS=(
    "node_modules" ".git" "logs" "uploads" "cache" "tmp" "temp"
    ".vscode" ".idea" "__pycache__" "vendor"
)

BLACKLIST_FILES=(
    "*.log" "*.tmp" "*.cache" "*.lock" ".DS_Store" "Thumbs.db"
    "codebase_export.txt" "codebaseExtractor.sh" "debug_extractor.sh"
)

# Extensions to include
INCLUDE_EXTENSIONS=(
    "php" "html" "htm" "css" "js" "json" "xml" "yaml" "yml"
    "sql" "md" "txt" "env" "htaccess" "gitignore" "conf" "ini"
)

# Check if path contains blacklisted directory
is_blacklisted_dir() {
    local path="$1"
    for blacklist_dir in "${BLACKLIST_DIRS[@]}"; do
        if [[ "$path" == *"/$blacklist_dir"* ]] || [[ "$path" == *"$blacklist_dir/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file is blacklisted
is_blacklisted_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    for pattern in "${BLACKLIST_FILES[@]}"; do
        if [[ "$pattern" == *.* ]]; then
            local ext="${pattern#*.}"
            if [[ "$basename" == *.$ext ]]; then
                return 0
            fi
        else
            if [[ "$basename" == "$pattern" ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Check if extension is allowed
is_allowed_extension() {
    local file="$1"
    local basename=$(basename "$file")
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    # Special files without extensions
    case "$basename" in
        ".env"|".htaccess"|"Dockerfile"|"Makefile")
            return 0
            ;;
    esac
    
    # Check if file has extension
    if [[ "$file" == "$extension" ]]; then
        return 1  # No extension
    fi
    
    # Check if extension is in allowed list
    for ext in "${INCLUDE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Process a single file
process_file() {
    local file="$1"
    local relative_path="${file#./}"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would process: $relative_path"
        return
    fi
    
    echo "Processing: $relative_path" >&2
    
    echo "--- $relative_path BEGINNING ---"
    cat "$file" 2>/dev/null || echo "[ERROR: Could not read file]"
    echo ""
    echo "--- $relative_path END ---"
    echo ""
}

# Main function
main() {
    echo "Simple Codebase Extractor started..." >&2
    echo "Output file: $OUTPUT_FILE" >&2
    echo "Dry run: $DRY_RUN" >&2
    echo "" >&2
    
    if [[ "$DRY_RUN" == false ]]; then
        rm -f "$OUTPUT_FILE"
    fi
    
    # Create header
    local header_content=$(cat <<EOF
CODEBASE EXPORT
Created on: $(date)
Directory: $(pwd)

===============================================

EOF
)
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "$header_content"
    else
        echo "$header_content" > "$OUTPUT_FILE"
    fi
    
    local processed_count=0
    local skipped_count=0
    
    # Process all files
    find . -type f 2>/dev/null | while IFS= read -r file; do
        # Skip if in blacklisted directory
        if is_blacklisted_dir "$file"; then
            echo "Skipping (blacklisted dir): $file" >&2
            ((skipped_count++))
            continue
        fi
        
        # Skip if blacklisted file
        if is_blacklisted_file "$file"; then
            echo "Skipping (blacklisted file): $file" >&2
            ((skipped_count++))
            continue
        fi
        
        # Skip if extension not allowed
        if ! is_allowed_extension "$file"; then
            echo "Skipping (extension): $file" >&2
            ((skipped_count++))
            continue
        fi
        
        # Process the file
        if [[ "$DRY_RUN" == true ]]; then
            process_file "$file"
        else
            process_file "$file" >> "$OUTPUT_FILE"
        fi
        
        ((processed_count++))
    done
    
    echo "" >&2
    echo "Export completed!" >&2
    echo "Files processed: $processed_count" >&2
    echo "Files skipped: $skipped_count" >&2
    
    if [[ "$DRY_RUN" == false ]] && [[ -f "$OUTPUT_FILE" ]]; then
        echo "Output file: $OUTPUT_FILE" >&2
        if command -v wc >/dev/null 2>&1; then
            local line_count=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
            echo "Lines in output: $line_count" >&2
        fi
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Simple Codebase Extractor"
            echo "Usage: $0 [-d|--dry-run] [-o|--output FILE]"
            echo "  -d, --dry-run    Show what would be processed"
            echo "  -o, --output     Output file (default: $OUTPUT_FILE)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

main

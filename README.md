# Codebase Extractor for the Shell

A powerful bash script that extracts and exports your entire codebase into a single text file, perfect for Large Language Model (LLM) analysis and code review. The script intelligently filters files, maintains folder structure, and creates a comprehensive overview of your project.

## Features

- **Smart File Filtering**: Automatically excludes binary files, build artifacts, and dependency folders
- **Configurable Output**: Customizable blacklists and file extension filters
- **Folder Structure Visualization**: Creates a clean tree view of your project structure
- **Selective Export**: Export entire directories or specific files/folders
- **Size Management**: Skips files larger than 1MB to prevent bloated outputs
- **Binary Detection**: Automatically detects and skips binary files
- **Web Development Focus**: Optimized for web server codebases with relevant file extensions

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/nkenan/codebaseExtractor/main/codebaseExtractor.sh
   ```

2. Make it executable:
   ```bash
   chmod +x codebaseExtractor.sh
   ```

3. Optionally, move to your PATH for global access:
   ```bash
   sudo mv codebaseExtractor.sh /usr/local/bin/codebaseExtractor
   ```

## Usage

### Basic Usage

Export entire current directory:
```bash
./codebaseExtractor.sh
```

### Advanced Usage

```bash
# Custom output file
./codebaseExtractor.sh -o my_project.txt

# Export specific directories
./codebaseExtractor.sh src/ docs/ config/

# Export specific files
./codebaseExtractor.sh index.php config.json README.md

# Mixed export (folders and files)
./codebaseExtractor.sh src/ README.md LICENSE
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help message |
| `-o`, `--output` | Specify output filename (default: `codebase_export.txt`) |

## Configuration

### Blacklisted Directories

The script automatically excludes common build and dependency directories:

- `node_modules`, `vendor`
- `.git`, `.svn`, `.hg`
- `dist`, `build`, `target`
- `__pycache__`, `.pytest_cache`
- `.vscode`, `.idea`
- `tmp`, `temp`, `cache`, `logs`
- `.next`, `.nuxt`
- `coverage`, `.nyc_output`
- `public/uploads`, `storage`
- `var/cache`, `var/log`

### Included File Extensions

**Web Development:**
- `php`, `html`, `htm`, `css`, `scss`, `sass`, `less`
- `js`, `jsx`, `ts`, `tsx`, `vue`, `svelte`

**Programming Languages:**
- `py`, `rb`, `java`, `c`, `cpp`, `cs`, `go`, `rs`

**Configuration & Data:**
- `json`, `xml`, `yaml`, `yml`, `toml`, `ini`, `conf`
- `sql`, `md`, `txt`, `.htaccess`, `.gitignore`

**Scripts & Templates:**
- `dockerfile`, `makefile`, `sh`, `bat`, `ps1`
- `twig`, `blade`, `smarty`, `handlebars`, `mustache`
- `asp`, `aspx`, `jsp`, `erb`, `ejs`, `pug`, `jade`

### Excluded File Extensions

Media and binary files are automatically excluded:
- Images: `jpg`, `jpeg`, `png`, `gif`, `bmp`, `svg`, `webp`, `ico`
- Videos: `mp4`, `avi`, `mov`, `wmv`, `flv`, `webm`, `mkv`
- Audio: `mp3`, `wav`, `ogg`, `flac`, `aac`, `wma`
- Documents: `pdf`, `doc`, `docx`, `xls`, `xlsx`, `ppt`, `pptx`
- Archives: `zip`, `rar`, `tar`, `gz`, `7z`, `bz2`
- Executables: `exe`, `dll`, `so`, `dylib`, `bin`
- Fonts: `ttf`, `otf`, `woff`, `woff2`, `eot`

## Output Format

The generated file contains:

1. **Header Section**: Export timestamp and directory information
2. **Folder Structure**: Tree-like visualization of your project structure
3. **File Contents**: Each file with clear delimiters and indented content

### Example Output Structure

```
CODEBASE EXPORT
Created on: Thu Jun 19 10:30:45 GMT 2025
Directory: /path/to/your/project

===============================================

=== FOLDER STRUCTURE ===

src/
  components/
  utils/
  styles/
docs/
config/

=== FILES ===

--- src/index.js BEGINNING ---
	// Your indented file content here
	console.log('Hello World');
--- src/index.js END ---

--- src/components/App.jsx BEGINNING ---
	// Component code here
--- src/components/App.jsx END ---
```

## Use Cases

- **LLM Code Analysis**: Feed your entire codebase to ChatGPT, Claude, or other LLMs
- **Code Reviews**: Create comprehensive code snapshots for review
- **Documentation**: Generate project overviews and architecture documentation
- **Backup**: Create human-readable backups of your codebase
- **Migration**: Prepare codebases for migration or refactoring projects

## File Size Management

- Files larger than 1MB are automatically skipped
- Binary files are detected and excluded
- Unreadable files are gracefully handled
- The script provides clear feedback about skipped files

## Compatibility

- **macOS**: Full support (uses `stat -f%z`)
- **Linux**: Full support (uses `stat -c%s`)
- **Windows**: Works with Git Bash, WSL, or Cygwin

## Customization

You can easily modify the script to suit your needs:

1. **Add file extensions**: Edit the `INCLUDE_EXTENSIONS` array
2. **Exclude directories**: Add to the `BLACKLIST_DIRS` array
3. **Change file size limit**: Modify the `MAX_FILE_SIZE` variable
4. **Custom file patterns**: Edit the `BLACKLIST_FILES` array

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest new features.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Examples

### Export a React Project
```bash
./codebaseExtractor.sh src/ public/ package.json README.md
```

### Export PHP Application
```bash
./codebaseExtractor.sh app/ config/ public/ composer.json
```

### Export with Custom Output
```bash
./codebaseExtractor.sh -o project_analysis.txt src/ docs/
```

---

**Perfect for developers who want to leverage AI for code analysis, documentation, and project understanding!**

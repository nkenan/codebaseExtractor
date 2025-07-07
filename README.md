# Codebase Extractor

A lightweight, dependency-free Bash script that extracts and consolidates your entire codebase into a single text file for analysis, documentation, or AI-powered code review.

## Features

- **Zero Dependencies**: Pure Bash script that works on any Unix-like system
- **Smart Filtering**: Automatically excludes common build artifacts, dependencies, and binary files
- **Flexible Target Selection**: Extract entire directories or specific files/folders
- **Size Protection**: Configurable file size limits to prevent memory issues
- **Metadata Support**: Optional file metadata inclusion (size, permissions, modification time)
- **Dry Run Mode**: Preview what would be extracted without creating files
- **Cross-Platform**: Works on Linux, macOS, and Windows (with WSL/Git Bash)
- **Highly Configurable**: Customizable blacklists and file type filters

## Installation

```bash
# Download the script
curl -O https://raw.githubusercontent.com/nkenan/codebase-extractor/main/codebase-extractor.sh

# Make it executable
chmod +x codebase-extractor.sh

# Optional: Add to PATH for global access
sudo mv codebase-extractor.sh /usr/local/bin/codebase-extractor
```

## Quick Start

```bash
# Extract entire current directory
./codebase-extractor.sh

# Extract specific folders
./codebase-extractor.sh src/ docs/ config/

# Extract with metadata and custom output file
./codebase-extractor.sh -m -o my-project.txt src/

# Dry run to see what would be extracted
./codebase-extractor.sh -d
```

## Usage

```
./codebase-extractor.sh [OPTIONS] [PATHS...]

OPTIONS:
  -h, --help       Show help message
  -o, --output     Output file (default: codebase_export.txt)
  -d, --dry-run    Preview extraction without creating file
  -m, --metadata   Include file metadata (size, permissions, dates)

PATHS:
  Without paths: Exports all files in the current directory
  With paths:    Exports only the specified files/folders
```

## Configuration

Create a `.codebase-extractor.conf` file in your project root to customize behavior:

```bash
# Custom output file
OUTPUT_FILE="my-custom-export.txt"

# Increase file size limit to 2MB
MAX_FILE_SIZE=2097152

# Add custom directories to blacklist
BLACKLIST_DIRS+=("my-custom-dir" "temp-files")

# Add custom file extensions to include
INCLUDE_EXTENSIONS+=("custom" "special")

# Add custom file patterns to exclude
BLACKLIST_FILES+=("*.backup" "*.orig")
```

## What Gets Extracted

### Included File Types
- **Web**: `php`, `html`, `css`, `js`, `jsx`, `ts`, `tsx`, `vue`, `svelte`
- **Backend**: `py`, `rb`, `java`, `c`, `cpp`, `cs`, `go`, `rs`
- **Config**: `json`, `xml`, `yaml`, `yml`, `toml`, `ini`, `conf`
- **Documentation**: `md`, `txt`, `rst`
- **Templates**: `twig`, `blade`, `handlebars`, `mustache`, `ejs`
- **Database**: `sql`, `graphql`, `gql`
- **DevOps**: `dockerfile`, `makefile`, `tf`, `.gitignore`, `.htaccess`

### Automatically Excluded
- **Dependencies**: `node_modules`, `vendor`, `__pycache__`
- **Build artifacts**: `dist`, `build`, `target`, `.next`
- **Version control**: `.git`, `.svn`, `.hg`
- **IDE files**: `.vscode`, `.idea`
- **Media files**: Images, videos, audio files
- **Archives**: `zip`, `tar`, `gz`, `rar`
- **Binaries**: `exe`, `dll`, `so`, `dylib`
- **Lock files**: `package-lock.json`, `yarn.lock`, `composer.lock`

## Output Format

The generated file includes:
1. **Header**: Timestamp, directory info, options used
2. **Folder Structure**: Tree view of directories
3. **File Contents**: Each file with clear delimiters

```
CODEBASE EXPORT
Created on: 2025-01-15 10:30:00
Directory: /path/to/project

=== FOLDER STRUCTURE ===
src/
  components/
  utils/
config/

=== FILES ===

--- src/main.js BEGINNING ---
[METADATA: Size: 2KB | Modified: 2025-01-15 09:15:00 | Permissions: -rw-r--r--]
    const app = {
        init() {
            console.log('App initialized');
        }
    };
--- src/main.js END ---
```

## Use Cases

### 🤖 AI Code Analysis
- **Code Review**: Feed entire codebase to AI tools like ChatGPT, Claude, or Copilot
- **Documentation Generation**: Automatically generate project documentation
- **Bug Detection**: Let AI scan for potential issues across your entire project
- **Refactoring Suggestions**: Get AI-powered recommendations for code improvements

### 📋 Project Documentation
- **Onboarding**: Create comprehensive code snapshots for new team members
- **Code Audits**: Prepare consolidated codebases for security or quality audits
- **Architecture Analysis**: Analyze project structure and dependencies
- **Legacy Code Documentation**: Document old codebases before migration

### 🔄 Migration & Backup
- **Platform Migration**: Easily move code between different hosting environments
- **Code Backup**: Create portable backups of your entire project
- **Version Snapshots**: Capture complete project state at specific points
- **Deployment Preparation**: Bundle code for deployment to restricted environments

### 🧪 Testing & Analysis
- **Static Analysis**: Prepare code for static analysis tools
- **Code Metrics**: Generate input for code complexity and quality tools
- **License Scanning**: Scan entire codebase for license compliance
- **Security Analysis**: Feed to security scanning tools

### 👥 Collaboration
- **Code Sharing**: Share entire projects without Git repositories
- **Remote Consultation**: Send complete codebases to consultants or freelancers
- **Code Training**: Create training materials from real projects
- **Interview Preparation**: Prepare code samples for technical interviews

## Perfect for Restricted Environments

This tool was specifically designed for **restricted managed web hosting servers** where you have limited access and capabilities:

### Why This Tool Exists
Many developers work on shared hosting platforms, corporate servers, or managed hosting environments where:
- **No Package Managers**: Can't install npm, pip, composer, or other dependency managers
- **Limited Shell Access**: Basic SSH with restricted commands
- **No Git Access**: Can't clone repositories or use version control
- **Firewall Restrictions**: Limited internet access for downloading tools
- **No Admin Rights**: Can't install system packages or dependencies

### How It Solves These Problems
- **Zero Dependencies**: Only requires Bash (available on virtually all Unix systems)
- **Single File**: Just one script file to upload via FTP/SFTP
- **No Installation**: Works immediately without setup
- **Portable**: Runs anywhere with basic shell access
- **Offline Capable**: Doesn't require internet connection after upload

### Real-World Scenarios
- **Shared Hosting**: Working on cPanel, DirectAdmin, or similar platforms
- **Corporate Servers**: Analyzing code on locked-down enterprise systems
- **Legacy Systems**: Extracting code from old servers with limited tools
- **Embedded Systems**: Working on IoT devices or embedded Linux systems
- **Restricted VPS**: Servers with minimal installed packages

This makes the tool invaluable for developers who need to work with codebases in constrained environments where modern development tools aren't available.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Additional file type support
- Performance improvements
- New configuration options
- Bug fixes
- Documentation improvements

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:
1. Check the [Issues](https://github.com/nkenan/codebase-extractor/issues) page
2. Create a new issue with detailed information
3. Include your system info and the exact command used

---

**Happy Coding!** 🚀

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a command-line Bible reader that allows users to read various Bible translations from the terminal with interactive navigation support. The project builds self-contained executable shell scripts that embed Bible text data and an AWK parsing engine.

## Core Architecture

### Data Format
- Bible text stored as TSV files in `data/` folder (e.g., `data/kjv.tsv`, `data/darby.tsv`, `data/chiuns.tsv`, `data/cuv.tsv`)
- Format: `Book Name\tAbbreviation\tBook Number\tChapter\tVerse\tText`
- Each line represents one verse with tab-separated fields
- Backup files stored as `*.tsv.backup`

### Build System
- **Primary build command**: `make kjv` (builds KJV version)
- **Navigation version**: `make kjv-nav` (builds KJV with interactive navigation)
- **Other versions**: `make darby`, `make chiuns`, `make cuv`
- Each build creates a self-contained executable that embeds:
  - Shell script wrapper (e.g., `kjv.sh`, `kjv-nav.sh`)
  - AWK parser (`kjv.awk` or `kjv-nav.awk`)
  - Bible text data from `data/` folder

### Executable Architecture
Each generated binary follows this pattern:
1. Shell script wrapper handles argument parsing and user interface
2. Embedded tarball contains AWK script and TSV data
3. `get_data()` function extracts embedded files using `sed` and `tar`
4. AWK engine (`kjv.awk`) handles reference parsing and text formatting

## Development Commands

### Building
```bash
# Build KJV version
make kjv

# Build KJV with interactive navigation
make kjv-nav

# Build other Bible versions
make darby
make chiuns
make cuv
```

### Testing
```bash
# Run shell script linting
make test
```

### Development Scripts
- Convert new Bible versions: Use R scripts in `scripts/` folder (`convert_*.R`) to transform other Bible formats
- Generate chapter summaries: `scripts/get_Bible_chapter_summary.R`
- Data processing and fixing: Various scripts in `scripts/` for data maintenance

## Code Organization

### Core Files
- `kjv.sh`, `darby.sh`, etc. - Shell script wrappers for each Bible version
- `kjv-nav.sh` - Enhanced shell script wrapper with interactive navigation
- `kjv.awk` - Shared AWK parser that handles all reference types and formatting
- `kjv-nav.awk` - Enhanced AWK parser with navigation support and bookinfo command
- `data/*.tsv` - Bible text data files organized in data folder
- `scripts/*.R` - R scripts for data conversion and processing
- `Makefile` - Build system that creates self-contained executables

### Reference Parsing
The AWK parser supports multiple reference formats:
- Individual books: `Genesis`
- Chapters: `Genesis:1`
- Verses: `Genesis:1:1` or `Genesis:1:1,3,5`
- Ranges: `Genesis:1-3`, `Genesis:1:1-5`, `Genesis:1:1-2:5`
- Search: `/word`, `Genesis/word`, `Genesis:1/word`

### Output Formatting
- Automatic line wrapping based on terminal width (disable with `-W`)
- Pager integration (uses `less` or `cat`)
- Interactive mode when run without arguments
- Navigation mode with keyboard controls for chapter/verse browsing

### Navigation Features (kjv-nav)
- **Interactive navigation**: Browse Bible with keyboard shortcuts
- **Reference formats**: Support both space-separated (`john 1`) and colon-separated (`John:1`) formats
- **Navigation controls**:
  - `n/p`: Next/Previous chapter with wraparound (Revelation → Genesis)
  - `N/P`: Next/Previous book
  - `j/k`: Next/Previous verse
  - `space/b`: Next/Previous page (within chapter)
  - `t`: Toggle between page view (10 verses) and single verse view
  - `g`: Go to specific reference
  - `q`: Quit navigation
  - `?`: Show help
- **Case-insensitive book matching**: "john" matches "John", "acts" matches "The Acts"
- **Page and single verse modes**: Flexible viewing options

### Project Structure
```
kjv/
├── data/              # Bible text data and backups
│   ├── kjv.tsv       # King James Version
│   ├── darby.tsv     # Darby Translation
│   ├── chiuns.tsv    # Chinese Union Simplified
│   ├── cuv.tsv       # Chinese Union Version
│   └── *.backup      # Backup files
├── scripts/           # Data processing and conversion tools
│   ├── convert_*.R   # R scripts for Bible format conversion
│   ├── fix_*.R       # Data fixing and processing scripts
│   └── *.sh          # Shell utility scripts
├── *.sh              # Shell script templates
├── *.awk             # AWK parsing engines
├── Makefile          # Build system
└── built executables # Generated self-contained binaries
```
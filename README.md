# kjv [![AUR](https://img.shields.io/badge/AUR-kjv--git-blue.svg)](https://aur.archlinux.org/packages/kjv-git/)

Read the Word of God from your terminal with navigation support

## Usage

### Basic Bible Reader

    usage: ./kjv [flags] [reference...]

      -l      list books
      -W      no line wrap
      -h      show help

### Interactive Navigation Mode

    usage: ./kjv-nav [flags] [reference...]

      -l      list books
      -W      no line wrap
      -n      navigation mode (interactive chapter navigation)
      -h      show help

    Navigation controls:
      n/p     Next/Previous chapter
      N/P     Next/Previous book
      j/k     Next/Previous verse
      space   Next page (within chapter)
      b       Previous page (within chapter)
      t       Toggle page/single view
      g       Go to specific reference
      q       Quit navigation
      ?       Show navigation help

### Reference Formats

    Space-separated: john 1, john 1 5, genesis 2 10
    Colon-separated: John:1, John:1:5, Genesis:2:10

    Reference types:
          <Book>
              Individual book
          <Book>:<Chapter>
              Individual chapter of a book
          <Book>:<Chapter>:<Verse>[,<Verse>]...
              Individual verse(s) of a specific chapter of a book
          <Book>:<Chapter>-<Chapter>
              Range of chapters in a book
          <Book>:<Chapter>:<Verse>-<Verse>
              Range of verses in a book chapter
          <Book>:<Chapter>:<Verse>-<Chapter>:<Verse>
              Range of chapters and verses in a book

          /<Search>
              All verses that match a pattern
          <Book>/<Search>
              All verses in a book that match a pattern
          <Book>:<Chapter>/<Search>
              All verses in a chapter of a book that match a pattern

## Build

kjv can be built by cloning the repository and then running make:

    git clone https://github.com/bontibon/kjv.git
    cd kjv

    # Build different Bible versions
    make kjv        # King James Version
    make kjv-nav    # KJV with interactive navigation
    make darby      # Darby Translation
    make chiuns     # Chinese Union Simplified
    make cuv        # Chinese Union Version

    # Optional: rename binaries for easier usage
    mv chiuns cus
    mv kjv-nav kjvnav
    
    # Install to PATH (e.g., ~/.local/bin/)
    cp kjv kjv-nav darby chiuns cuv ~/.local/bin/

## License

Public domain

## Features

- **Multiple Bible versions**: KJV, Darby, Chinese Union Simplified/Traditional
- **Interactive navigation**: Browse chapters and verses with keyboard shortcuts
- **Flexible reference formats**: Support both space-separated and colon-separated
- **Search functionality**: Find verses matching text patterns
- **Self-contained executables**: No external dependencies required
- **Terminal-friendly**: Automatic line wrapping and pager integration

## Project Structure

    kjv/
    ├── data/           # Bible text data (TSV files and backups)
    │   ├── kjv.tsv     # King James Version
    │   ├── darby.tsv   # Darby Translation
    │   ├── chiuns.tsv  # Chinese Union Simplified
    │   └── cuv.tsv     # Chinese Union Version
    ├── scripts/        # Data processing and conversion tools
    │   ├── convert_*.R # R scripts for Bible format conversion
    │   └── fix_*.R     # Data fixing and processing scripts
    ├── *.sh            # Shell script templates
    ├── *.awk           # AWK parsing engines
    └── Makefile        # Build system

## Development

### Data Format
Bible text stored as TSV files with tab-separated fields:
- Column 1: Book title (Genesis)
- Column 2: Abbreviated book title (Ge)
- Column 3: Book number (1 for Genesis)
- Column 4: Chapter number
- Column 5: Verse number
- Column 6: Verse text

### Converting Bible Versions
Use the R scripts in `scripts/` folder or diatheke (SWORD project):

    # Using diatheke
    diatheke -b Darby -o M -k <reference>
    
    # Using R conversion scripts
    Rscript scripts/convert_darby.R

### Testing
    make test    # Run shellcheck on shell scripts


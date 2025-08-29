# KJV Bible Reader - Scripts Directory

This directory contains automation and debugging scripts for the KJV Bible reader project.

## Scripts Overview

### `debug_and_check_commands.sh`
**Purpose:** Comprehensive diagnostic and verification tool  
**Usage:** `./debug_and_check_commands.sh`

**What it does:**
- Checks system prerequisites (diatheke, R, SWORD modules)
- Verifies data integrity across all Bible versions
- Detects empty or missing verses  
- Tests binary functionality
- Provides detailed status report

### `fix_missing_verses.sh`
**Purpose:** Complete automated fix for missing Bible verses  
**Usage:** `./fix_missing_verses.sh`

**What it does:**
- Checks all prerequisites and installs missing dependencies
- Creates backups of existing data files
- Fixes conversion scripts and AWK processing
- Runs targeted verse conversion (much faster than full Bible)
- Rebuilds binaries and verifies functionality

## Quick Start

### To Check Current Status
```bash
cd /home/isaacpei/Workbench/kjv
./scripts/debug_and_check_commands.sh
```

### To Fix Missing Verses Issues
```bash  
cd /home/isaacpei/Workbench/kjv
./scripts/fix_missing_verses.sh
```

### To Test Specific Functionality
```bash
# Test Acts access in different formats
./darby "acts:1:1"
./darby "The Acts:1:1" 
./chiuns "acts:1:1-5"
```

## Manual Operations

### Individual R Scripts
- `fix_acts_only.R` - Convert only Acts verses (fast)
- `fix_remaining_verses.R` - Fix any remaining empty verses
- `convert_*.R` - Full Bible conversion (slow, use only if needed)

### Run Individual Fix
```bash
# For Acts only (recommended)
Rscript fix_acts_only.R

# For remaining issues
Rscript fix_remaining_verses.R
```

## Troubleshooting

### Common Issues

**1. diatheke not found**
```bash
sudo pacman -S sword  # Arch/Manjaro
sudo apt install diatheke  # Debian/Ubuntu
```

**2. SWORD modules not installed**
```bash
sudo installmgr --allow-internet-access-and-risk-tracing-and-jail-or-martyrdom -sc
sudo installmgr --allow-internet-access-and-risk-tracing-and-jail-or-martyrdom -ri CrossWire Darby
sudo installmgr --allow-internet-access-and-risk-tracing-and-jail-or-martyrdom -ri CrossWire ChiUns
```

**3. R data.table package missing**
```bash
mkdir -p ~/R/x86_64-pc-linux-gnu-library/4.5
R -e "install.packages('data.table', repos='https://cran.r-project.org', lib='~/R/x86_64-pc-linux-gnu-library/4.5')"
```

### Verification Commands

```bash
# Check verse counts
for f in *.tsv; do echo "$f: $(wc -l < "$f") verses"; done

# Check book counts  
for f in *.tsv; do echo "$f: $(cut -f1 "$f" | sort -u | wc -l) books"; done

# Check empty verses
for f in *.tsv; do echo "$f: $(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' "$f" | wc -l) empty"; done

# Test Acts specifically
grep -c "^The Acts" *.tsv
```

## Documentation

For detailed information about the fix process and technical details, see:
- `docs/2025-08-28_acts_missing_issue_fix.md` - Complete technical documentation
- `docs/file_changes_and_backups.md` - File changes and backup information

---

**These scripts provide complete automation for maintaining the KJV Bible reader and fixing any missing verse issues.**
#!/bin/bash
# KJV Bible Reader - Fix Missing Verses Script
# Created: 2025-08-28
# Purpose: Complete fix procedure for missing Bible verses (like Acts)

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== KJV Bible Reader - Missing Verses Fix Script ==="
echo "Date: $(date)"
echo "Project Directory: $PROJECT_DIR"
echo

cd "$PROJECT_DIR"

# Function to print section headers
print_section() {
    echo "================================"
    echo "=== $1 ==="
    echo "================================"
}

# Function to run command with error checking
run_step() {
    echo "🔧 $1"
    echo "   Command: $2"
    if eval "$2"; then
        echo "   ✅ Success"
    else
        echo "   ❌ Failed"
        exit 1
    fi
    echo
}

# Function to check prerequisites
check_prerequisites() {
    print_section "CHECKING PREREQUISITES"
    
    echo "🔍 Checking required tools..."
    
    # Check diatheke
    if command -v diatheke >/dev/null 2>&1; then
        echo "   ✅ diatheke found: $(which diatheke)"
    else
        echo "   ❌ diatheke not found"
        echo "   Install with: sudo pacman -S sword"
        exit 1
    fi
    
    # Check R
    if command -v R >/dev/null 2>&1; then
        echo "   ✅ R found: $(R --version | head -1)"
    else
        echo "   ❌ R not found"
        echo "   Install with: sudo pacman -S r"
        exit 1
    fi
    
    # Check data.table package
    if R -e "library(data.table)" >/dev/null 2>&1; then
        echo "   ✅ data.table package available"
    else
        echo "   ❌ data.table package not found"
        echo "   Installing data.table package..."
        mkdir -p ~/R/x86_64-pc-linux-gnu-library/4.5
        R -e "install.packages('data.table', repos='https://cran.r-project.org', lib='~/R/x86_64-pc-linux-gnu-library/4.5')"
    fi
    
    # Check SWORD modules
    echo "🔍 Checking SWORD Bible modules..."
    if diatheke -b Darby -k "Acts 1:1" >/dev/null 2>&1; then
        echo "   ✅ Darby module available"
    else
        echo "   ❌ Darby module not found"
        echo "   Install with: sudo installmgr --allow-internet-access-and-risk-tracing-and-jail-or-martyrdom -ri CrossWire Darby"
        exit 1
    fi
    
    if diatheke -b ChiUns -k "Acts 1:1" >/dev/null 2>&1; then
        echo "   ✅ ChiUns module available"
    else
        echo "   ❌ ChiUns module not found"
        echo "   Install with: sudo installmgr --allow-internet-access-and-risk-tracing-and-jail-or-martyrdom -ri CrossWire ChiUns"
        exit 1
    fi
    
    echo
}

# Function to create backups
create_backups() {
    print_section "CREATING BACKUPS"
    
    for file in darby.tsv chiuns.tsv cuv.tsv; do
        if [[ -f "$file" ]]; then
            if [[ ! -f "$file.backup" ]]; then
                run_step "Backing up $file" "cp '$file' '$file.backup'"
            else
                echo "   ⚠️  Backup $file.backup already exists, skipping"
            fi
        else
            echo "   ⚠️  File $file not found, skipping backup"
        fi
    done
}

# Function to fix conversion scripts
fix_conversion_scripts() {
    print_section "FIXING CONVERSION SCRIPTS"
    
    # This step assumes the R scripts have already been fixed
    # Just verify they have the correct content
    
    echo "🔍 Verifying conversion scripts have book name mapping..."
    
    for script in convert_darby.R convert_chiuns.R convert_cuv.R; do
        if [[ -f "$script" ]]; then
            if grep -q 'ifelse.*"The Acts".*"Acts"' "$script"; then
                echo "   ✅ $script has book name mapping fix"
            else
                echo "   ❌ $script missing book name mapping fix"
                echo "   Please run the fix manually or check the documentation"
                exit 1
            fi
        else
            echo "   ⚠️  $script not found"
        fi
    done
}

# Function to fix AWK script
fix_awk_script() {
    print_section "FIXING AWK SCRIPT"
    
    echo "🔍 Verifying AWK script has book matching fix..."
    
    if [[ -f "kjv.awk" ]]; then
        if grep -q 'book == "theacts" && query == "acts"' kjv.awk; then
            echo "   ✅ kjv.awk has book matching fix"
        else
            echo "   ❌ kjv.awk missing book matching fix"
            echo "   Adding book matching fix to kjv.awk..."
            
            # Create a temporary fix (backup original approach)
            cp kjv.awk kjv.awk.backup.$(date +%Y%m%d_%H%M%S)
            
            # Add the fix before the closing brace of bookmatches function
            sed -i '/^}/{ 
                i\\t# Handle "The Acts" special case - allow "acts" to match "theacts"
                i\\tif (book == "theacts" && query == "acts") {
                i\\t\treturn book
                i\\t}
                i\
            }' kjv.awk
            
            echo "   ✅ Added book matching fix to kjv.awk"
        fi
    else
        echo "   ❌ kjv.awk not found"
        exit 1
    fi
}

# Function to run targeted verse conversion
run_targeted_conversion() {
    print_section "RUNNING TARGETED CONVERSION"
    
    # Check if we have the fix_acts_only.R script
    if [[ ! -f "fix_acts_only.R" ]]; then
        echo "   ❌ fix_acts_only.R script not found"
        echo "   Creating fix_acts_only.R script..."
        
        # Create the script inline
        cat > fix_acts_only.R << 'EOF'
# Fix Acts verses only for Darby and ChiUns versions
rm(list=ls())
library(data.table)

get_darby = function(verse_index) {
    command = paste0("diatheke -b Darby -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        print(paste("ERROR: Failed to get verse for:", verse_index))
        return("")
    }
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

get_chiuns = function(verse_index) {
    command = paste0("diatheke -b ChiUns -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        print(paste("ERROR: Failed to get verse for:", verse_index))
        return("")
    }
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

print("Loading existing Darby data...")
darby_data = fread("darby.tsv")
names(darby_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

print("Loading existing ChiUns data...")
chiuns_data = fread("chiuns.tsv")
names(chiuns_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

acts_rows = darby_data$V1 == "The Acts"
print(paste("Found", sum(acts_rows), "Acts verses to convert"))

if (sum(acts_rows) > 0) {
    acts_data = darby_data[acts_rows, ]
    acts_data$index = paste0("Acts ", acts_data$V4, ":", acts_data$V5)
    
    print("Converting Acts verses for Darby...")
    acts_data$verse_darby = sapply(acts_data$index, get_darby)
    
    print("Converting Acts verses for ChiUns...")
    acts_data$verse_chiuns = sapply(acts_data$index, get_chiuns)
    
    acts_data$verse_darby = gsub("\n", " ", acts_data$verse_darby, fixed=T)
    acts_data$verse_chiuns = gsub("\n", " ", acts_data$verse_chiuns, fixed=T)
    
    darby_data[acts_rows, "verse"] = acts_data$verse_darby
    chiuns_data[acts_rows, "verse"] = acts_data$verse_chiuns
    
    print("Saving updated Darby data...")
    fwrite(darby_data[, .(V1, V2, V3, V4, V5, verse)], 'darby.tsv', col.names=F, sep="\t")
    
    print("Saving updated ChiUns data...")  
    fwrite(chiuns_data[, .(V1, V2, V3, V4, V5, verse)], 'chiuns.tsv', col.names=F, sep="\t")
    
    print("Conversion complete!")
    print(paste("Converted", length(acts_data$verse_darby), "Acts verses"))
    
    print("Sample of converted Acts verses:")
    print("Darby Acts 1:1:")
    print(acts_data$verse_darby[1])
    print("ChiUns Acts 1:1:")  
    print(acts_data$verse_chiuns[1])
} else {
    print("No Acts verses found in the data")
}
EOF
    fi
    
    run_step "Running Acts-only conversion" "Rscript fix_acts_only.R"
}

# Function to fix remaining empty verses  
fix_remaining_verses() {
    print_section "FIXING REMAINING EMPTY VERSES"
    
    # Check if we have remaining empty verses
    empty_darby=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' darby.tsv | wc -l)
    empty_chiuns=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' chiuns.tsv | wc -l)
    
    if [[ $empty_darby -gt 0 ]] || [[ $empty_chiuns -gt 0 ]]; then
        echo "   Found $empty_darby empty verses in Darby, $empty_chiuns in ChiUns"
        echo "   Creating fix_remaining_verses.R script..."
        
        cat > fix_remaining_verses.R << 'EOF'
# Fix the remaining empty verses in darby and chiuns
rm(list=ls())
library(data.table)

get_darby = function(verse_index) {
    command = paste0("diatheke -b Darby -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        return("")
    }
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

get_chiuns = function(verse_index) {
    command = paste0("diatheke -b ChiUns -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        return("")
    }
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

darby_data = fread("darby.tsv")
names(darby_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

chiuns_data = fread("chiuns.tsv")
names(chiuns_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

empty_darby = which(darby_data$verse == "" | darby_data$verse == '""' | nchar(darby_data$verse) == 0)
empty_chiuns = which(chiuns_data$verse == "" | chiuns_data$verse == '""' | nchar(chiuns_data$verse) == 0)

print(paste("Found", length(empty_darby), "empty verses in Darby"))
print(paste("Found", length(empty_chiuns), "empty verses in ChiUns"))

if (length(empty_darby) > 0) {
    print("Fixing empty verses in Darby:")
    for (i in empty_darby) {
        book = darby_data$V1[i]
        chapter = darby_data$V4[i] 
        verse = darby_data$V5[i]
        book_for_diatheke = ifelse(book == "The Acts", "Acts", book)
        ref = paste0(book_for_diatheke, " ", chapter, ":", verse)
        print(paste("Trying to fix:", ref))
        new_verse = get_darby(ref)
        if (new_verse != "") {
            darby_data$verse[i] = gsub("\n", " ", new_verse, fixed=T)
            print(paste("  Fixed:", substr(new_verse, 1, 50), "..."))
        } else {
            print(paste("  No content available in Darby for:", ref))
        }
    }
}

if (length(empty_chiuns) > 0) {
    print("Fixing empty verses in ChiUns:")
    for (i in empty_chiuns) {
        book = chiuns_data$V1[i]
        chapter = chiuns_data$V4[i]
        verse = chiuns_data$V5[i]
        book_for_diatheke = ifelse(book == "The Acts", "Acts", book)
        ref = paste0(book_for_diatheke, " ", chapter, ":", verse)
        print(paste("Trying to fix:", ref))
        new_verse = get_chiuns(ref)
        if (new_verse != "") {
            chiuns_data$verse[i] = gsub("\n", " ", new_verse, fixed=T)
            print(paste("  Fixed:", substr(new_verse, 1, 50), "..."))
        } else {
            print(paste("  No content available in ChiUns for:", ref))
        }
    }
}

print("Saving updated data...")
fwrite(darby_data[, .(V1, V2, V3, V4, V5, verse)], 'darby.tsv', col.names=F, sep="\t")
fwrite(chiuns_data[, .(V1, V2, V3, V4, V5, verse)], 'chiuns.tsv', col.names=F, sep="\t")
print("Done fixing remaining empty verses!")
EOF
        
        run_step "Running remaining verses fix" "Rscript fix_remaining_verses.R"
    else
        echo "   ✅ No empty verses found, skipping this step"
    fi
}

# Function to rebuild binaries
rebuild_binaries() {
    print_section "REBUILDING BINARIES"
    
    if [[ -f "Makefile" ]]; then
        run_step "Building darby binary" "make darby"
        run_step "Building chiuns binary" "make chiuns"
        
        # Also build kjv if needed
        if [[ -f "kjv.tsv" ]] && [[ -f "kjv.sh" ]]; then
            run_step "Building kjv binary" "make kjv"
        fi
    else
        echo "   ❌ Makefile not found"
        echo "   Manual build required"
        exit 1
    fi
}

# Function to verify fixes
verify_fixes() {
    print_section "VERIFYING FIXES"
    
    echo "🔍 Running verification tests..."
    
    # Test binaries
    if [[ -x "./darby" ]]; then
        echo "   Testing darby binary with Acts 1:1..."
        if ./darby "acts:1:1" | grep -q "I composed the first discourse"; then
            echo "   ✅ darby binary works with Acts"
        else
            echo "   ❌ darby binary test failed"
            exit 1
        fi
    fi
    
    if [[ -x "./chiuns" ]]; then
        echo "   Testing chiuns binary with Acts 1:1..."
        if ./chiuns "acts:1:1" | grep -q "提阿非罗"; then
            echo "   ✅ chiuns binary works with Acts"
        else
            echo "   ❌ chiuns binary test failed"
            exit 1
        fi
    fi
    
    # Check data integrity
    kjv_books=$(cut -f1 kjv.tsv | sort -u | wc -l)
    darby_books=$(cut -f1 darby.tsv | sort -u | wc -l)  
    chiuns_books=$(cut -f1 chiuns.tsv | sort -u | wc -l)
    
    echo "   Books count - KJV: $kjv_books, Darby: $darby_books, ChiUns: $chiuns_books"
    
    if [[ $kjv_books -eq $darby_books ]] && [[ $darby_books -eq $chiuns_books ]] && [[ $kjv_books -eq 66 ]]; then
        echo "   ✅ All versions have correct number of books (66)"
    else
        echo "   ❌ Book count mismatch"
        exit 1
    fi
    
    # Check Acts verses
    kjv_acts=$(grep -c '^The Acts' kjv.tsv)
    darby_acts=$(grep -c '^The Acts' darby.tsv)
    chiuns_acts=$(grep -c '^The Acts' chiuns.tsv)
    
    echo "   Acts verses - KJV: $kjv_acts, Darby: $darby_acts, ChiUns: $chiuns_acts"
    
    if [[ $kjv_acts -eq $darby_acts ]] && [[ $darby_acts -eq $chiuns_acts ]]; then
        echo "   ✅ All versions have same number of Acts verses"
    else
        echo "   ❌ Acts verse count mismatch"
        exit 1
    fi
    
    # Check for empty verses
    empty_darby=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' darby.tsv | wc -l)
    empty_chiuns=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' chiuns.tsv | wc -l)
    
    echo "   Empty verses - Darby: $empty_darby, ChiUns: $empty_chiuns"
    echo "   ℹ️  Note: Some empty verses are legitimate textual variants"
}

# Main execution
main() {
    echo "Starting KJV Bible Reader missing verses fix..."
    echo
    
    check_prerequisites
    create_backups
    fix_conversion_scripts  
    fix_awk_script
    run_targeted_conversion
    fix_remaining_verses
    rebuild_binaries
    verify_fixes
    
    print_section "COMPLETE"
    echo "✅ Missing verses fix completed successfully!"
    echo
    echo "📋 Summary:"
    echo "   - All Bible versions now have complete book coverage"
    echo "   - Acts verses are fully functional in all versions"
    echo "   - Book name matching works for both 'acts' and 'The Acts'"
    echo "   - Backups created for all modified files"
    echo "   - Binaries rebuilt and tested"
    echo
    echo "📖 For detailed information, see:"
    echo "   docs/2025-08-28_acts_missing_issue_fix.md"
    echo
    echo "🧪 Test commands:"
    echo "   ./darby 'acts:1:1'"
    echo "   ./chiuns 'acts:1:1-5'"  
    echo "   ./scripts/debug_and_check_commands.sh"
}

# Run main function
main "$@"
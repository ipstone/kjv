#!/bin/bash
# KJV Bible Reader - Debug and Check Commands
# Created: 2025-08-28
# Purpose: All debugging, checking, and verification commands used during Acts missing issue fix

set -e  # Exit on error

echo "=== KJV Bible Reader - Debug and Check Commands ==="
echo "Date: $(date)"
echo

# Function to print section headers
print_section() {
    echo "================================"
    echo "=== $1 ==="
    echo "================================"
}

# Function to run command with description
run_check() {
    echo "🔍 $1"
    echo "   Command: $2"
    eval "$2"
    echo
}

print_section "1. BASIC SYSTEM CHECKS"

run_check "Check if diatheke is installed" "which diatheke || echo 'diatheke not found'"

run_check "Check diatheke version" "diatheke --help 2>&1 | head -3 || echo 'Cannot get diatheke version'"

run_check "List currently installed SWORD modules" "diatheke -b system -k modulelist || echo 'No modules found'"

print_section "2. BIBLE DATA INTEGRITY CHECKS"

run_check "Count books in KJV" "cut -f1 kjv.tsv | sort -u | wc -l"

run_check "Count books in Darby" "cut -f1 darby.tsv | sort -u | wc -l"

run_check "Count books in ChiUns" "cut -f1 chiuns.tsv | sort -u | wc -l"

run_check "Compare book lists (KJV vs Darby)" "diff <(cut -f1 kjv.tsv | sort -u) <(cut -f1 darby.tsv | sort -u) || echo 'Books match'"

run_check "Compare book lists (KJV vs ChiUns)" "diff <(cut -f1 kjv.tsv | sort -u) <(cut -f1 chiuns.tsv | sort -u) || echo 'Books match'"

print_section "3. EMPTY VERSE DETECTION"

run_check "Count empty verses in KJV" "awk -F'\t' '\$6 == \"\" || \$6 == \"\\\"\\\"\" || length(\$6) == 0' kjv.tsv | wc -l"

run_check "Count empty verses in Darby" "awk -F'\t' '\$6 == \"\" || \$6 == \"\\\"\\\"\" || length(\$6) == 0' darby.tsv | wc -l"

run_check "Count empty verses in ChiUns" "awk -F'\t' '\$6 == \"\" || \$6 == \"\\\"\\\"\" || length(\$6) == 0' chiuns.tsv | wc -l"

run_check "Identify empty verses in Darby" "awk -F'\t' '\$6 == \"\" || \$6 == \"\\\"\\\"\" || length(\$6) == 0 {print \$1\":\" \$4\":\" \$5}' darby.tsv"

run_check "Identify empty verses in ChiUns" "awk -F'\t' '\$6 == \"\" || \$6 == \"\\\"\\\"\" || length(\$6) == 0 {print \$1\":\" \$4\":\" \$5}' chiuns.tsv"

print_section "4. ACTS SPECIFIC CHECKS"

run_check "Count Acts verses in KJV" "grep -c '^The Acts' kjv.tsv || echo '0'"

run_check "Count Acts verses in Darby" "grep -c '^The Acts' darby.tsv || echo '0'"

run_check "Count Acts verses in ChiUns" "grep -c '^The Acts' chiuns.tsv || echo '0'"

run_check "Sample Acts verses from KJV (first 3)" "grep '^The Acts' kjv.tsv | head -3"

run_check "Sample Acts verses from Darby (first 3)" "grep '^The Acts' darby.tsv | head -3"

run_check "Sample Acts verses from ChiUns (first 3)" "grep '^The Acts' chiuns.tsv | head -3"

print_section "5. DIATHEKE FUNCTIONALITY TESTS"

if command -v diatheke >/dev/null 2>&1; then
    run_check "Test Darby module with Acts 1:1" "diatheke -b Darby -k 'Acts 1:1' || echo 'Darby module test failed'"
    
    run_check "Test ChiUns module with Acts 1:1" "diatheke -b ChiUns -k 'Acts 1:1' || echo 'ChiUns module test failed'"
    
    run_check "Test textual variant - Matthew 23:14 in Darby" "diatheke -b Darby -k 'Matthew 23:14' || echo 'Matthew 23:14 not available in Darby'"
    
    run_check "Test textual variant - Luke 1:2 in ChiUns" "diatheke -b ChiUns -k 'Luke 1:2' || echo 'Luke 1:2 not available in ChiUns'"
else
    echo "⚠️  diatheke not available - skipping functionality tests"
fi

print_section "6. BINARY FUNCTIONALITY TESTS"

if [[ -x "./kjv" ]]; then
    run_check "Test KJV binary with Acts 1:1" "./kjv 'The Acts:1:1'"
else
    echo "⚠️  kjv binary not found"
fi

if [[ -x "./darby" ]]; then
    run_check "Test Darby binary with Acts 1:1" "./darby 'acts:1:1'"
    run_check "Test Darby binary with The Acts format" "./darby 'The Acts:1:1'"
else
    echo "⚠️  darby binary not found"
fi

if [[ -x "./chiuns" ]]; then
    run_check "Test ChiUns binary with Acts 1:1" "./chiuns 'acts:1:1'"
    run_check "Test ChiUns binary range query" "./chiuns 'acts:1:1-3'"
else
    echo "⚠️  chiuns binary not found"
fi

print_section "7. R ENVIRONMENT CHECKS"

run_check "Check R installation" "R --version | head -1 || echo 'R not installed'"

run_check "Check data.table package" "R -e 'library(data.table); cat(\"data.table package is available\\n\")' || echo 'data.table package not available'"

print_section "8. FILE BACKUP VERIFICATION"

run_check "Check for backup files" "ls -la *.backup 2>/dev/null || echo 'No backup files found'"

run_check "Verify backup file sizes" "for f in *.backup; do [[ -f \$f ]] && echo \"\$f: \$(wc -l < \"\$f\") lines\" || true; done"

print_section "9. BUILD SYSTEM CHECKS"

run_check "Test Makefile targets" "make -n kjv darby chiuns 2>/dev/null || echo 'Makefile test failed'"

run_check "Check if binaries are newer than source files" "for bin in kjv darby chiuns; do [[ -f \$bin ]] && echo \"\$bin: \$(stat -c '%Y' \$bin)\" || echo \"\$bin: not found\"; done"

print_section "SUMMARY"

echo "✅ Debug and check commands completed"
echo "📊 Check results summary:"
echo "   - Books in each version: KJV=$(cut -f1 kjv.tsv | sort -u | wc -l), Darby=$(cut -f1 darby.tsv | sort -u | wc -l), ChiUns=$(cut -f1 chiuns.tsv | sort -u | wc -l)"
echo "   - Empty verses: Darby=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' darby.tsv | wc -l), ChiUns=$(awk -F'\t' '$6 == "" || $6 == "\"\"" || length($6) == 0' chiuns.tsv | wc -l)"
echo "   - Acts verses: KJV=$(grep -c '^The Acts' kjv.tsv 2>/dev/null || echo 0), Darby=$(grep -c '^The Acts' darby.tsv 2>/dev/null || echo 0), ChiUns=$(grep -c '^The Acts' chiuns.tsv 2>/dev/null || echo 0)"

echo
echo "For detailed analysis, see: docs/2025-08-28_acts_missing_issue_fix.md"
#!/bin/sh
# kjv-nav: Read the Word of God from your terminal with navigation
# License: Public domain

SELF="$0"

get_data() {
	sed '1,/^#EOF$/d' < "$SELF" | tar xz -O "$1"
}

if [ -z "$PAGER" ]; then
	if command -v less >/dev/null; then
		PAGER="less"
	else
		PAGER="cat"
	fi
fi

show_help() {
	exec >&2
	echo "usage: $(basename "$0") [flags] [reference...]"
	echo
	echo "  -l      list books"
	echo "  -W      no line wrap"
	echo "  -n      navigation mode (interactive chapter navigation)"
	echo "  -h      show help"
	echo
	echo "  Reference formats:"
	echo "      Space-separated: john 1, john 1 5, genesis 2 10"
	echo "      Colon-separated: John:1, John:1:5, Genesis:2:10"
	echo
	echo "  Reference types:"
	echo "      <Book>"
	echo "          Individual book"
	echo "      <Book> <Chapter> | <Book>:<Chapter>"
	echo "          Individual chapter of a book"
	echo "      <Book> <Chapter> <Verse> | <Book>:<Chapter>:<Verse>"
	echo "          Individual verse of a specific chapter"
	echo "      <Book>:<Chapter>:<Verse>[,<Verse>]..."
	echo "          Individual verse(s) of a specific chapter of a book"
	echo "      <Book>:<Chapter>-<Chapter>"
	echo "          Range of chapters in a book"
	echo "      <Book>:<Chapter>:<Verse>-<Verse>"
	echo "          Range of verses in a book chapter"
	echo "      <Book>:<Chapter>:<Verse>-<Chapter>:<Verse>"
	echo "          Range of chapters and verses in a book"
	echo
	echo "      /<Search>"
	echo "          All verses that match a pattern"
	echo "      <Book>/<Search>"
	echo "          All verses in a book that match a pattern"
	echo "      <Book>:<Chapter>/<Search>"
	echo "          All verses in a chapter of a book that match a pattern"
	echo
	echo "  Navigation mode controls:"
	echo "      n/p     Next/Previous chapter"
	echo "      N/P     Next/Previous book"
	echo "      j/k     Next/Previous verse"
	echo "      space   Next page (within chapter)"
	echo "      b       Previous page (within chapter)"
	echo "      t       Toggle page/single view"
	echo "      g       Go to specific reference"
	echo "      q       Quit navigation"
	echo "      ?       Show navigation help"
	exit 2
}

# Simple navigation using direct AWK queries instead of complex shell functions
get_verse_count() {
	local book="$1"
	local chapter="$2"
	get_data kjv.tsv | awk -F'\t' -v book="$book" -v chapter="$chapter" 'tolower($1) == tolower(book) && $4 == chapter { max_verse = ($5 > max_verse) ? $5 : max_verse } END { print max_verse }'
}

get_chapter_count() {
	local book="$1"
	get_data kjv.tsv | awk -F'\t' -v book="$book" 'tolower($1) == tolower(book) { max_chapter = ($4 > max_chapter) ? $4 : max_chapter } END { print max_chapter }'
}

get_next_book() {
	local current_book="$1"
	get_data kjv.tsv | awk -F'\t' -v current_book="$current_book" '
	!seen[$1] { 
		books[++book_count] = $1; 
		book_num[$1] = $3; 
		seen[$1] = 1 
	}
	END {
		for (i = 1; i <= book_count; i++) {
			if (tolower(books[i]) == tolower(current_book)) {
				next_idx = i + 1
				if (next_idx > book_count) next_idx = 1
				print books[next_idx]
				exit
			}
		}
	}'
}

get_prev_book() {
	local current_book="$1"
	get_data kjv.tsv | awk -F'\t' -v current_book="$current_book" '
	!seen[$1] { 
		books[++book_count] = $1; 
		book_num[$1] = $3; 
		seen[$1] = 1 
	}
	END {
		for (i = 1; i <= book_count; i++) {
			if (tolower(books[i]) == tolower(current_book)) {
				prev_idx = i - 1
				if (prev_idx < 1) prev_idx = book_count
				print books[prev_idx]
				exit
			}
		}
	}'
}

parse_arguments() {
	# Convert space-separated arguments to colon format
	# Examples: "john 1" -> "john:1", "john 1 5" -> "john:1:5"
	local args="$*"
	
	# If it already contains colons, assume it's in correct format
	if echo "$args" | grep -q ":"; then
		echo "$args"
		return
	fi
	
	# Split on spaces and join with colons
	echo "$args" | awk '{
		result = $1
		for(i = 2; i <= NF; i++) {
			if($i ~ /^[0-9]+$/) {
				result = result ":" $i
			} else {
				result = result " " $i
			}
		}
		print result
	}'
}

parse_current_reference() {
	# Extract book, chapter, and verse from a reference like "Genesis:1" or "John:3:16"
	echo "$1" | sed 's/^\([^:]*\):\?\([0-9]*\):\?\([0-9]*\).*/\1|\2|\3/'
}

get_verses_for_page() {
	local book="$1"
	local chapter="$2" 
	local start_verse="$3"
	local page_size="$4"
	
	local end_verse=$((start_verse + page_size - 1))
	local verse_range="${start_verse}-${end_verse}"
	get_data kjv.tsv | awk -v cmd=ref -v ref="${book}:${chapter}:${verse_range}" "$(get_data kjv-nav.awk)"
}

navigation_mode() {
	local current_ref="${1:-Genesis:1:1}"
	local page_size=10
	local display_start_verse=1
	local view_mode="page"  # "page" or "single"
	
	# Normalize reference to include verse if missing
	if ! echo "$current_ref" | grep -q ".*:.*:.*"; then
		current_ref="${current_ref}:1"
	fi
	
	# Variables for the navigation loop
	local ref_parts book chapter verse
	local chapter_count verse_count next_book prev_book 
	local prev_chapters prev_verse_count
	local next_start prev_start
	
	while true; do
		# Parse current reference
		ref_parts=$(parse_current_reference "$current_ref")
		book=$(echo "$ref_parts" | cut -d'|' -f1)
		chapter=$(echo "$ref_parts" | cut -d'|' -f2)
		verse=$(echo "$ref_parts" | cut -d'|' -f3)
		chapter=${chapter:-1}
		verse=${verse:-1}
		
		# Calculate display range for paging
		if [ "$view_mode" = "page" ]; then
			# For page mode, use verse to calculate which page to show
			display_start_verse=$(( ((verse - 1) / page_size) * page_size + 1 ))
		else
			display_start_verse=$verse
		fi
		
		# Display current content
		clear
		if [ "$view_mode" = "page" ]; then
			echo "=== Navigation Mode - ${book}:${chapter} (verses ${display_start_verse}-$((display_start_verse + page_size - 1))) ==="
		else
			echo "=== Navigation Mode - ${book}:${chapter}:${verse} ==="
		fi
		echo "Controls: [n/p]ch [N/P]book [j/k]verse [space/b]page [t]oggle [g]o [q]uit [?]help"
		echo "============================================================================="
		echo
		
		if [ "$view_mode" = "page" ]; then
			get_verses_for_page "$book" "$chapter" "$display_start_verse" "$page_size"
		else
			get_data kjv.tsv | awk -v cmd=ref -v ref="${book}:${chapter}:${verse}" "$(get_data kjv-nav.awk)"
		fi
		
		echo
		if [ "$view_mode" = "page" ]; then
			printf "kjv-nav (%s:page)> " "${book}:${chapter}"
		else
			printf "kjv-nav (%s:single)> " "${book}:${chapter}:${verse}"
		fi
		
		# Read single character input
		if command -v stty >/dev/null 2>&1; then
			old_stty=$(stty -g)
			stty -echo -icanon min 1 time 0
			key=$(dd bs=1 count=1 2>/dev/null)
			stty "$old_stty"
		else
			read -r key
		fi
		
		case "$key" in
			n)
				# Next chapter
				chapter_count=$(get_chapter_count "$book")
				if [ "$chapter" -lt "$chapter_count" ]; then
					current_ref="${book}:$((chapter + 1))"
				else
					# Move to next book, chapter 1
					next_book=$(get_next_book "$book")
					current_ref="${next_book}:1"
				fi
				view_mode="page"
				;;
			p)
				# Previous chapter  
				if [ "$chapter" -gt 1 ]; then
					current_ref="${book}:$((chapter - 1))"
				else
					# Move to previous book, last chapter
					prev_book=$(get_prev_book "$book")
					prev_chapters=$(get_chapter_count "$prev_book")
					current_ref="${prev_book}:${prev_chapters}"
				fi
				view_mode="page"
				;;
			N)
				# Next book
				next_book=$(get_next_book "$book")
				current_ref="${next_book}:1"
				view_mode="page"
				;;
			P)
				# Previous book
				prev_book=$(get_prev_book "$book")
				current_ref="${prev_book}:1"
				view_mode="page"
				;;
			j)
				# Next verse
				verse_count=$(get_verse_count "$book" "$chapter")
				if [ "$verse" -lt "$verse_count" ]; then
					current_ref="${book}:${chapter}:$((verse + 1))"
				else
					# Move to next chapter, verse 1
					chapter_count=$(get_chapter_count "$book")
					if [ "$chapter" -lt "$chapter_count" ]; then
						current_ref="${book}:$((chapter + 1)):1"
					else
						# Move to next book, chapter 1, verse 1
						next_book=$(get_next_book "$book")
						current_ref="${next_book}:1:1"
					fi
				fi
				view_mode="single"
				;;
			k)
				# Previous verse
				if [ "$verse" -gt 1 ]; then
					current_ref="${book}:${chapter}:$((verse - 1))"
				else
					# Move to previous chapter, last verse
					if [ "$chapter" -gt 1 ]; then
						prev_verse_count=$(get_verse_count "$book" "$((chapter - 1))")
						current_ref="${book}:$((chapter - 1)):${prev_verse_count}"
					else
						# Move to previous book, last chapter, last verse
						prev_book=$(get_prev_book "$book")
						prev_chapters=$(get_chapter_count "$prev_book")
						prev_verse_count=$(get_verse_count "$prev_book" "$prev_chapters")
						current_ref="${prev_book}:${prev_chapters}:${prev_verse_count}"
					fi
				fi
				view_mode="single"
				;;
			' ')
				# Next page (space bar) - stay within chapter
				verse_count=$(get_verse_count "$book" "$chapter")
				next_start=$((display_start_verse + page_size))
				if [ "$next_start" -le "$verse_count" ]; then
					current_ref="${book}:${chapter}:${next_start}"
				else
					# Already at end of chapter, stay there
					current_ref="${book}:${chapter}:${verse_count}"
				fi
				view_mode="page"
				;;
			b)
				# Previous page - stay within chapter
				prev_start=$((display_start_verse - page_size))
				if [ "$prev_start" -gt 0 ]; then
					current_ref="${book}:${chapter}:${prev_start}"
				else
					current_ref="${book}:${chapter}:1"
				fi
				view_mode="page"
				;;
			t)
				# Toggle view mode
				if [ "$view_mode" = "page" ]; then
					view_mode="single"
					current_ref="${book}:${chapter}:${verse}"
				else
					view_mode="page"
					current_ref="${book}:${chapter}:1"
				fi
				;;
			g)
				# Go to specific reference
				echo
				printf "Enter reference: "
				if command -v stty >/dev/null 2>&1; then
					stty "$old_stty"
					read -r new_ref
					stty -echo -icanon min 1 time 0
				else
					read -r new_ref
				fi
				if [ -n "$new_ref" ]; then
					current_ref="$new_ref"
					if echo "$new_ref" | grep -q ".*:.*:.*"; then
						view_mode="single"
					else
						view_mode="page"
					fi
				fi
				;;
			q)
				echo
				echo "Exiting navigation mode."
				break
				;;
			'?')
				echo
				echo "Navigation controls:"
				echo "  n         Next chapter"
				echo "  p         Previous chapter"
				echo "  N         Next book"
				echo "  P         Previous book"
				echo "  j         Next verse"
				echo "  k         Previous verse"
				echo "  space     Next page (within chapter)"
				echo "  b         Previous page (within chapter)"
				echo "  t         Toggle page/single view"
				echo "  g         Go to specific reference"
				echo "  q         Quit navigation"
				echo "  ?         Show this help"
				echo
				printf "Press any key to continue..."
				if command -v stty >/dev/null 2>&1; then
					dd bs=1 count=1 2>/dev/null >/dev/null
				else
					read -r
				fi
				;;
			*)
				# Invalid key, just continue
				;;
		esac
	done
	
	if command -v stty >/dev/null 2>&1; then
		stty "$old_stty" 2>/dev/null || true
	fi
}

# Parse command line arguments
NAV_MODE=0

while [ $# -gt 0 ]; do
	isFlag=0
	firstChar="${1%"${1#?}"}"
	if [ "$firstChar" = "-" ]; then
		isFlag=1
	fi

	if [ "$1" = "--" ]; then
		shift
		break
	elif [ "$1" = "-l" ]; then
		# List all book names with their abbreviations
		get_data kjv.tsv | awk -v cmd=list "$(get_data kjv-nav.awk)"
		exit
	elif [ "$1" = "-W" ]; then
		export KJV_NOLINEWRAP=1
		shift
	elif [ "$1" = "-n" ]; then
		NAV_MODE=1
		shift
	elif [ "$1" = "-h" ] || [ "$isFlag" -eq 1 ]; then
		show_help
	else
		break
	fi
done

cols=$(tput cols 2>/dev/null)
if [ $? -eq 0 ]; then
	export KJV_MAX_WIDTH="$cols"
fi

# Handle navigation mode
if [ "$NAV_MODE" -eq 1 ]; then
	if [ $# -gt 0 ]; then
		parsed_ref=$(parse_arguments "$@")
		navigation_mode "$parsed_ref"
	else
		navigation_mode
	fi
	exit 0
fi

# Original functionality
if [ $# -eq 0 ]; then
	if [ ! -t 0 ]; then
		show_help
	fi

	# Interactive mode
	while true; do
		printf "kjv> "
		if ! read -r ref; then
			break
		fi
		parsed_ref=$(parse_arguments $ref)
		get_data kjv.tsv | awk -v cmd=ref -v ref="$parsed_ref" "$(get_data kjv-nav.awk)" | ${PAGER}
	done
	exit 0
fi

parsed_ref=$(parse_arguments "$@")
get_data kjv.tsv | awk -v cmd=ref -v ref="$parsed_ref" "$(get_data kjv-nav.awk)" | ${PAGER}

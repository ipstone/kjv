# Use diatheke command line to obtain Darby version
# NOTE: Requires diatheke (from sword project) to be installed:
#   - Ubuntu/Debian: sudo apt install diatheke
#   - Arch Linux: sudo pacman -S sword
#   - Or compile from: https://crosswire.org/sword/

rm(list=ls())
library(data.table)

# Loading the kjv.tsv data
d = fread("kjv.tsv")

get_darby = function(verse_index) {
# Function to get darby version by diatheke
    # Input is the verse_index: 1 John 3:1
    # Output is the Darby version to be included
    command = paste0("diatheke -b Darby -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    
    # Handle cases where diatheke returns an error or empty result
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        print(paste("ERROR: Failed to get verse for:", verse_index))
        return("")
    }
    
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    # print(paste("-- converting:", verse_index)) ## just for debugging, may slow down converting process
    return(return_verse)
}

# Fix book names that don't work with diatheke (remove "The " prefix)
book_name = ifelse(d$V1 == "The Acts", "Acts", d$V1)
d$index = paste0(book_name, " ", d$V4, ":", d$V5)
# d = d[1:10, ]
d$verse =sapply(d$index, get_darby)

# Remove the line breaks in verse
d$verse = gsub("\n", " ", d$verse, fixed=T)

# Save the converted version
d1 = d[, .(V1, V2, V3, V4, V5, verse)]
fwrite(d1, 'darby.tsv', col.names=F, sep="\t")


# Fix Acts verses only for Darby and ChiUns versions
# This is much faster than converting the entire Bible

rm(list=ls())
library(data.table)

# Function to get darby version by diatheke
get_darby = function(verse_index) {
    command = paste0("diatheke -b Darby -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    
    # Handle cases where diatheke returns an error or empty result
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        print(paste("ERROR: Failed to get verse for:", verse_index))
        return("")
    }
    
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

# Function to get chiuns version by diatheke
get_chiuns = function(verse_index) {
    command = paste0("diatheke -b ChiUns -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    
    # Handle cases where diatheke returns an error or empty result
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        print(paste("ERROR: Failed to get verse for:", verse_index))
        return("")
    }
    
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

# Load existing data
print("Loading existing Darby data...")
darby_data = fread("darby.tsv")
names(darby_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

print("Loading existing ChiUns data...")
chiuns_data = fread("chiuns.tsv")
names(chiuns_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

# Get only Acts verses (book number 44)
acts_rows = darby_data$V1 == "The Acts"
print(paste("Found", sum(acts_rows), "Acts verses to convert"))

if (sum(acts_rows) > 0) {
    # Fix book name for diatheke (remove "The " prefix)
    acts_data = darby_data[acts_rows, ]
    acts_data$index = paste0("Acts ", acts_data$V4, ":", acts_data$V5)
    
    print("Converting Acts verses for Darby...")
    acts_data$verse_darby = sapply(acts_data$index, get_darby)
    
    print("Converting Acts verses for ChiUns...")
    acts_data$verse_chiuns = sapply(acts_data$index, get_chiuns)
    
    # Clean up line breaks
    acts_data$verse_darby = gsub("\n", " ", acts_data$verse_darby, fixed=T)
    acts_data$verse_chiuns = gsub("\n", " ", acts_data$verse_chiuns, fixed=T)
    
    # Update the main data
    darby_data[acts_rows, "verse"] = acts_data$verse_darby
    chiuns_data[acts_rows, "verse"] = acts_data$verse_chiuns
    
    # Save the updated data
    print("Saving updated Darby data...")
    fwrite(darby_data[, .(V1, V2, V3, V4, V5, verse)], 'darby.tsv', col.names=F, sep="\t")
    
    print("Saving updated ChiUns data...")  
    fwrite(chiuns_data[, .(V1, V2, V3, V4, V5, verse)], 'chiuns.tsv', col.names=F, sep="\t")
    
    print("Conversion complete!")
    print(paste("Converted", length(acts_data$verse_darby), "Acts verses"))
    
    # Show sample of converted verses
    print("Sample of converted Acts verses:")
    print("Darby Acts 1:1:")
    print(acts_data$verse_darby[1])
    print("ChiUns Acts 1:1:")  
    print(acts_data$verse_chiuns[1])
    
} else {
    print("No Acts verses found in the data")
}
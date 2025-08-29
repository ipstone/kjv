# Fix the remaining empty verses in darby and chiuns
rm(list=ls())
library(data.table)

# Function to get darby version by diatheke
get_darby = function(verse_index) {
    command = paste0("diatheke -b Darby -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        return("")
    }
    
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

# Function to get chiuns version by diatheke
get_chiuns = function(verse_index) {
    command = paste0("diatheke -b ChiUns -f plain -k \"", verse_index, "\"")
    verse = system(command, intern=TRUE)
    
    if(length(verse) == 0 || is.na(verse[1]) || verse[1] == "") {
        return("")
    }
    
    return_verse = substring(verse[1], nchar(verse_index) + 3)
    return(return_verse)
}

# Load existing data
darby_data = fread("darby.tsv")
names(darby_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

chiuns_data = fread("chiuns.tsv")
names(chiuns_data) = c("V1", "V2", "V3", "V4", "V5", "verse")

# Find empty verses
empty_darby = which(darby_data$verse == "" | darby_data$verse == '""' | nchar(darby_data$verse) == 0)
empty_chiuns = which(chiuns_data$verse == "" | chiuns_data$verse == '""' | nchar(chiuns_data$verse) == 0)

print(paste("Found", length(empty_darby), "empty verses in Darby"))
print(paste("Found", length(empty_chiuns), "empty verses in ChiUns"))

# Fix empty verses in Darby
if (length(empty_darby) > 0) {
    print("Fixing empty verses in Darby:")
    for (i in empty_darby) {
        book = darby_data$V1[i]
        chapter = darby_data$V4[i] 
        verse = darby_data$V5[i]
        
        # Convert book name for diatheke if needed
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

# Fix empty verses in ChiUns
if (length(empty_chiuns) > 0) {
    print("Fixing empty verses in ChiUns:")
    for (i in empty_chiuns) {
        book = chiuns_data$V1[i]
        chapter = chiuns_data$V4[i]
        verse = chiuns_data$V5[i]
        
        # Convert book name for diatheke if needed  
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

# Save the updated data
print("Saving updated data...")
fwrite(darby_data[, .(V1, V2, V3, V4, V5, verse)], 'darby.tsv', col.names=F, sep="\t")
fwrite(chiuns_data[, .(V1, V2, V3, V4, V5, verse)], 'chiuns.tsv', col.names=F, sep="\t")

print("Done fixing remaining empty verses!")
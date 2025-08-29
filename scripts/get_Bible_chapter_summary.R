rm(list = ls())
library(data.table)

# Get the Bible chapter summary
d = fread("kjv.tsv")

# Group by V1 and V2, get the first of V3, max of V4
result <- d[, .(booknum = first(V3), totalchap = max(V4)), by = .(book = V1, abrev = V2)]

# Write the result to a file
fwrite(result, "kjv_chapter_summary.tsv", sep = "\t")

# ___________________________________________________________________________________
# calcANOVA <- function (muscles, geneExpr, numRep)
# ___________________________________________________________________________________
#
# Calculates ANOVAs for the difference in gene expression between muscle tissues.
#
# For every combination of selected muscle tissues, calculates the ANOVA in expression,
# outputting the p-value and the q-value. Allows for only SOME of the geneExpr data to 
# be used, i.e. calculating an ANOVA for a subset of the muscle tissues.
#
# Inputs: - muscles:  vector containing the names of the muscle tissues to be compared
#         - geneExpr: a matrix containing ALL the data for the gene expression. 
#                     Assumes that each row in the matrix is a separate transcript, and
#                     each column is a different replicate for the measured gene expression.
#                     Columns are assumed to be labeled with a muscle code word + repNum,
#                     i.e. "AOR1" or "SOL6".
#         - numRep:   number of replicates for each muscle tissue.
#
# Output: ANOVAp_q:   a list containing two columns: p and q.  
#                     p is the value of the ANOVA (Pr > F)
#                     q is the normalized value of p, relative to the cumulative sum over all the transcripts.
#
# Written as a generalized function by Laura Hughes, based on code by John Hogenesch
# August, 2014; muscle.transcriptome.atlas@gmail.com
# ___________________________________________________________________________________

#read RNS-seq data
# geneExpr = as.matrix(read.csv("allData-sol6BAD.csv", row.names=1))

calcANOVA <- function (muscles, geneExpr, numRep){
  
  # Threshold to assume that there's no variation within the tissues, so don't calculate the ANOVA.
  sd_thresh = 1e-6

# ___________________________________________________________________________________
# Intialize 2 column data frame to hold the data in each loop.
  # cat == categorical label for each of the muscle tissues
  # val == placeholder; where the real expression data will go for calculating each ANOVA.
  
numTissues = length(muscles)
  
d <- data.frame(cat = rep(letters[1:numTissues], each = numRep), val = rep(NA, numRep*numTissues))




# ___________________________________________________________________________________


# ___________________________________________________________________________________
# Initialize final table for the p-values for each transcript.
anova_data <- array(0, dim=c(dim(geneExpr)[1],1))
rownames(anova_data) <- rownames(geneExpr)
# ___________________________________________________________________________________

# ___________________________________________________________________________________
# Figure out which columns will be used for the ANOVA analysis.
colMuscles = NULL

for (j in 1:length(muscles)){
  # Regex modified to be the muscle name + single digit, to avoid TA1 and TAN1 confusion.
  colMuscles = c(colMuscles, grep(paste0("^", muscles[j], "[0-9]"), colnames(geneExpr)))
}

# ___________________________________________________________________________________


# ___________________________________________________________________________________
# Calculate the ANOVA for each transcript (i.e. each row)
for(i in 1:nrow(geneExpr)){
  d[,2] <- geneExpr[i, colMuscles]
  
  # Calculate linear model between the observations
  d_obj <- lm(val~cat, data=d)
  
  if(sd(d_obj$residuals) > sd_thresh){
    d_anova <- anova(d_obj)
    
    anova_data[i,1] <- d_anova[1,5]
    
  } else {
    anova_data[i,1] <- NA
  }
  
  
  
  # Display every 10,000 transcripts how many calcs have been done.
  if (! i%%10000) {
    print(paste("completed ", i, " of ", nrow(geneExpr), " ANOVA calcs."))
  }
}
# ___________________________________________________________________________________


# ___________________________________________________________________________________
# Pull out the p-value; calculate q-value based on the ratio of p to the cumulative sum of p.
p = anova_data[,1]
q = p.adjust(p, method = "BH")

fxp = ecdf(p)
johnQ = p/fxp(p)


# combine p and q into a single data frame so it can be returned
ANOVAp_q = data.frame("p" = p, "q" = q, "johnQ" = johnQ)

return(ANOVAp_q)
# ___________________________________________________________________________________
# write.table(ANOVAp_q, "ANOVA_all_eight.csv", sep=",")
}



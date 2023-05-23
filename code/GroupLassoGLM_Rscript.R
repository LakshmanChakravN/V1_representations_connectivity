# Example R script
getwd()
examplePath <- "/Users/lakshmannc/Documents/GitHub/project-LakshmanChakravN/code/" # Enter the path where the R function (cvLassoGLM) is saved
# Note: for Windows users, you must enter two backslashes, for example "\\home\\Documents\\Data\\"
#       for Linux users, enter the forward slash once, for example "/home/Documents/Data/"
source(paste(examplePath, "cvLassoGLMwithCells.R", sep=""))

desMatPath <- "/Users/lakshmannc/Documents/GitHub/project-LakshmanChakravN/data/" # Enter the path where the designMatrix is saved
numFolds <- 10
cvFileName <- "cvInd.csv" # If you want random assignment for cross-validation then instead of the filename for cvInd enter ""
cvLassoGLMwithCells(desMatPath, "poisson", cvFileName, numFolds) 
# Note: we highly recommend creating your own cross-validation vector.
# In our experience, it improves the fitting compared to random cross-validation
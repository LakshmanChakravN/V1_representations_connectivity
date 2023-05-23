cvLassoGLMwithCells <- function(fileDirectory, linkFunc, cvIndsFileName, nFolds) {
  
  # Example: cvLassoGLM("/home/Documents/Data/", "poisson", "cvIndsVector", 10)
  
  # INPUTS:
  # fileDirectory = the same directory where the designMatrix was saved and where the output files of the model will be saved
  # linkFunc = the link function for the response variable (can be  "poisson", "binomial", or "gaussian").
  #   If you are entering binned spike data then we recommend using linkFunc="poisson"
  # cvIndsFileName = the name of the .csv file defining which fold each observation belongs to. If you prefer not to define the 
  #   cross-validation structure then enter cvIndsFileName=c() and the program will default to randomly assigning the cross-validation.
  #   NOTE: In our experience it is best to provide a cross-validation structure to avoid overfitting!
  # nFolds = the number of cross validation folds. Default is 10.
  
  # OUTPUTS:
  # This function will produce 6 .csv files in the fileDirectory for each response variable entered.
  # These files are labeled as follows: "betas_Cell#", "cve_Cell#", "cvse_Cell#", "lambdas_Cell#", "minlambda_Cell#", "nulldev_Cell#"
  
  
  library(grpreg)
  
  # Save files in different directory
  saveDirectory = paste(fileDirectory, 'RoutputFilesWithCells/')
  
  # Load in the design matrix
  dMatFileRoot <- gsub(" ","",paste(fileDirectory, "DesignMatrixWithCells.txt"),fixed=TRUE)
  dMat <- read.delim(dMatFileRoot,header=TRUE, sep=",", quote = "")
  
  # Separate cell responses from design matrix
  colidx <- which(colnames(dMat)=="Cell1_26_1")
  cellResponses <- dMat[ ,colidx:ncol(dMat), drop=FALSE]
  
  #if (is.vector(cellResponses)) {
  #  cellResponses <- matrix(cellResponses)
  #}
  

  
  # Read in cvInds file
  cvIndsFileRoot <- gsub(" ","",paste(fileDirectory, cvIndsFileName),fixed=TRUE)
  if(file.exists(cvIndsFileRoot)) {
    cvInds <- read.csv(cvIndsFileRoot,header=FALSE, sep=",")
    cvInds <- data.frame(cvInds) 
    print("Found CV File")
  }
  else {
    cvInds <- c()
  }
  
  # Fit model on each cell and save output files in the fileDirectory
  for (cell in 7:(ncol(cellResponses))) {
    
    # Change dMat in each iteration by removing just the cell that goes into y
    thisCellColIdx <- which(colnames(dMat)==paste("Cell",cell,"_26_",cell, sep=""))
    thisDMat <- dMat[ ,-thisCellColIdx]
    
    # Extract group numbers from variable names
    dVars <- strsplit(colnames(thisDMat),'_')
    secondFromEnd <- function(x){
      return(x[length(x)-1]) }
    dVars <- sapply(dVars,secondFromEnd) 
    dVars <- t(data.frame(dVars))
    
    
    binnedSpikes <- cellResponses[ ,cell]
    
    
    
    if (sum(cellResponses)<=10) {
      print("Too few spikes, skipping")
      next
    }
    
    print(colnames(cellResponses[cell])) # Indicates which cell is currently being processed
    
    if(!length(cvInds)){
      cvMdl <- cv.grpreg(thisDMat,binnedSpikes,group=dVars,nfolds=nFolds,returnY=TRUE,trace=TRUE,family=c(linkFunc),penalty=c("grLasso")) 
    } else {
      cvMdl <- cv.grpreg(thisDMat,binnedSpikes,group=dVars,nfolds=nFolds,fold=cvInds,returnY=TRUE,trace=TRUE,family=c(linkFunc),penalty=c("grLasso")) 
    }
    
    write.csv(cvMdl$cve,gsub(" ","",paste(saveDirectory, "cve_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
    write.csv(cvMdl$cvse,gsub(" ","",paste(saveDirectory, "cvse_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
    write.csv(cvMdl$fit$beta,gsub(" ","",paste(saveDirectory, "betas_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
    write.csv(cvMdl$lambda,gsub(" ","",paste(saveDirectory, "lambdas_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
    write.csv(cvMdl$lambda.min,gsub(" ","",paste(saveDirectory, "minlambda_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
    write.csv(cvMdl$null.dev,gsub(" ","",paste(saveDirectory, "nulldev_",colnames(cellResponses[cell])),fixed=TRUE),row.names=FALSE)
  }
}


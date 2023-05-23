 # Read Data
 
 In this phase of the pipeline, you make important decisions about how to represent your data.
 Good choices make subsequent analysis code easier to write and read.
 Good choices make it easier to allow a later switch to a different raw data format.  

The specific assignment is to write the function prototype, the documentation, and descriptive section headers (using cells: %%) for your data import routine in  `.code/read.m`.  

The code will, of course, depend greatly on the specifics of your project and the nature of the external data file. We'll be looking primarily for the following items :
- The choice of input arguments  (and their documentation in the INPUT section) should demonstrate that this function can be used flexibly (e.g. different OS, different folders for the data, maybe options to select a subset of data from a file?).
- The choice of output argument(s) (and their documentation in the OUTPUT section) should explain why you chose the specific data representation (ND-array, struct, cell).
- Error checking/Sanity Checks - Does the file exist? Are the contents what you expect them to be, (e.g. check for a minimum number of trials, a valid date range, or anything else that helps you decide that this file really has the data you think it has)
- Good style should be followed throughout (meaningful variable names, consistent capitalization, etc.  .

If you have trouble completing the actual code, you should use pseudo-code (i.e. text describing what the code would have to do, rather than the code itself), to demonstrate that you know what needs to be done, even if you don't know how to do it yet. You will fill in the details later. 

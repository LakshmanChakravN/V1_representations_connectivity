# Project
This repository will contain all code, documentation and, if possible, data for the  project.

Your project does not have to be complex, but performing one T-test and one ranksum test does not count as an exploratory and an advanced analysis method. Try to do something that is useful for your research. If it really moves your research forward, then it is probably enough for the course too. If I find the draft version lacking in complexity, I will let you know in the GitHub comments. 

Before finalizing the project, or before submitting  a particular section, please reread the comments you received on assignments throughout the course. You can re-use code **you** developed during the course, but if you use code developed by others, make sure to mark it as such.

## Grading
For a good grade, your project needs to demonstrate: 
1. Adherence to the principles of writing readable, reusable, and reliable code. Use the [checklist](./docs/checklist.md)!
2. A solid understanding of one or more of the data analysis techniques covered in the course. You demonstrate this by applying these techniques to your data.
3. An ability to generate publication-quality graphical output from Matlab.  

## Submitting Code, Sharing Data
All code (and small data files) should be on the main branch of your GitHub repository. Issue a pull-request to merge with the feedback branch for me to review. If larger data files (>50 MB) are needed for your scripts to run, share them via OneDrive, or Google Drive. Make sure that the sharing link you create says something like “Anyone with the link can view” and do not share with a specific account.  Place the sharing link in the file that needs access to the data so that the instructors can easily download the data set. 

## Using External Toolboxes
In general, using external toolboxes for your projects is encouraged (don't reinvent the wheel). That said, you have to be able to explain the analysis that such a toolbox does, and not just accept the results blindly. GUIs in external toolboxes can be useful when you're in an exploratory phase of a project, and they can be a good way to learn about the different analyses,  but they are problematic when it comes to the consistent application of a specific set of analysis steps. **Projects in this course must therefore run on the command line, without GUI intervention**. 


## Assignments

*Sections 1-7 are assigned in separate modules of the course. They are only presented here so that you can see the whole trajectory to the end of the course. Although you are, of course, free to work ahead, some of these sections will make more sense at a later stage in the course.*

---
### 1. Outline the Pipeline

The first step is to make an [outline of your data analysis pipeline](./docs/pipeline.md). 

---

### 2. Read Data

Every data analysis pipeline starts with reading data from a raw/external data file or database.
In this assignemnt you [write the code to read your data](./docs/readdata.md). 

---

### 3. Preprocessing 

Write a separate function (`./code/preprocess.m`) with  preprocessing code. This function takes the output of the `read` function and returns a clean version of the data. The same evaluation criteria apply: a good choice of input/output arguments, flexibility, and error checking.  In addition, this function should 
- Handle missing values, make simple adjustments (for instance, change units from V to mV, or s to ms ), removing bits and pieces of the raw data that are never used. 
- Remove outliers or perform other data cleaning procedures.  

---

### 4. First Draft

Produce all m-files (i.e., addressing points 1-7) and their documentation. You should implement as much code as you can, but if you're not sure yet about some sections, use pseudo-code or text to write what you would like to do in that section.  The more you implement, the more specific feedback you will get. 

---

### 5. Exploratory Analysis 

Complete the script/function to perform an exploratory data analysis to get some insight into the raw data (e.g. histograms, means, ranges, etc. ) 

---

### 6. Advanced Analysis

Create the core analysis scripts/functions. 
- Use one or more of the data analysis techniques covered in the course
- Your script/function takes the output of the `preprocess` function and generates output that you can use to do statistical analysis. 
- Include a statistical test (either with linear mixed models or with a permutation test).
- Pretty-print the statistical output so that you can paste it into a document. 

---

### 7. Graphics

- Write a script to generate at least two figures that visualize your results and meet the standard for submission to the Journal of Neuroscience.

---

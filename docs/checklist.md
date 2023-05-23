# Checklist

Please check each m-file in your project against this list.  

- Use meaningful variable names and meaningful file names for m-files.
- Don’t use bare numbers in your code; define constants for parameters that do not change, and/or use input arguments with default values for parameters that might change.
- Pick a style (e.g. from Johnson’s style guide) and stick to it.
- Every script and function has complete documentation at the top (and code comments throughout).
- Cell style markers (%%) separate logically distinct sections in each script/function.
- Code is not duplicated unnecessarily.
- Organize code within a script to reuse code
- Use function m-files or nested functions for bits of code that are needed multiple times in your scripts (or other functions)
- Use vectorized code when possible.
- Use the inputParser for every function with multiple input arguments.
- Output figures meet all requirements for submission to J Neuroscience. Check their Guide for Authors.
- Check Matlab’s suggestions about how to improve your code; the top-right square should be green (and not by just disabling all warnings!)
- Pre-allocate variables before a loop.
- Before submitting, clear all variables in your workspace, then run your scripts to make sure they actually run. 

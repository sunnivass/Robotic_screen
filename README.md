# Robotic_screen

Scripts for analyzing data from Eve, an automated high-throughput screening system
https://doi.org/10.1098/rsob.120158

# scripts
move_files.py  
robot_merge.py  
robot_growthcurves.R  
Eve_growthrates_multi.R 

# 1. move_files.py (py3)

Eve stores all files in one folder and since the barcoding scanner was not working, this script moves files to folders in a fixed sequencce.

Preparation: Change script according to number of plates in batch and rename filenames etc. See script comments for where to edit

# 2. robot_merge.py (py3)
requirement: pandas, datetime

This script takes the measurements from all .DAT files in a folder (output from move_files.py) and puts it in a wide table format, with well position vs time (in hour unit)

Preparation: Change filename and directory
Requires well.csv 

# 3. Robot_growthcurves.R

This script takes data from robot_merge.py and makes separate plots for all IDs (compounds) with average +/- SD and the control (DMSO) as reference. 
Preparation: Change directory, library file and filenames
Requires metadata about library used and 1to4_array.csv
Works platewise

# 4. Eve_growthrates_multi.R

This script takes data from robot_merge.py and gives yield and GT using the package growthrates, in addition to t-test statistics and adjusted p-values. This script was done with the help of 
https://cran.r-project.org/web/packages/growthrates/vignettes/Introduction.html

Preparation: Change directory, library file and filenames
Requires metadata about library used and 1to4_array.csv
Works librarywise - ie put all platefiles from a library in a folder. 







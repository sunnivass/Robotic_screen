#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Oct 26 12:45:07 2021

@author: sunniva
"""

import glob
import os
import shutil


# This script takes files from a folder 
# renames them based on a rep vector (1,2,1,2 etc)
# and saves in two new folders based on new name

# It remains to make the script reproducible (?)


full_path = '/home/sunniva/Desktop/COVID/robot_data/raw_data/220217_SuelenSunniva_1/'
files = [name for name in sorted(glob.glob(full_path + "*.DAT"))]
print('\n'.join(files))


length = round(len(files)/3)
print(length)

vector = ["PatBox_Hs-Wt","Ver-01", "Ver-02"]*length
print(vector)

# add _1 or _2 to file

for (i,j) in zip(files, vector):
    os.rename(i, i.replace("AUTOMATED__", "AUTOMATED_" + j))

# make directories
Dirs = ["PatBox_Hs-Wt", "Ver-01", "Ver-02"]
for d in Dirs:
    path = os.path.join(full_path, d)
    os.mkdir(path)
    print("Directory '% s' created" % d)
    

# move based on _1 or _2
for file in glob.iglob(full_path + "AUTOMATED_PatBox_Hs-Wt*"):
    file_name = os.path.basename(file)
    print(file_name)
    shutil.move(file, full_path + "PatBox_Hs-Wt/" + file_name)

for file in glob.iglob(full_path + "AUTOMATED_Ver-01*"):
    file_name = os.path.basename(file)
    print(file_name)
    shutil.move(file, full_path + "Ver-01/" + file_name)
    
for file in glob.iglob(full_path + "AUTOMATED_Ver-02*"):
    file_name = os.path.basename(file)
    print(file_name)
    shutil.move(file, full_path + "Ver-02/" + file_name)

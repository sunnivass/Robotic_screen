#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jul  1 09:30:44 2021

@author: sunniva
"""

import glob
import re
from datetime import datetime
from datetime import timedelta
import pandas as pd

# This script takes results files from the Eve robot
# and makes a horizontal table of measurements.
# It remains to make the script reproducible (?)
# settings differ between OD and fluo - make one script each

full_path = "/home/sunniva/Desktop/COVID/robot_data/raw_data/220216_SuelenSunniva/Ver-02/"
files = [name for name in sorted(glob.glob(full_path + '*.DAT'))]
print('\n'.join(files))

# this function extracts the timestamp from filename
# at time 0 (hpi_first) and time t (hpi)
# then takes the difference between them and stores delta hours


FMT = '%Y%m%d_%H%M%S'
#print(FMT)
hpi_first = re.findall(r'(?<=detected__)\w+', files[0])
print(*hpi_first)

def get_time(fname):
    hpi = re.findall('(?<=detected__)\w+', fname)
    tdelta = datetime.strptime(*hpi, FMT) - datetime.strptime(hpi_first[0], FMT)
    return str(tdelta / timedelta(hours=1))


df = pd.read_csv('/home/sunniva/Desktop/COVID/Robot_DA/wells.csv')

# this takes hpi and values from files
# and adds to dataframe containing well names
# change skiprows - OD: 496, Fluo: 488


for fname in files:
    time = get_time(fname)
    df_file = pd.read_csv(fname, sep=":", skiprows=488, nrows=384, index_col=False, usecols=[1])
#    ls = df_file.values.tolist()
    df[time] = df_file

print(df)


df.to_csv("/home/sunniva/Desktop/COVID/robot_data/Ver-02.csv", index=False)

#!/usr/bin/env python3
import pandas as pd
import numpy as np
import gspread
from oauth2client.service_account import ServiceAccountCredentials
    
# use creds to create a client to interact with the Google Drive API
scope =['https://spreadsheets.google.com/feeds', 'https://www.googleapis.com/auth/drive']

creds = ServiceAccountCredentials.from_json_keyfile_name('/tmp/testddbjapi-d6ecaa3f4cdd.json', scope)

client = gspread.authorize(creds)
# Find a workbook by name and open the first sheet
# Make sure you use the right name here.
wks = client.open("MSS Working list").worksheet('submissions')
temp_line2add = pd.read_csv('/workspace/temp_py/line2add.tsv', sep="\t", header=None, keep_default_na=False)
temp_line2add.columns = ['mass_id', 'accession', 'prefix_count', 'div', 'BioProject', 'BioSample', 'DRR']
line2add = temp_line2add[['accession', 'prefix_count', 'div', 'BioProject', 'BioSample', 'DRR']]
massid = temp_line2add.loc[0, 'mass_id']
# find row where mass-id is located
cell = wks.find(massid)
position = f'U{cell.row}:Z{cell.row}'
wks.update(range_name=position, values=line2add.values.tolist())

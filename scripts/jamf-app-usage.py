
#!/usr/local/bin/python3

#### README ####
#
# Uses the JAMF API to pull application usage for all computers in your environment and export it in a CSV
# Can take a long time depending on your environment and selected date range.
#
#### REQUIREMENTS ####
#
# * Python3 'requests' module (pip3 install requests)
# * JAMF user credentials with read access to computer application usage
#
#### USER VARIABLES ####

# No trailing / please :)
jamf_url=''
api_user = ''
api_password = ''
# date_range = '2021-03-09_2021-03-10' for example
date_range = ''

import requests
from requests.auth import HTTPBasicAuth
import csv

CSVExport = open('JamfAppUsage.csv', 'w', newline='')
writer = csv.writer(CSVExport)

id_computer_list = []
apps_list = []
data_list = []

get_computers = requests.get("%s/JSSResource/computers" % jamf_url, auth=HTTPBasicAuth(api_user, api_password), headers={'Accept': 'application/json'}).json()

for c in get_computers['computers']:
    criterias = [c['name'], c['id']]
    id_computer_list.append(criterias)


for comp in id_computer_list:
    get_usage = requests.get("%s/JSSResource/computerapplicationusage/id/%s/%s" % (jamf_url, comp[1], date_range), auth=HTTPBasicAuth(api_user, api_password), headers={'Accept': 'application/json'}).json()
    try:
        for u in get_usage['computer_application_usage']:
            for a in u['apps']:
                writer.writerow([comp[0], u['date'],  a['name'], a['open'], a['foreground']])
    except Exception as x:
        print (x)
    
CSVExport.close



    


      
  


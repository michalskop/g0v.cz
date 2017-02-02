import datetime
import os
import requests
import sys

# import api:
try:
    dir_path = os.path.dirname(os.path.realpath(__file__))
except:
    dir_path = os.path.realpath('.')

up_path = '/'.join(dir_path.split('/')[:-1])
sys.path.insert(0, up_path)
sys.path.insert(0, dir_path)

import api
import credentials

api.login(email=credentials.email, password=credentials.password)

data = api.get_all("finished_not_solved")

for row in data:
    params = {"id": "eq." + str(row['id'])}
    if row['in_time']:
        status = "ok"
    else:
        status = "finished late"
    d = {"status": status}
    api.patch("runs", params=params, data=d)

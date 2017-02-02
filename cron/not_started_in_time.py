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

data = api.get_all("not_started_in_time")

if len(data) > 0:
    message = "cron.g0v.cz not started in time:\n"
    for row in data:
        message += row['name'] + ", last run started " + row['interval_since_last'] + " ago\n"

    requests.post("https://botsend.me/", json={"message": message})

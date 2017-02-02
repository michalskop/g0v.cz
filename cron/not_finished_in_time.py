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

data = api.get_all("not_finished_in_time")

if len(data) > 0:
    message = "cron.g0v.cz not finished in time:\n"
    for row in data:
        message += row['name'] + ", start: " + row['start_date'] + "\n"
        params = {"id": "eq." + str(row['id'])}
        d = {"status": "fail"}
        api.patch("runs", params=params, data=d)

    requests.post("https://botsend.me/", json={"message": message})

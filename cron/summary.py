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

data = api.get_all("last_day")

d = {}
message = ""
for row in data:
    try:
        d[row['code']]
    except:
        d[row['code']] = {
            "name": row['name'],
            "status": {}
        }
    try:
        d[row['code']]['status'][row['status']]
    except:
        d[row['code']]['status'][row['status']] = {
            "count": 0,
            "message": ""
        }
    d[row['code']]['status'][row['status']]['count'] += 1
    if row['message'] is not None:
        d[row['code']]['status'][row['status']]['message'] += str(row['message']) + "\n"

for code in d:
    message += d[code]['name'] + ":\n"
    for status in d[code]['status']:
        message += status + ": " + str(d[code]['status'][status]['count']) + "\n"
        message += d[code]['status'][status]['message'] + "\n"

if message == "":
    message = "No runs."
message = "cron.g0v.cz daily summary:\n" + message


requests.post("https://botsend.me", json={'message': message})

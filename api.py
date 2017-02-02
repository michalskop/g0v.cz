"""API client module.
Contains functions for sending API requests conveniently.
For Postgrest v 0.4
for use in g0v.cz project
"""

import json
import requests

import settings

HEADERS = {
    'Content-Type': 'application/json'
}


def get(resource, params=None, headers=HEADERS):
    r = requests.get(
        settings.SERVER_NAME + resource,
        params=params,
        headers=headers
    )
    r.raise_for_status()
    return r


def get_one(resource, params=None, headers=HEADERS):
    '''GET single item
    Returns None if no such item exists
    Note: Unlike many other API functions returns directly the result'''
    h = headers.copy()
    h['Accept'] = 'application/vnd.pgrst.object'
    r = requests.get(
        settings.SERVER_NAME + resource,
        params=params,
        headers=h
    )
    if r.status_code < 300:
        return r.json()
    else:
        return None


def get_all(resource, params=None, headers=HEADERS):
    '''GET all items
    Note: Unlike many other API functions returns directly the array of results'''
    h = headers.copy()
    h['Prefer'] = "count=exact"
    r = get(resource, params, h)
    r.raise_for_status()
    size = int(r.headers['Content-Range'].split('/')[1])
    try:
        last = int(r.headers['Content-Range'].split('/')[0].split('-')[1])
    except:
        last = 0
    arr = r.json()
    h = headers.copy()
    while (last + 1) < size:
        h['Range'] = str(last + 1) + "-"
        r = get(resource, params, h)
        last = int(r.headers['Content-Range'].split('/')[0].split('-')[1])
        arr = arr + r.json()
    return arr


def post(resource, data, headers=HEADERS, representation=False):
    h = headers.copy()
    if representation:
        h['Prefer'] = "return=representation"
    r = requests.post(
        settings.SERVER_NAME + resource,
        data=json.dumps(data),
        headers=h
    )
    r.raise_for_status()
    return r


def patch(resource, params=None, data=None, headers=HEADERS):
    r = requests.patch(
        settings.SERVER_NAME + resource,
        params=params,
        data=json.dumps(data),
        headers=headers
    )
    # r.raise_for_status()
    return r


def delete(resource, params=None, headers=HEADERS):
    r = requests.delete(
        settings.SERVER_NAME + resource,
        params=params,
        headers=headers
    )
    r.raise_for_status()
    return r


def login(email, password):
    try:
        del(HEADERS['Authorization'])
    except:
        nothing = None
    r = post("rpc/login", {"email": email, "pass": password})
    r.raise_for_status()
    HEADERS['Authorization'] = 'Bearer ' + r.json()[0]['token']
    return r


def post_id(request):
    '''Returns id of POSTed item
    Only for a single item POSTed'''
    try:
        arr = request.headers['Location'].split('id=eq.')
        return arr[1]
    except:
        return None

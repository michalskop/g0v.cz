#!/bin/bash

# sudo -i -u postgres

MYEMAIL="michal.skop@example.com"
MYPASS="example"

psql -d g0v -c "INSERT INTO basic_auth.users(email,pass,role) VALUES ('$MYEMAIL','$MYPASS','author')"

#psql -c "ALTER USER postgres WITH PASSWORD '$MYPGSQLPASS'"

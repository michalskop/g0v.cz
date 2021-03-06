# install cron db
# requires running AFTER server install.sh

# install cron db
# requires running AFTER install.sh

# run from the correct directory

include cronsettings.sh
# source settings.sh

# config file
cd /tmp

wget "https://gist.githubusercontent.com/michalskop/9edee4757545c7d905c4/raw/b8d369457051a55bedca2cda07673ada828e9c06/postgrest.conf" -O postgrest.conf
grep -rl 'xuser' ./postgrest.conf | xargs sed -i "s/xuser/$PGSQLUSER/g"
grep -rl 'xpass' ./postgrest.conf | xargs sed -i "s/xpass/$PGSQLPASS/g"
grep -rl 'x5432' ./postgrest.conf | xargs sed -i "s/x5432/$PORT/g"
grep -rl 'xdbname' ./postgrest.conf | xargs sed -i "s/xdbname/$DB/g"
grep -rl 'xapi' ./postgrest.conf | xargs sed -i "s/xapi/$SCHEMA/g"
grep -rl 'xanon' ./postgrest.conf | xargs sed -i "s/xanon/$ANON/g"
grep -rl 'xhost' ./postgrest.conf | xargs sed -i "s/xhost/$HOST/g"
grep -rl '3000' ./postgrest.conf | xargs sed -i "s/3000/$APIPORT/g"
sudo cp postgrest.conf /opt/postgrest/postgrest-$APIPORT.conf

# service
wget "https://gist.githubusercontent.com/michalskop/9edee4757545c7d905c4/raw/578c4bb595bc890b86ae8a0ebfe08a36eabe87c8/postgrest.service" -O postgrest.service
grep -rl '3000' ./postgrest.service | xargs sed -i "s/3000/$APIPORT/g"
sudo cp postgrest.service /etc/systemd/system/postgrest-$APIPORT.service

sudo service postgrest-$APIPORT start

# api apache config
cd /tmp

wget "https://gist.githubusercontent.com/michalskop/9edee4757545c7d905c4/raw/92a67b4302a1f46df7dbf4fe5a0b6783ca9db04a/api.example.com.conf" -O api.example.com.conf
grep -rl 'example.com' ./api.example.com.conf | xargs sed -i "s/api.example.com/$MYSITE/g"
sudo cp api.example.com.conf /etc/apache2/sites-available/$MYSITE.conf
sudo a2ensite $MYSITE

# already enabled:
# sudo a2enmod proxy
# sudo a2enmod proxy_html
# sudo a2enmod rewrite

sudo service apache2 restart

# create db
su postgres
include cronsettings.sh

createdb $DB -O postgres -E UTF-8 -D pg_default --lc-collate cs_CZ.UTF-8 --lc-ctype cs_CZ.UTF.8 -T template0


psql -f "$INSTALLPATH"cron_basic_auth_setup.sql -d $DB
#psql -f "$APIPATH"hlasovali.sql -d $DB

    # basic insert

psql -d $DB -c "INSERT INTO basic_auth.users(email,pass,role) VALUES ('$MYEMAIL','$MYPASS','author')"

exit

# letsencrypt
sudo /usr/bin/letsencrypt

# python packages
sudo apt-get -y install python3-pip
sudo pip3 install lxml


# botsendme
sudo apt-get install libapache2-mod-wsgi-py3 python-dev
sudo a2enmod cgi
sudo a2enmod xml2enc
sudo pip install virtualenv
cd ~
sudo virtualenv .botsendme
source .botsendme/bin/activate
sudo pip3 install Flask




sudo service apache2 restart

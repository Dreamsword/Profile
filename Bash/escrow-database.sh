#!/bin/bash

# Most operating systems play nicely with PostgreSQL's defaults.
superuser=postgres
superdb=postgres
psql=psql

build_db_version="9.3.16"
VERSION="6.5.1"

apt-get -y install postgresql-common
db_version=$(pg_lsclusters | grep online | sed 's/[\t ]\+/,/g' | cut -d, -f1 | tail -n 1)
if [ x$db_version == x ];then
  db_version=9.3
fi

if test "x$SUDO_USER" != x; then
  userhome=/home/$SUDO_USER
else
  userhome=$HOME
fi
TARBALL="$userhome/rocketseed-$VERSION-bin.tar.bz2"

while test $# -ge 1; do
  case "x$1" in
  x-f)  # force a fresh install
    force=yes
    shift;
    ;;
  x-fl) # frontline
    force=frontline
    shift;
    ;;
  x-fr) # frontline triggers on an existing rocketseed DB
    force=rocketseed
    shift;
    ;;
  *)
    break;
    ;;
  esac
done

# Accept a parameter for a netblock from which database clients may connect.
if test $# -ge 1; then
  clients="$1"
else
  clients=""
fi

# Set shared memory so that the DB can start up at least in the sections below
if grep -q '^[^#]*kernel[./]shmmax\>' /etc/sysctl.conf; then
  sed -i '/^kernel.shmmax = .*$/d' /etc/sysctl.conf
fi;

shmem=$(expr `free -b|grep Mem:|sed 's/[\s\t ]\+/,/g'|cut -d, -f2` / 3)
echo "Got shmem is $shmem"
if [ -e /etc/sysctl.d/30-postgresql-shm.conf ];then
  sed -i "s/^[^\w]*kernel.shmmax =.*$/kernel.shmmax = $shmem/" /etc/sysctl.d/30-postgresql-shm.conf
else
  echo "kernel.shmmax = $shmem" > /etc/sysctl.d/30-postgresql-shm.conf
fi
service procps start
echo "Got shared mem set to $shmem"

apt-get -y install patch postgresql postgresql-client postgresql-contrib pgpool2 sysstat pcregrep pgtune

# In case the new version of postgresql overwrites the 30-postgresql-shm file, we set
# it again
sed -i "s/^[^\w]*kernel.shmmax =.*$/kernel.shmmax = $shmem/" /etc/sysctl.d/30-postgresql-shm.conf
service procps start

# The ports in 12.04 seem to be reversed from what they were in 10.04 (pgpool=5433 and postgres on 5432)
# Since we do all our DB access on 5433, make that the port for pgpool, and restore postgres to 5432
if [ -e /etc/pgpool2/pgpool.conf ]; then
  sudo perl -pi -e 's/^port = 543./port = 5433/' /etc/pgpool2/pgpool.conf
  sudo service pgpool2 stop
  if [ -e /etc/postgresql/$db_version/main/postgresql.conf ]; then
    sudo perl -pi -e 's/^port = 543./port = 5432/' /etc/postgresql/$db_version/main/postgresql.conf
    sudo service postgresql restart
  fi
  sudo service pgpool2 start
fi
if ! grep 'ssl = false' /etc/postgresql/$db_version/main/postgresql.conf; then
  echo 'ssl = false' >> /etc/postgresql/$db_version/main/postgresql.conf
fi

# Change the logging output (Stephen Tyson)
sudo perl -pi -e "s/^.*log_line_prefix = .*$/log_line_prefix = '%t %d %e '/" /etc/postgresql/$db_version/main/postgresql.conf

pg_hba="/etc/postgresql/$db_version/main/pg_hba.conf"
psql="sudo -u postgres psql"

if [ "x$clients" != "x" ]; then
  if fgrep -q "$clients" "$pg_hba"; then
    echo "$clients is already listed in $pg_hba, leaving access unchanged" >&1
  else
    cat >>"$pg_hba" <<EOF
host    all         all         `printf %-21s "$clients"` md5
host    all         all         127.0.0.0/8           md5
EOF
  fi
fi

if test "x$force" = xyes; then
  $psql -U $superuser $superdb <<EOF
DROP DATABASE IF EXISTS rocketseed2;
DROP DATABASE IF EXISTS datawarehouse;
DROP DATABASE IF EXISTS drupal_db;
DROP USER IF EXISTS rocketseed_user;
DROP USER IF EXISTS drupal_user;
CREATE USER rocketseed_user WITH PASSWORD 'r0cketseed';
CREATE DATABASE rocketseed2 WITH OWNER rocketseed_user;
CREATE USER drupal_user WITH PASSWORD 'drup4l';
CREATE DATABASE drupal_db WITH OWNER drupal_user;
\c rocketseed2
CREATE LANGUAGE plpgsql;
CREATE EXTENSION dblink;
REVOKE ALL ON DATABASE "postgres" FROM PUBLIC;
EOF

elif test "x$force" = xfrontline; then
  $psql -U $superuser $superdb <<EOF
DROP DATABASE IF EXISTS rocketseed2;
DROP DATABASE IF EXISTS datawarehouse;
DROP DATABASE IF EXISTS drupal_db;
DROP USER IF EXISTS rocketseed_user;
DROP USER IF EXISTS drupal_user;
CREATE USER rocketseed_user WITH PASSWORD 'r0cketseed';
CREATE DATABASE rocketseed2 WITH OWNER rocketseed_user;
\c rocketseed2
CREATE LANGUAGE plpgsql;
CREATE EXTENSION dblink;
REVOKE ALL ON DATABASE "postgres" FROM PUBLIC;
EOF
# Now let's install the empty rocketseed2 database
  cd /tmp
  tar -xjf $TARBALL ./var/www/drupal/sites/worldclass/modules/rscommon/rocketseed2.sql
  mv /tmp/var/www/drupal/sites/worldclass/modules/rscommon/rocketseed2.sql /tmp/
  cd -
  psql -Urocketseed_user -hlocalhost rocketseed2 < /tmp/rocketseed2.sql
  $psql -U $superuser rocketseed2 <<EOF
ALTER TABLE "mstAccount" DROP CONSTRAINT IF EXISTS "mstAccount_parentAccountId_fkey";
ALTER TABLE senderdomains DROP CONSTRAINT IF EXISTS accountid_fkey;
ALTER TABLE "mstAccountIpAddress" DROP CONSTRAINT IF EXISTS "mstAccountIpAddress_parentAccountId_fkey";
ALTER TABLE "lnkAccountIPList" DROP CONSTRAINT IF EXISTS "lnkAccountIPList_account_fkey";
ALTER TABLE "smarthosts" DROP CONSTRAINT IF EXISTS "accountid_fkey";
EOF

elif test "x$force" = xrocketseed; then
  $psql -U $superuser $superdb <<EOF
\c rocketseed2
DROP EXTENSION IF EXISTS dblink;
DROP TYPE IF EXISTS dblink_pkey_results;
CREATE EXTENSION dblink;
EOF
# Install the flsql.sql trigger file
psql -Urocketseed_user -hlocalhost rocketseed2 < $userhome/flsql.sql

elif ! $psql -c '\l' -U $superuser $superdb |grep -q rocketseed2; then
  $psql -U $superuser $superdb <<EOF
CREATE USER rocketseed_user WITH PASSWORD 'r0cketseed';
CREATE DATABASE rocketseed2 WITH OWNER rocketseed_user;
CREATE USER drupal_user WITH PASSWORD 'drup4l';
CREATE DATABASE drupal_db WITH OWNER drupal_user;
REVOKE ALL ON DATABASE "postgres" FROM PUBLIC;
EOF

elif $psql -c '\dT+ rs_format' -U $superuser rocketseed2 | grep -q 'HTML only'; then
$psql -U $superuser $superdb <<EOF
\c rocketseed2
UPDATE "mstAccount" SET "templateFormat"='HTML and Images' WHERE "templateFormat"='HTML only';
UPDATE "mstPerson" SET "templateFormat"='Group Default' WHERE "templateFormat"='HTML only';
UPDATE "mstTag" SET "templateFormat"='Group Default' WHERE "templateFormat"='HTML only';
UPDATE "mstTemplate" SET "templateFormat"='HTML and Images' WHERE "templateFormat"='HTML only';
UPDATE pg_enum SET enumlabel='No banner'
WHERE enumlabel='HTML only'
  AND enumtypid IN (
    SELECT typelem FROM pg_type WHERE typname='_rs_format'
  );
EOF
fi

if ! $psql -c 'SELECT * from pg_language;' -U $superuser rocketseed2 |grep -q plpgsql; then
$psql -U $superuser rocketseed2 <<EOF
CREATE LANGUAGE plpgsql;
EOF
fi

#== Configure pgpool2 on 12.04 ==
if test "x$force" != x; then #doing an install/reset, so adjust pgpool
  sed -i "s/#backend_hostname0 = 'host1'/backend_hostname0 = 'localhost'/" /etc/pgpool2/pgpool.conf
  sed -i "s/#backend_port0/backend_port0/" /etc/pgpool2/pgpool.conf
  sed -i "s/#backend_weight0/backend_weight0/" /etc/pgpool2/pgpool.conf
  sed -i "s/#backend_data_directory0/backend_data_directory0/" /etc/pgpool2/pgpool.conf
  sed -i "s/#*backend_flag0 =.*$/backend_flag0 = 'DISALLOW_TO_FAILOVER'/" /etc/pgpool2/pgpool.conf
  sed -i "s/num_init_children =.*$/num_init_children = 90/" /etc/pgpool2/pgpool.conf
  sed -i "s/max_pool =.*$/max_pool = 1/" /etc/pgpool2/pgpool.conf
  sed -i "s/fail_over_on_backend_error =.*$/fail_over_on_backend_error = off/" /etc/pgpool2/pgpool.conf
fi

#== Move SSL certificates to PGDATA Directory. Addresses the Fsync Permissions Bug
echo "applying a workaround for the SSL certificate fsync persmissions bug"
rm /var/lib/postgresql/9.1/main/server.crt /var/lib/postgresql/9.1/main/server.key
cp /etc/ssl/certs/ssl-cert-snakeoil.pem /var/lib/postgresql/9.1/main/server.crt
cp /etc/ssl/private/ssl-cert-snakeoil.key /var/lib/postgresql/9.1/main/server.key
chown postgres: /var/lib/postgresql/9.1/main/server.crt /var/lib/postgresql/9.1/main/server.key
chmod 640 /var/lib/postgresql/9.1/main/server.crt /var/lib/postgresql/9.1/main/server.key

if ! grep -q rocketeer /etc/pgpool2/pcp.conf; then
  echo rocketeer:`pg_md5 r0cketseed` >> /etc/pgpool2/pcp.conf
fi

if [ -e /etc/init.d/rslogger ]; then
  service rslogger stop
fi
service pgpool2 stop
if [ -e /var/run/postgresql/pgpool_status ]; then
  rm /var/run/postgresql/pgpool_status
fi
service postgresql restart
service pgpool2 start
if [ -e /etc/init.d/rslogger ]; then
  service rslogger start
fi

#==Set up the firewall==
if [ ! -e /etc/ufw/ufw.conf ]; then # just in case something went wrong
  sudo sh -c 'cat >/etc/ufw/ufw.conf' <<EOF
ENABLED=yes
LOGLEVEL=low
EOF
fi

if [ "x`sudo ufw status`" != "xStatus: active" ]; then
  sudo apt-get install ufw
  sudo ufw disable
  sudo ufw default deny
  sudo ufw allow from any to any port 22
  sudo ufw allow from any to any port 5432
  sudo ufw allow from any to any port 5433
  sudo ufw allow from any to any port 9102
  sudo ufw allow from any to any port 9103
  yes y | sudo ufw enable

  sudo cp -p /etc/ufw/ufw.conf /etc/ufw/"ufw.conf`date '+%m%d%y%S'`"
  sudo sh -c 'cat >/etc/ufw/ufw.conf' <<EOF
ENABLED=yes
LOGLEVEL=low
EOF
fi

if test "x$force" = xfrontline; then
  # this is a frontline server, open smtp port
  sudo ufw allow from any to any port 25
fi

# vim: set et sw=2: #

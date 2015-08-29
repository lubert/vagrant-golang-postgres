#!/bin/bash

###########################################################
# Script to set up a Golang + PostgreSQL project on Vagrant.
###########################################################

# Installation settings
PROJECT_NAME=$1
PROJECT_DIR=/home/vagrant/$PROJECT_NAME

# Edit the following to change the name of the database user that will be created (defaults to the project name)
APP_DB_USER=$PROJECT_NAME
APP_DB_PASS=dbpass

# Edit the following to change the name of the database that is created (defaults to the project name)
APP_DB_NAME=$PROJECT_NAME

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.4

# Edit the following to change the version of Golang that is installed
GO_VERSION=1.5

# Edit the following to change the version of Node that is installed
NODE_VERSION=v0.12.7

# Edit the following to change the version of Ruby that is installed
RUBY_VERSION=2.2.2

###########################################################
# Bash
###########################################################

# bash environment global setup
cp -p $PROJECT_DIR/etc/install/bashrc ~/.bashrc

###########################################################
# Build dependencies
###########################################################

sudo apt-get install -y curl git mercurial make binutils bison gcc build-essential

###########################################################
# Golang
###########################################################

if [ ! -f /usr/local/go/bin/go ]; then
  wget –quiet https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
  echo "export GOPATH=/vagrant" >> /home/vagrant/.bashrc
  echo "export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin" >> /home/vagrant/.bashrc
fi

###########################################################
# NVM + Node
###########################################################

if [ ! -f ~/.nvm/nvm.sh ]; then
  curl -s https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | bash
  source ~/.nvm/nvm.sh
  nvm install $NODE_VERSION
  nvm alias default stable
fi

###########################################################
# RVM + Ruby
###########################################################

if [ ! -f ~/.rvm/scripts/rvm ]; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  curl -sSL https://get.rvm.io | bash -s stable --ruby=$RUBY_VERSION
  source ~/.rvm/scripts/rvm
  rvm --default use $RUBY_VERSION
  gem install bundler
fi

###########################################################
# PostgreSQL
###########################################################

print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)"
  echo "  Host: localhost"
  echo "  Port: 15432"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME"
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run system updates manually login via 'vagrant ssh' and run 'sudo apt-get update && sudo apt-get upgrade'"
  echo ""
  print_db_usage
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  sudo bash -c "echo \"deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main\" > \"$PG_REPO_APT_SOURCE\""

  # Add PGDG repo key:
  wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
fi

# Update package list and upgrade all packages
sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit postgresql.conf to change listen address to '*':
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
sudo bash -c "echo \"host    all             all             all                     md5\" >> \"$PG_HBA\""

# Explicitly set default client_encoding
sudo bash -c "echo \"client_encoding = utf8\" >> \"$PG_CONF\""

# Restart so that all new config is loaded:
sudo service postgresql restart

cat <<EOF
 EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF

# Tag the provision time:
sudo bash -c "date > \"$PROVISIONED_ON\""

echo "Successfully created virtual machine."
echo ""
print_db_usage

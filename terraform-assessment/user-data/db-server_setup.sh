#!/bin/bash
yum update -y
amazon-linux-extras install -y postgresql14
yum install -y postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "create database techcorpdb;"
sudo -u postgres psql -c "create user appuser with password 'yourstrongdbpass123!';"
sudo -u postgres psql -c "grant all privileges on database techcorpdb to appuser;"
sed -i 's/ident$/md5/g' /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql 
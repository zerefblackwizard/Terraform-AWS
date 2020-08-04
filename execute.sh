#!/bin/bash
sudo su postgres<<'EOF'
psql -c 'create database test;'
psql -c 'grant all privileges on database test to postgres;'
psql -c 'create table demo(data text);'

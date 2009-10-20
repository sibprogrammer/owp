#!/bin/sh

cd `dirname $0`
rm database
sqlite3 database < ./sql/sqlite/structure.sql
chown www database

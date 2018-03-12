# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version - 2.3.1
 
* Configuration - cinfigured rails using rbenv 
 
* How to run the test suite - run rails server and open localhost:3000. enter the remote mysql server details and backup, restore or validate your database using the tool. While you run backup a BRV directory is created in your home directory and the backup files are stored under the database name. cs.txt a Checksum text file is also created while backup, make sure you don't delete this file. The checksum file thus created will be used during validation of you database restored. SQL file  is used for restoring your database.

Backup options - all databases, individual database or individual table.

Restore options - database or a table, database in which the data will be restored must already be created.

Validate options - database, table or a sql dump. If you haven't already restored a sql file, nut still you want to check it's consistency you can  use validate file option by providing the sql file itself and the checksum file generated for the same. For validating a table or database, select the same and provide checksum file.

# BRVTool

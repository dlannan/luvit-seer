#!/bin/bash
#Purpose = Backup of Important Data
#Created on 6/02/2017 
#Author = David Lannan 
#Version 1.0
#START
TIME=`date +%b-%d-%y-%H`            # This Command will add date in Backup File Name.
FILENAME=backup-redis-$TIME.tar.gz    # Here i define Backup file name format.
SRCDIR=dump.rdb                    # Location of Important Data Directory (Source of backup).
DESDIR=/srv/backups            # Destination of backup file.
tar -cpzf $DESDIR/$FILENAME $SRCDIR
#END

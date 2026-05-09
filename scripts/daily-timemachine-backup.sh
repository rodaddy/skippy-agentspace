#!/usr/bin/env sh
# PAI Daily Time Machine Backup - runs at 3am via com.timemachine.daily
exec /usr/bin/tmutil startbackup --auto --block

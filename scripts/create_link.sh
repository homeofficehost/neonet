#!/bin/bash -x

# -depth 2
find ~/Development -name "off" -type d -exec echo {} \; | while read line; do

  NAME=$(echo $line | awk -F/ '{ print $5 }')
  ISMOD=$(echo $line | awk -F/ '{ print $6 }')
  if [ $ISMOD != "off" ]; then
    # off folder is in depth folder
    MODNAME=$(echo $line | awk -F/ '{ print $7 }')
    echo 'Creating link to: '$MODNAME
    ln -s $line ~/Dropbox/server/off/$MODNAME
  else
    # simple version where folder is on 1 level depth
    echo 'Creating link to: '$NAME
    ln -s $line ~/Dropbox/server/off/$NAME
  fi

done

#ln -s /Users/thomas/Library/Application\ Support/MySQL/Workbench/connections.xml /Users/thomas/Dropbox/Sync/connections.xml

# ln -s ~/Development ~/Dropbox/server/htdocs
# ln -s /Applications/MAMP/db ~/Dropbox/server/db

# ln -s /Library/Application\ Support/appsolute/MAMP\ PRO/db/mysql ~/Dropbox/server/db/mysql
#
#
# iMac
# ln -s /Applications/World\ of\ Warcraft/Interface/AddOns ~/Dropbox/sync/wow-addons
#
#
# Notebook
# ln -s ~/Dropbox/sync/wow-addons /Applications/World\ of\ Warcraft/Interface/AddOns

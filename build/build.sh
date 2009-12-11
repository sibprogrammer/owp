#!/bin/sh

set -xv

cd `dirname $0`

{
  PROJECT="ovz-web-panel"
  SVN_REPO="http://ovz-web-panel.googlecode.com/svn/trunk/"
  
  [ -d $PROJECT ] && rm -rf ovz-web-panel
  
  REVISION=`svn info $SVN_REPO | grep "Revision:" | sed "s/Revision: //g"`
  
  if [ -d $PROJECT.r$REVISION ]; then
    mkdir $PROJECT
    cp -R $PROJECT.r$REVISION/* $PROJECT/
  else
    svn export $SVN_REPO $PROJECT

    echo $REVISION > $PROJECT/revision

    mkdir $PROJECT.r$REVISION
    cp -R $PROJECT/* $PROJECT.r$REVISION/
  fi
  
  cd $PROJECT
    rm -rf build test
    
    # prepare database
    rake db:migrate RAILS_ENV="production"
  cd ..
  
  [ -f $PROJECT-r$REVISION.tgz ] && rm $PROJECT-r$REVISION.tgz
  tar --owner 0 -czf $PROJECT-r$REVISION.tgz ./$PROJECT
  
} 2>&1 | tee build.log

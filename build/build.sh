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
    VERSION=`grep "PRODUCT_VERSION" config/environment.rb | sed -e 's/[^0-9.]//g'`
    echo $VERSION > version

    # prepare database
    rake db:migrate RAILS_ENV="production"
    
    # minimize distribution size
    rm -rf build test vendor/rails/railties/doc/guides vendor/rails/activerecord/test
  cd ..
  
  [ -f $PROJECT-$VERSION.$REVISION.tgz ] && rm $PROJECT-$VERSION.$REVISION.tgz
  tar --owner 0 -czf $PROJECT-$VERSION.$REVISION.tgz ./$PROJECT
  
} 2>&1 | tee build.log

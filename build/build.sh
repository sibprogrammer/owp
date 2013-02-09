#!/bin/sh

set -xve

trap '{ STATUS=$?; if [ $STATUS -ne 0 ]; then echo "Build preparation failed." ; exit $STATUS; fi }' EXIT

cd `dirname $0`

{
  PROJECT="ovz-web-panel"
  REPO="git://github.com/sibprogrammer/owp.git"

  [ -d $PROJECT ] && rm -rf ovz-web-panel

  git clone $REPO $PROJECT

  echo $REVISION > $PROJECT/revision

  cd $PROJECT
    REVISION=`git show | egrep '^commit' | awk '{ print $2 }'`
    echo $REVISION > revision

    VERSION=`grep "PRODUCT_VERSION" config/environment.rb | sed -e 's/[^0-9.]//g'`
    echo $VERSION > version

    for TEXT_FILE in README INSTALL CHANGELOG; do
      mv $TEXT_FILE.md $TEXT_FILE
    done

    # remove extra markup for better readability
    sed -i '/!\[/d' README
    sed -i 's/^##\? //' README

    # prepare database
    rake db:migrate RAILS_ENV="production"

    mkdir -p tmp log

    # minimize distribution size
    rm -rf build vendor/rails/railties/doc/guides vendor/rails/activerecord/test

    rm -rf .git .gitignore .travis.yml
  cd ..

  [ -f $PROJECT-$VERSION.tgz ] && rm $PROJECT-$VERSION.tgz || true
  tar --owner 0 -czf $PROJECT-$VERSION.tgz ./$PROJECT

} 2>&1 | tee build.log

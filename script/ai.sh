#!/bin/sh

# global variables
VERSION="2.4"
DOWNLOAD_URL="http://ovz-web-panel.googlecode.com/files/ovz-web-panel-$VERSION.tgz"
RUBYGEMS_URL="http://production.cf.rubygems.org/rubygems/rubygems-1.3.5.tgz"
RUBY_SQLITE3_CMD="ruby -e \"require 'rubygems'\" -e \"require 'sqlite3'\""
LOG_FILE="/tmp/ovz-web-panel.log"
INSTALL_DIR="/opt/ovz-web-panel/"
FORCE=0 # force installation to the same directory
PRESERVE_ARCHIVE=0
AUTOSOLVER=1 # automatic solving of dependencies
DISTRIB_ID=""
DEBUG=0
UPGRADE=0
UNINSTALL=0
ERR_FATAL=1

for PARAM in $@; do
  eval $PARAM
done

[ "x$DEBUG" = "x1" ] && set -xv 

log() {
  echo `date` $1 >> $LOG_FILE
}

puts() {
  echo $1
  log "$1"
}

puts_separator() {
  puts "-----------------------------------"
}

puts_spacer() {
  puts 
}

exec_cmd() {
  TITLE=$1
  COMMAND=$2
  
  puts "$TITLE $COMMAND"
  `$COMMAND`
}

fatal_error() {
  puts "Fatal error: $1"
  exit $ERR_FATAL
}

is_command_present() {
  puts "Checking presence of the command: $1"
  
  CMD=`whereis -b $1 | awk '{ print $2 }'`
  [ -n "$CMD" ] && return 0 || return 1
}

detect_os() {
  puts "Detecting distrib ID..."

  is_command_present "lsb_release"
  if [ $? -eq 0 ]; then
    puts "LSB info: `lsb_release -a`"
    DISTRIB_ID=`lsb_release -si`
    return 0
  fi
  
  [ -f /etc/redhat-release ] && DISTRIB_ID="RedHat"  
  [ -f /etc/fedora-release ] && DISTRIB_ID="Fedora"
  [ -f /etc/debian_version ] && DISTRIB_ID="Debian"
}

resolve_deps() {
  puts "Resolving dependencies..."

  if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "Debian" ]; then
    apt-get update
    apt-get -y install ruby rubygems libsqlite3-ruby libopenssl-ruby rake
  fi
  
  if [ "$DISTRIB_ID" = "RedHat" -o "$DISTRIB_ID" = "CentOS" ]; then
    yum -y install ruby
    is_command_present gem
    if [ $? -ne 0 ]; then
      yum -y install ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc
      wget -nc -P /tmp/ $RUBYGEMS_URL
      ARCHIVE_NAME=`echo $RUBYGEMS_URL | sed 's/.\+\///g'`
      DIR_NAME=`echo $ARCHIVE_NAME | sed 's/.tgz//g'`
      tar -C /tmp/ -xzf /tmp/$ARCHIVE_NAME
      ruby /tmp/$DIR_NAME/setup.rb
      rm -f /tmp/$ARCHIVE_NAME
      rm -rf /tmp/$DIR_NAME
    fi

    gem list rake -i
    [ $? -ne 0 ] && gem install rake

    gem list rdoc -i
    [ $? -ne 0 ] && gem install rdoc

    sh -c "$RUBY_SQLITE3_CMD" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      yum -y install sqlite-devel make gcc
      gem install sqlite3
    fi 
  fi
  
  if [ "$DISTRIB_ID" = "Fedora" ]; then
    yum -y install ruby rubygems ruby-sqlite3 rubygem-rake
  fi
}

check_environment() {
  puts "Checking environment..."
  
  [ "`whoami`" != "root" ] && fatal_error "Installer should be executed under root user."
  
  puts "System info: `uname -a`"
  
  detect_os
  [ "x$DISTRIB_ID" != "x" ] && puts "Detected distrib ID: $DISTRIB_ID"
  
  detect_openvz
}

check_dependencies() {
  [ "x$AUTOSOLVER" = "x1" ] && resolve_deps

  is_command_present ruby
  if [ $? -eq 0 ]; then
    RUBY_VERSION=`ruby -v | awk '{ print $2 }'`
    if [ "1.8" != "`echo $RUBY_VERSION | awk -F. '{ print $1"."$2 }'`" ]; then
      fatal_error "Panel requires Ruby 1.8 (Ruby 1.9 is not supported)."
    fi
    if [ `echo $RUBY_VERSION | awk -F. '{ print $3 }'` -lt 5 ]; then
      fatal_error "Panel requires Ruby 1.8.5 or higher."
    fi
    puts "Ruby version: $RUBY_VERSION"
  else
    fatal_error "Ruby 1.8 is not installed. Please install it first."
  fi
  
  is_command_present gem
  if [ $? -eq 0 ]; then
    puts "RubyGems version: `gem -v`"
  else
    fatal_error "RubyGems is not installed. Please install it first."
  fi
  
  puts "Checking Ruby SQLite3 support: $RUBY_SQLITE3_CMD"
  sh -c "$RUBY_SQLITE3_CMD" > /dev/null 2>&1
  [ $? -ne 0 ] && fatal_error "Ruby SQLite3 support not found. Please install it first."

  puts_spacer
}

detect_openvz() {
  if [ -f /proc/vz/version ]; then
    ENVIRONMENT="HW-NODE"
    puts "OpenVZ hardware node detected."
  elif [ -d /proc/vz ]; then
    ENVIRONMENT="VPS"
    puts "OpenVZ virtual environment detected."
  else
    ENVIRONMENT="STANDALONE"
    puts "Standalone environment detected."
  fi
}

install_product() {
  puts "Installation..."
  
  [ -f $INSTALL_DIR/config/database.yml ] && UPGRADE=1
  
  mkdir -p $INSTALL_DIR
  
  if [ -f "$DOWNLOAD_URL" ]; then
    ARCHIVE_NAME=$DOWNLOAD_URL
    puts "Local archive: $ARCHIVE_NAME"
    PRESERVE_ARCHIVE=1
  else
    exec_cmd "Downloading:" "wget -nc -P $INSTALL_DIR $DOWNLOAD_URL"
    [ $? -ne 0 ] && fatal_error "Failed to download distribution." 
    ARCHIVE_NAME="$INSTALL_DIR/"`echo $DOWNLOAD_URL | sed 's/.\+\///g'`
  fi

  EXCLUDE_LIST=""
  if [ "x$UPGRADE" = "x1" ]; then
    EXCLUDE_LIST="--exclude=*.log --exclude=config/database.yml --exclude=db/*.sqlite3"
    [ -f "$INSTALL_DIR/config/certs/server.crt" ] && EXCLUDE_LIST="$EXCLUDE_LIST --exclude=config/certs/*"
    [ -f "$INSTALL_DIR/utils/hw-daemon/certs/server.crt" ] && EXCLUDE_LIST="$EXCLUDE_LIST --exclude=hw-daemon/certs/*"
  fi
  exec_cmd "Unpacking:" "tar --strip 2 -C $INSTALL_DIR -xzf $ARCHIVE_NAME $EXCLUDE_LIST"
  
  if [ "x$PRESERVE_ARCHIVE" != "x1" ]; then
    exec_cmd "Removing downloaded archive:" "rm -f $ARCHIVE_NAME"
  fi
  
  if [ "x$UPGRADE" = "x1" ]; then
    puts "Removing deprecated files..."
    [ -f $INSTALL_DIR/app/controllers/admin_controller.rb ] && rm $INSTALL_DIR/app/controllers/admin_controller.rb
  
    puts "Upgrading database..."
    CURRENT_DIR=`pwd`
    cd $INSTALL_DIR
      rake db:migrate RAILS_ENV="production"
    cd $CURRENT_DIR
    [ $? -ne 0 ] && fatal_error "Failed to upgrade database to new version."

    puts "Syncing physical servers state..."
    ruby $INSTALL_DIR/script/runner -e production "HardwareServer.all.each { |server| server.sync }"

    puts "Reset remember_me tokens..."
    ruby $INSTALL_DIR/script/runner -e production "User.all.each{ |user| user.remember_token = ''; user.save }"
  fi
  
  [ ! -x $INSTALL_DIR/script/owp ] && chmod +x $INSTALL_DIR/script/owp
  
  if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "Debian" -o "$DISTRIB_ID" = "RedHat" -o "$DISTRIB_ID" = "CentOS" -o "$DISTRIB_ID" = "Fedora" ]; then
    cp $INSTALL_DIR/script/owp /etc/init.d/owp
    chmod 755 /etc/init.d/owp
    if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "Debian" ]; then
      update-rc.d -f owp remove
      update-rc.d owp defaults 30
    else
      /sbin/chkconfig --add owp
    fi
  fi

  if [ -f $INSTALL_DIR/script/owp.cron -a -d /etc/cron.daily ]; then
    cp $INSTALL_DIR/script/owp.cron /etc/cron.daily/owp.cron
    chmod 755 /etc/cron.daily/owp.cron
  fi 
  
  if [ -f $INSTALL_DIR/config/owp.conf.sample -a ! -f /etc/owp.conf ]; then
    cp $INSTALL_DIR/config/owp.conf.sample /etc/owp.conf
    sed -i "s|^INSTALL_DIR=.*|INSTALL_DIR=$INSTALL_DIR|g" /etc/owp.conf
  fi
  
  puts "Installation finished."
  puts "Product was installed into: $INSTALL_DIR"  
  puts_spacer
}

stop_services() {
  puts "Stopping services..."
  
  $INSTALL_DIR/script/owp stop
}

start_services() {
  [ "x$UPGRADE" = "x1" ] && stop_services

  puts "Starting services..."
  
  if [ "x$UPGRADE" = "x0" ]; then
    if [ "$ENVIRONMENT" = "HW-NODE" ]; then
      HW_DAEMON_CONFIG="$INSTALL_DIR/utils/hw-daemon/hw-daemon.ini"
      if [ ! -f $HW_DAEMON_CONFIG ]; then
        echo "address = 127.0.0.1" >> $HW_DAEMON_CONFIG
        echo "port = 7767" >> $HW_DAEMON_CONFIG
        RAND_KEY=`head -c 200 /dev/urandom | md5sum | awk '{ print \$1 }'`
        echo "key = $RAND_KEY" >> $HW_DAEMON_CONFIG
      fi
      $INSTALL_DIR/script/owp start
      puts "Adding localhost to the list of controlled servers..."
      ruby $INSTALL_DIR/script/runner -e production "HardwareServer.new(:host => 'localhost', :auth_key => '$RAND_KEY').connect"
      [ $? -ne 0 ] && puts "Failed to add local server."
    else
      $INSTALL_DIR/script/owp start
      puts "Place hardware daemon on machine with OpenVZ."
      puts "To start hardware daemon run:"
      puts "sudo ruby $INSTALL_DIR/utils/hw-daemon/hw-daemon.rb start"
    fi
  else
    $INSTALL_DIR/script/owp start
  fi
}

print_access_info() {
  puts "Panel should be available at:"
  puts "http://`hostname -f`:3000"
  puts "Default credentials: admin/admin"
}

uninstall_product() {
  if [ ! -d "$INSTALL_DIR" -o "$INSTALL_DIR" = "" -o "$INSTALL_DIR" = "/" ]; then
    puts "Panel not found. Nothing to uninstall."
    return 1
  fi
  
  stop_services
  rm -rf $INSTALL_DIR
  
  if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "Debian" ]; then
    update-rc.d -f owp remove
  elif [ "$DISTRIB_ID" = "RedHat" -o "$DISTRIB_ID" = "CentOS" -o "$DISTRIB_ID" = "Fedora" ]; then
    /sbin/chkconfig --del owp
  fi
  
  [ -f /etc/owp.conf ] && rm /etc/owp.conf
  [ -f /etc/init.d/owp ] && rm /etc/init.d/owp
  [ -f /etc/cron.daily/owp.cron ] && rm /etc/cron.daily/owp.cron
  
  puts "Panel was uninstalled."
}

main() {
  puts_separator
  puts "OpenVZ Web Panel Installer."
  puts_separator
  
  check_environment
  
  if [ "x$UNINSTALL" = "x1" ]; then
    uninstall_product
  else
    check_dependencies
    install_product
    start_services
    print_access_info
    puts_separator
  fi
}

main

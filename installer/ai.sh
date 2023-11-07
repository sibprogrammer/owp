#!/bin/sh

# global variables
VERSION="2.4"
DOWNLOAD_URL="http://owp.softunity.com.ru/download/ovz-web-panel-$VERSION.tgz"
RUBYGEMS_URL="http://production.cf.rubygems.org/rubygems/rubygems-1.3.5.tgz"
RUBY_SQLITE3_CMD="ruby -e \"require 'rubygems'\" -e \"require 'sqlite3'\""
LOG_FILE="/tmp/ovz-web-panel.log"
INSTALL_DIR="/opt/ovz-web-panel/"
FORCE=0 # force installation to the same directory
PRESERVE_ARCHIVE=0
AUTOSOLVER=1 # automatic solving of dependencies

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

  # Ensure the OS is compatible with the launcher
if [ -f /etc/almalinux-release ]; then
    OS="Alma Linux"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 8
elif [ -f /etc/fedora-release ]; then
    OS="Fedora"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)
    VER=${VERFULL:0:2}
elif [ -f /etc/gentoo-release ]; then
    OS="Gentoo"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)
    VER=${VERFULL:0:2}
elif [ -f /etc/SuSE-release ]; then
    OS="OpenSUSE"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)
    VER=${VERFULL:0:3}
elif [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 8
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/os-release ]; then
    OS=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    VER=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/')
 else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "Detected : $OS  $VER  $ARCH"
}

resolve_deps() {
  puts "Resolving dependencies..."

  if [ "$OS" = "Ubuntu" -o "$OS" = "debian" ]; then
    apt-get update
    apt-get -y install ruby1.8 rubygems libsqlite3-ruby libruby1.8  rake
  fi

  if [ "$OS" = "RedHat" -o "$OS" = "CentOS" ]; then
    if [ "$VER" = "6" ]; then
      yum -y install ruby ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc rubygems rubygem-rake
    fi
    if [ "$VER" = "7" ]; then
      yum -y remove ruby ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc rubygems
      yum -y remove ruby193-ruby ruby193-ruby-devel  ruby193-ruby-docs ruby193-ruby-ri ruby193-ruby-irb ruby193-ruby-rdoc ruby193-rubygems
      wget -O /etc/yum.repos.d/amidevous-ruby187-epel-7.repo https://copr.fedorainfracloud.org/coprs/amidevous/ruby187/repo/epel-7/amidevous-ruby187-epel-7.repo
      yum -y install ruby187-ruby ruby187-ruby-devel ruby187-ruby-docs ruby187-ruby-ri ruby187-ruby-irb ruby187-ruby-rdoc ruby187-rubygems ruby187-rubygem-rake
    fi

    gem sources -r http://gems.rubyforge.org/
    gem sources -r https://gems.rubyforge.org/
    gem sources -a https://rubygems.org/

    gem list rake -i
    [ $? -ne 0 ] && gem install rake

    gem list rdoc -i
    [ $? -ne 0 ] && gem install rdoc

    sh -c "$RUBY_SQLITE3_CMD" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      yum -y install sqlite-devel make gcc
      gem install sqlite3 -v 1.3.13
    fi
  fi

  if [ "$OS" = "Fedora" ]; then
    yum -y install ruby rubygems ruby-sqlite3 rubygem-rake
  fi
}

check_environment() {
  puts "Checking environment..."

  [ "`whoami`" != "root" ] && fatal_error "Installer should be executed under root user."

  puts "System info: `uname -a`"

  detect_os
  [ "x$OS" != "x" ] && puts "Detected distrib ID: $OS"

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

  if [ "$DISTRIB_ID" = "Ubuntu" -o "$OS" = "debian" -o "$OS" = "RedHat" -o "$OS" = "CentOS" -o "$OS" = "Fedora" ]; then
    cp $INSTALL_DIR/script/owp /etc/init.d/owp
    chmod 755 /etc/init.d/owp
    if [ "$OS" = "Ubuntu" -o "$OS" = "debian" ]; then
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

  if [ "$OS" = "Ubuntu" -o "$OS" = "debian" ]; then
    update-rc.d -f owp remove
  elif [ "$OS" = "RedHat" -o "$OS" = "CentOS" -o "$OS" = "Fedora" ]; then
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

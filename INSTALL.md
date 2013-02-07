# OpenVZ Web Panel Installation


Table of contents:

1. Introduction
2. Installation of development version
3. Requirements
4. Manual installation the build
5. Installation from Git repository
6. Uninstallation


## 1. Introduction


Most preferable way to install the panel is to use automatic installer.

```bash
wget -O - http://ovz-web-panel.googlecode.com/svn/installer/ai.sh | sh
```

Instructions below should be used only if you can not use automatic installer due to some reason.


## 2. Installation of development version


To be able to test the newest features you can install latest development version.
This build is not suitable for production and should be used only for testing purposes.

```bash
wget -O - http://ovz-web-panel.googlecode.com/svn/installer/ai.sh | \
sh -s DOWNLOAD_URL=http://owp.softunity.com.ru/download/ovz-web-panel-latest.tgz
```


## 3. Requirements


The following software is required to be installed on server with panel:

* Ruby 1.8.7+ (1.9 is not supported)
* RubyGems
* Ruby SQLite3 support

The following software is required to be installed on physical server, which 
will be used for OpenVZ containers:

* OpenVZ kernel
* OpenVZ tools (vzctl, vzlist)
* Ruby 1.8.7+ (1.9 is not supported)


## 4. Manual installation of the build


Place build archive to the server where you plan to run the panel. Move 
build archive content to destination directory, e.g. /opt/ovz-web-panel/.
This can be achived using the following command:

```bash
tar -xzvf ovz-web-panel-X.X.tgz -C /opt/
```

Panel is written on Ruby. So you need to have it to run the panel. Please check
the Ruby version:

```bash
ruby -v
```

If you haven't ruby installed jet it's time to install it. For example on Ubuntu
using apt:

```bash
apt-get install ruby rubygems libsqlite3-ruby
```

To start the panel run the command:

```bash
sudo /opt/ovz-web-panel/script/owp start
# or
/etc/init.d/owp start
```

To shutdown application the following command can be used (be careful):

```bash
sudo /opt/ovz-web-panel/script/owp stop
# or
/etc/init.d/owp stop
```

Then need to place hardware daemon on the server with OpenVZ. There are two
possible scenarios: panel is installed on hardware node or panel is on separate
server. Physical server daemon located at <install-root>/utils/hw-daemon/ 
Copy content of directory to OpenVZ physical server. Then copy 
hw-daemon.ini.sample to hw-daemon.ini. Next step is to generate unique key, 
which will be used for authorization between panel and daemon. Key can be 
generated using the  following command for example:

```bash
head -c 200 /dev/urandom | md5sum
```

Key should be placed to hw-daemon.ini as a value of "key" parameter. Now daemon
can be  started by the command: 

```bash
sudo ruby hw-daemon.rb start
```

Daemon should work under root user to be able to manipulate with containers.

To start the daemon run:

```bash
sudo ruby hw-daemon.rb start
```

Daemon can be stopped using the following command

```bash
sudo ruby hw-daemon.rb stop
```


## 5. Installation from Git repository


You can checkout the source code using the following command:

```bash
git clone https://github.com/sibprogrammer/owp.git
```

File https://github.com/sibprogrammer/owp/blob/master/build/build.sh
contains information on how to prepare working copy.

One of key steps is to create/upgrade database after code update:

```bash
cd /opt/ovz-web-panel/
rake db:migrate RAILS_ENV="production"
```


## 6. Uninstallation


To uninstall the product need to run the command:

```bash
wget -O - http://ovz-web-panel.googlecode.com/svn/installer/ai.sh | sh -s UNINSTALL=1
```

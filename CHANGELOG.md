# Changes

## OpenVZ Web Panel 2.4 (2013-04-04)

This version is a maintenance release. The following items were fixed and/or
added:

* Empty detailed statistics charts.
* HTML entities in German localization.

## OpenVZ Web Panel 2.3 (2013-02-23)

This version is a maintenance release. The following items were fixed and/or
added:

* Ability to add IP with subnet mask (issue 472).
* Support for big VEID numbers (issue 494).
* Security improvements.

## OpenVZ Web Panel 2.2 (2013-02-09)

This version is a maintenance release. The following items were fixed and/or
added:

* Ability to remove virtual server even if root dir is broken (issue 393).
* Fix problem with container cloning (issue 476).
* Fix non-absolute home error during attempt to connect additional hardware
  servers (issue 416).
* Fix an ability to remove non-existing backup (issue 365).
* Ability to see long names of server and OS templates (issue 478).
* Basic support for scheduled backups (issue 247).
* Add support for vSwap (issue 389).
* Add units support for diskspace limit.
* Ability to use native UI on mobile devices (issue 487).
* Ability to restrict admin access by IP (issue 327).
* Protection against Rails vulnerabilities (issue 485).
* Errors during big server template creation (issue 453).
* Fix an ability to create OS template based on virtual server.

## OpenVZ Web Panel 2.1 (2012-05-02)

This version is a maintenance release. The following items were fixed and/or
added:

* Ability to auto-assign first free IP during VE creation.
* Integration with Travis CI (more stable development builds).
* Workaround for loading mask problem in Firefox (issue 415).
* Stop running background tasks on panel stop (issue 203).
* Init scripts output improvements.
* Better process status control for watchdog.
* Better process status control for hw-daemon.
* Fix problem with running two backups in the same time (issue 412).
* Ability to use panel inside subdirectory.
* Ability to customize sender name in emails (issue 377).
* All translations completeness.
* Use native interface for iPad (issue 343).
* Better escaping of shell parameters (issue 239).
* Final migration to git repo on GitHub.
* Fix problem with watchdog: do not fail if physical server have more VEs than
  panel knows (issue 351).
* Proper creation of VE from template via API.
* Fix problem with VE stats fetching (undefined method pluralize, issue 298).
* Detect vzctl utility path in case of compilation from sources (issue 305).

## OpenVZ Web Panel 2.0 (2011-04-17)

This version is a major release. The following items were fixed and/or added:

* Ability to control using Remote API (issue 191).
* WHMCS (billing system) support (issue 249).
* IP addresses management (issue 132).
* Automatic sync of virtual server state (issue 262).
* Virtual server migration between physical servers (issue 99).
* Ability to create template based on virtual server (issue 125).
* Fixed FloatDomainError on virtual server details screen (issue 254).
* Spanish language support (issue 252).
* Ukraine language support.
* Android OS basic support (issue 243).
* Avoid writing plains passwords to production.log (issue 238).
* Ability to set swappages (issue 237).
* Ability to limit number of backups (issue 236).
* Preserve SSL certificates on upgrade (issue 229).
* Ability to see more than 15 connected physical servers (issue 225).
* Show free RAM including buffers/cache (issue 221).
* IP address field was added to events log (issue 210).
* E-mail notifications on requests (issue 206).
* Offline installer (issue 204).
* Optional root password for virtual server (issue 196).
* Ability to restore user password (issue 189).
* LDAP authentication support (issue 176).
* Ability to see OS template size (issue 46).
* Ability to use SSL for communication with physical servers (issue 22).

## OpenVZ Web Panel 1.7 (2010-11-23)

This version is a maintenance release. The following items were fixed and/or
added:

* Fix problem with SQLite3::BusyException: database is locked (issue 211).
* Ability to use MySQL for backend (issue 212).
* Make IP address for virtual server an optional field (issue 216).
* Fix problem with virtual server statistics page if server is out of sync
  (issue 118).
* Fix problems with expiration dates on CentOS (issue 217). 

## OpenVZ Web Panel 1.6 (2010-11-07)

This version is a major release. The following items were fixed and/or added:

* Show local dates and time with timezone correction in UI (issue 195).
* Proper detection of upgrade and re-installation cases (issue 186).
* Ability to suspend virtual server during backup instead of stopping it
  (issue 183).
* Make IP address an optional field (182).
* Upgrade to ExtJS 3.2.1 (issue 181).
* Support of unlimited values for limits (issue 180).
* Limit updates checking procedure to avoid freeze of dashboard if internet
  connection is not allowed (issue 174).
* Customizable user roles (issue 168).
* Login/logout attempts tracking (issue 167).
* Ability for user to change OS (issue 160).
* Use first server template if config points to non-existent template
  (issue 159).
* Ability to disable user (issue 155).
* Add email field for user (issue 154).
* Add contact name field for user (issue 153).
* Ability to select text for copying for Firefox and Chrome (issue 151).
* Japanese language support (issue 148).
* Use passive FTP mode for OS templates downloading by default (issue 145).
* Ability to set default language (issue 143).
* French language support (issue 141).
* Simple QOS alerts and charts (issue 98).
* Expiration date for virtual server (issue 96).
* Requests tracking system (issue 87).
* Ability to connect additional hardware servers using root shell access
  (issue 74).
* Ability to clone virtual server (issue 48).

## OpenVZ Web Panel 1.5 (2010-07-31)

This version is a major release. The following items were fixed and/or added:

* Ability to backup/restore virtual server (issue 38). 
* Limited iPhone support (issue 69).
* CPU, HDD and RAM usage information for virtual server (issue 118).
* CPU, HDD and RAM usage information for physical server (issue 131).
* Fixed incorrect handling of othersockbuf limit (issue 142).
* Improved detection of supported Ruby version during installation
  (issue 138).
* Improved the speed of loading the pages with lists (issue 136).
* IPv6 compatibility (issue 135).
* Portuguese (Brazilian) language support (issue 133).
* Fixed problem with vzctl/vzlist utilities search path (issue 130).
* Improved stability of import existing containers procedure (issue 129).
* Fixed problem with password change by user (issue 126).
* Ability to set CPU and CPULIMIT settings for virtual server (issue 123).
* Increased default timeout to allow installation of servers on big templates
  (issue 122).
* Ability to set admin as virtual server owner (issue 121)
* Native support for virtul server descriptions (issue 117).
* Fixed problem with OS reinstallation and empty properties (issue 114).
* Search for virtual server (issue 109).
* Ability to install template from URL (issue 108).
* Ability to select OS template on reinstall (issue 105).
* Simple shell for virtual server (issue 97).
* Ability to reboot physical server (issue 95).
* Ability to customize support link (issue 75).
* Ability to use ExtJS libs available at CacheFly (issue 26).
* Ability to set HW daemon port during connecting new HW node (issue 21).

## OpenVZ Web Panel 1.1 (2010-05-23)

This version is a maintenance release. The following items were fixed and/or
added:

* Proper handling of maximum limits numbers (issue 111).
* Fixed deletion of VPS if imposible to update some parameter (issue 112).
* Allowed to sync virtual servers with same IPs or without them (issue 110).
* Added "Change settings" dialog to virtual server overview page (issue 104).
* Ability to uninstall the panel (issue 102).
* Romanian language support (issue 94).
* Ability to set hostname and root password by virtual server owner (issue 92).
* Proper message about virtual server update in event log (issue 86).
* Ability to reinstall virtual server (issue 45).

## OpenVZ Web Panel 1.0 (2010-04-18)

This version is a major release. The following items were fixed and/or added:

* Updated and new icons for pages and operations (issue 81).
* Hungarian language support (issue 80).
* Automatic synchronization of the state on panel startup (issue 78).
* Limit number of record at events log and tasks via configuation (issue 77).
* Added upstart scripts (issue 73).
* OS templates counter was removed from statistics panel at dashboard (issue 72).
* Added administrator's and user's guides (issue 71).
* Added ability to set description for virtual server (issue 70).
* Improved backend errors detection and reporting (issue 67).
* Corrected dependencies solver for CentOS 5.4 (issue 66).
* Fixed 404 error (page not found) after login (issue 65).
* Access OS templates remote list using FTP passive mode (issue 64).

## OpenVZ Web Panel 0.9 (2010-03-29)

This version is a beta release. The following items were fixed and/or added:

* Ability to see/change virtual server advanced limits (issue 63).
* Improved visualisation of OS template installation process (issue 62).
* Ability to clear log (issue 61).
* Fixed redirect on original page after clicking Help link (issue 60). 
* Detect default OS template for new server creation (issue 59).
* Prohibit attempts to use Ruby 1.9 (issue 58).
* Redirect to dashboard in case of invalid URL access (issue 57).
* German language support (issue 56).
* Virtual server templates management was introduced (issue 55).
* Support multiple IPs for virtual server (issue 54).
* Support multiple nameservers for virtual server (issue 53).
* Show OS template size at installation dialog (issue 51).
* Clear password field after attempt to login using invalid password
  (issue 50).
* Allow two characters logins for users (issue 43).
* Translation of too_short validation message on user creation (issue 42).
* Roles for users were introduced (issue 40).
* Virtual server details screen (issue 39).
* Store panels states at Dashboard (issue 37).
* Prohibit ability to delete admin user (issue 36).
* Proper detection of OS templates directory on Debian/Ubuntu (issue 19).

## OpenVZ Web Panel 0.6 (2010-01-30)

This version is a preview release. The following items were fixed and/or added:

* Ability to upgrade the panel using auto installer (issue 30).
* Ability to create panel users (issue #20).
* Ability to install OS templates from mirrors (issue 23).
* Start/stop script for the panel (issue 29).
* Redesing of virtual server creation form.
* Ability to specify diskspace and memory for virtual server (issue 34).
* Fixed validation of password on virtual server creation form (issue 10).
* Notifications about new versions availability (issue 41).


## OpenVZ Web Panel 0.5 (2009-12-31)

This version is a preview release. The following items were fixed and/or added:

* Ability to synchronize physical server state (issue 13).
* Ability to update physical server connection settings (issue 17).
* Ability to see log of events.
* Ability to remove OS template (issue 24).
* Automatic installer (issue 25).
* Dutch language support (issue 32).
* New icons for showing of virtual server state (issue 33). 
* Fixed issue with wrong OS template detection (issue 27).
* Ext JS was upgraded to version 3.1.0.


## OpenVZ Web Panel 0.4 (2009-12-19)

This version is a preview release. The following items were fixed and/or added:

* Project was rewritten from scratch using Ruby on Rails.
* Ext JS was upgraded to version 3.0.0.
* Pages shortcuts functionality was dropped.
* Improved error handling on connecting of physical server (issue 11,
  issue 14, issue 15). 
* Correct state of virtual servers after connecting of physical server 
  (issue 9).
* Ability to install OS template (issue 18).


## OpenVZ Web Panel 0.3 (2009-09-17)

Initial public release. The following items were fixed and/or added:

* Publication of source codes due to users requests after one year of the
  project's freeze.
* Server-side code is based on Zend Framework 1.6.0.
* Client-side code is based on Ext JS 2.2.
* Separate physical server daemon.
* Ability to control several physical servers.
* Ability to create/delete virtual servers.
* Ability to see list of available OS templates.
* Ability to create shortcut to the page and see it on dashboard.


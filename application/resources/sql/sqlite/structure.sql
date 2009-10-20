BEGIN TRANSACTION;

CREATE TABLE users (
	id INTEGER NOT NULL PRIMARY KEY autoincrement,
	userName VARCHAR(255) UNIQUE NOT NULL,
	userPassword CHAR(32) NOT NULL,
	roleId INTEGER NOT NULL
);
INSERT INTO "users" VALUES(1, 'admin', '21232f297a57a5a743894a0e4a801fc3', 1);

CREATE TABLE hwServers (
	id INTEGER NOT NULL PRIMARY KEY autoincrement,
	hostName VARCHAR(255) UNIQUE NOT NULL,
	authKey VARCHAR(255) NOT NULL,
	description VARCHAR(255) NULL
);

CREATE TABLE virtualServers (
	id INTEGER NOT NULL PRIMARY KEY autoincrement,
	veId INTEGER NOT NULL,
	ipAddress VARCHAR(255) NULL,
	hostName VARCHAR(255) NULL,
	veState INTEGER NOT NULL,
	hwServerId INTEGER NOT NULL,
	osTemplateId INTEGER NOT NULL
);

CREATE TABLE osTemplates (
	id INTEGER NOT NULL PRIMARY KEY autoincrement,
	name VARCHAR(255) NOT NULL,
	hwServerId INTEGER NOT NULL
);

CREATE TABLE shortcuts (
	id INTEGER NOT NULL PRIMARY KEY autoincrement,
	name VARCHAR(255) NOT NULL,
	link VARCHAR(255) NOT NULL
);
INSERT INTO "shortcuts" VALUES(1, 'Hardware servers', '/admin/hardware-server/list');

COMMIT;

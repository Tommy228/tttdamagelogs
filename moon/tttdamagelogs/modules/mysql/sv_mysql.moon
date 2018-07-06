require("mysqloo")

include("sv_mysql_config.lua")

db = mysqloo.connect(mysql_config.host, mysql_config.username, mysql_config.password, mysql_config.db_name, mysql_config.db_port)

queuedQueries = {
    "CREATE TABLE IF NOT EXISTS `damagelogs_players`
    (
        `id`      INT(11) NOT NULL auto_increment,
        `steamid` VARCHAR(25) NOT NULL,
        `name`    VARCHAR(40) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `steamid` (`steamid`)
    );",

    "CREATE TABLE IF NOT EXISTS `damagelogs_punish`
    (
        `id`           INT(11) NOT NULL auto_increment,
        `date`         BIGINT(20) NOT NULL,
        `punishmentid` INT(11) NOT NULL,
        `player`       VARCHAR(25) NOT NULL,
        `reason`       TEXT NOT NULL,
        PRIMARY KEY (`id`),
        KEY `punishmentid` (`punishmentid`)
    )"
}

nextQuery = ->
    if #queuedQueries > 0
        currentQuery = queuedQueries[1]
        query = db\query(currentQuery)
        table.remove(queuedQueries, 1)
        query.onSuccess = nextQuery
        query\start!
    else
        dmglog.db = db

db.onConnected = (self) ->
    nextQuery!

db\setMultiStatements(true)
db\connect!
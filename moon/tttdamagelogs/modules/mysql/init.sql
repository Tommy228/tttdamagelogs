CREATE TABLE IF NOT EXISTS `damagelogs_players`
(
    `id`      INT(11) NOT NULL auto_increment,
    `steamid` VARCHAR(25) NOT NULL,
    `name`    VARCHAR(40) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `steamid` (`steamid`)
);

CREATE TABLE IF NOT EXISTS `damagelogs_punish`
(
    `id`           INT(11) NOT NULL auto_increment,
    `date`         BIGINT(20) NOT NULL,
    `punishmentid` INT(11) NOT NULL,
    `player`       VARCHAR(25) NOT NULL,
    `reason`       TEXT NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`player`) REFERENCES damagelogs_players(id)
);
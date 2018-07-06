CREATE TABLE IF NOT EXISTS `damagelogs_players`
(
    `id`      INT NOT NULL AUTO_INCREMENT,
    `steamid` VARCHAR(25) NOT NULL,
    `name`    VARCHAR(40) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `steamid` (`steamid`)
);

CREATE TABLE IF NOT EXISTS `damagelogs_punish`
(
    `id`           INT NOT NULL AUTO_INCREMENT,
    `date`         BIGINT NOT NULL,
    `punishmentid` INT NOT NULL,
    `player`       INT NOT NULL,
    `reason`       TEXT NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`player`) REFERENCES damagelogs_players(id)
);
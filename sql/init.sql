CREATE TABLE IF NOT EXISTS `damagelogs_players`
(
    `id`      INT NOT NULL AUTO_INCREMENT,
    `steamid` VARCHAR(25) NOT NULL,
    `name`    VARCHAR(40) NOT NULL,
    PRIMARY KEY (`id`),
    KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `damagelogs_punish`
(
    `id`           INT NOT NULL AUTO_INCREMENT,
    `date`         BIGINT NOT NULL,
    `punishmentid` INT NOT NULL,
    `player`       INT NOT NULL,
    `reason`       VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`player`) REFERENCES damagelogs_players(id)
);

DROP FUNCTION IF EXISTS player_exists;
CREATE FUNCTION player_exists
  (in_steamid VARCHAR(25))
RETURNS BOOL
READS SQL DATA
BEGIN
   DECLARE playerExists BOOL;
   SET playerExists = (SELECT EXISTS (SELECT 1 FROM damagelogs_players WHERE steamid = in_steamid LIMIT 1));
   RETURN playerExists;
END;

DROP PROCEDURE IF EXISTS on_player_join;
CREATE PROCEDURE on_player_join
    (IN in_steamid VARCHAR(25), in_name VARCHAR(40))
BEGIN
    DECLARE playerExists BOOL;
    SET playerExists = player_exists(in_steamid);
    SELECT playerExists;
    IF (NOT playerExists) THEN
        BEGIN
            INSERT INTO damagelogs_players(steamid, name) VALUES (in_steamid, in_name);
        END;
    ELSE
        BEGIN
            UPDATE damagelogs_players SET name = in_name WHERE steamid = in_steamid;
        END;
    END IF;
END;
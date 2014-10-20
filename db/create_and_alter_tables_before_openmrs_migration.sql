#add SD role
INSERT INTO user_role VALUES (1, 'System Developer');
INSERT INTO user_role VALUES (1, 'Provider');

UPDATE users SET username = 'admin' ,password = '4a1750c8607d0fa237de36c6305715c223415189' ,salt = 'c788c6ad82a157b712392ca695dfcf2eed193d7f' WHERE user_id = 1;

DELETE FROM user_role WHERE user_id = 2;
DELETE FROM users WHERE user_id = 2;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS location_tag_map;
DROP TABLE IF EXISTS location;
CREATE TABLE `location` (
  `location_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) DEFAULT NULL,
  `address1` varchar(50) DEFAULT NULL,
  `address2` varchar(50) DEFAULT NULL,
  `city_village` varchar(50) DEFAULT NULL,
  `state_province` varchar(50) DEFAULT NULL,
  `postal_code` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `latitude` varchar(50) DEFAULT NULL,
  `longitude` varchar(50) DEFAULT NULL,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `county_district` varchar(50) DEFAULT NULL,
  `neighborhood_cell` varchar(50) DEFAULT NULL,
  `region` varchar(50) DEFAULT NULL,
  `subregion` varchar(50) DEFAULT NULL,
  `township_division` varchar(50) DEFAULT NULL,
  `retired` tinyint(1) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `retire_reason` varchar(255) DEFAULT NULL,
  `location_type_id` int(11) DEFAULT NULL,
  `parent_location` int(11) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`location_id`),
  UNIQUE KEY `location_uuid_index` (`uuid`),
  KEY `user_who_created_location` (`creator`),
  KEY `name_of_location` (`name`),
  KEY `user_who_retired_location` (`retired_by`),
  KEY `retired_status` (`retired`),
  KEY `type_of_location` (`location_type_id`),
  KEY `parent_location` (`parent_location`),
  CONSTRAINT `location_type` FOREIGN KEY (`location_type_id`) REFERENCES `location_type` (`location_type_id`),
  CONSTRAINT `parent_location` FOREIGN KEY (`parent_location`) REFERENCES `location` (`location_id`),
  CONSTRAINT `user_who_created_location` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_retired_location` FOREIGN KEY (`retired_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

ALTER TABLE `location` DROP COLUMN `parent_location_id`; 
ALTER TABLE `location` DROP INDEX  `parent_location_for_location` ;
ALTER TABLE `location` DROP FOREIGN KEY `parent_location`;
ALTER TABLE `location` DROP COLUMN `parent_location_id`, DROP INDEX `parent_location_for_location` ;

SET FOREIGN_KEY_CHECKS = 1;
ALTER TABLE `hl7_in_archive` ADD COLUMN `message_state` INT(1)  AFTER `hl7_data` ;

DELETE FROM encounter WHERE encounter_type IS NULL;


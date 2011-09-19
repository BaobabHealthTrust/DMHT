--
-- Table structure for table `regimen_tag`
--

DROP TABLE IF EXISTS `regimen_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen_tag` (
  `regimen_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `retire_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`regimen_tag_id`),
  UNIQUE KEY `regimen_tag_uuid_index` (`uuid`),
  KEY `regimen_tag_creator` (`creator`),
  KEY `regimen_tag_retired_by` (`retired_by`),
  CONSTRAINT `regimen_tag_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `regimen_tag_retired_by` FOREIGN KEY (`retired_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen_tag`
--

LOCK TABLES `regimen_tag` WRITE;
/*!40000 ALTER TABLE `regimen_tag` DISABLE KEYS */;
/*!40000 ALTER TABLE `regimen_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regimen_tag_map`
--



DROP TABLE IF EXISTS `regimen_tag_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen_tag_map` (
  `regimen_id` int(11) NOT NULL,
  `regimen_tag_id` int(11) NOT NULL,
  PRIMARY KEY (`regimen_id`,`regimen_tag_id`),
  KEY `regimen_tag_map_tag` (`regimen_tag_id`),
  CONSTRAINT `regimen_tag_map_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`),
  CONSTRAINT `regimen_tag_map_tag` FOREIGN KEY (`regimen_tag_id`) REFERENCES `regimen_tag` (`regimen_tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen_tag_map`
--

LOCK TABLES `regimen_tag_map` WRITE;
/*!40000 ALTER TABLE `regimen_tag_map` DISABLE KEYS */;
/*!40000 ALTER TABLE `regimen_tag_map` ENABLE KEYS */;
UNLOCK TABLES;


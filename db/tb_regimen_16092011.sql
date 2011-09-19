-- MySQL dump 10.13  Distrib 5.1.54, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: openmrs17
-- ------------------------------------------------------
-- Server version	5.1.54-1ubuntu4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `regimen`
--

DROP TABLE IF EXISTS `regimen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen` (
  `regimen_id` int(11) NOT NULL AUTO_INCREMENT,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `regimen_index` int(2) NOT NULL DEFAULT '0' COMMENT 'To keep the index for the regimen',
  `min_weight` int(3) NOT NULL DEFAULT '0',
  `max_weight` int(3) NOT NULL DEFAULT '200',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `program_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`regimen_id`),
  KEY `map_concept` (`concept_id`),
  CONSTRAINT `map_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen`
--

LOCK TABLES `regimen` WRITE;
/*!40000 ALTER TABLE `regimen` DISABLE KEYS */;
INSERT INTO `regimen` VALUES (11,2984,6,35,200,1,'2011-06-20 17:59:01',0,NULL,NULL,1),(13,7921,9,0,6,1,'2011-06-20 19:01:12',0,NULL,NULL,1),(14,7921,9,6,10,1,'2011-06-20 19:01:54',0,NULL,NULL,1),(15,7921,9,10,14,1,'2011-06-20 19:02:07',0,NULL,NULL,1),(16,7921,9,14,20,1,'2011-06-20 19:02:16',0,NULL,NULL,1),(17,7921,9,20,25,1,'2011-06-20 19:02:24',0,NULL,NULL,1),(18,7921,9,25,30,1,'2011-06-20 19:02:31',0,NULL,NULL,1),(19,7921,9,30,35,1,'2011-06-20 19:02:43',0,NULL,NULL,1),(20,794,0,0,4,1,'2011-06-20 19:12:10',1,NULL,NULL,1),(21,794,0,4,6,1,'2011-06-20 19:14:20',1,NULL,NULL,1),(22,794,0,6,14,1,'2011-06-20 19:17:03',1,NULL,NULL,1),(23,794,0,14,25,1,'2011-06-20 19:19:43',1,NULL,NULL,1),(24,794,0,25,35,1,'2011-06-20 19:19:59',1,NULL,NULL,1),(25,794,0,35,200,1,'2011-06-20 19:20:26',1,NULL,NULL,1),(26,792,1,0,6,1,'2011-06-20 20:09:24',0,NULL,NULL,1),(27,792,1,6,10,1,'2011-06-20 20:11:43',0,NULL,NULL,1),(28,792,1,10,14,1,'2011-06-20 20:12:37',0,NULL,NULL,1),(29,792,1,14,20,1,'2011-06-20 20:12:48',0,NULL,NULL,1),(30,792,1,20,25,1,'2011-06-20 20:13:22',0,NULL,NULL,1),(31,792,1,25,200,1,'2011-06-20 20:13:44',0,NULL,NULL,1),(32,1610,2,0,6,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(33,1610,2,6,10,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(34,1610,2,10,14,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(35,1610,2,14,20,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(36,1610,2,20,25,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(37,1610,2,25,200,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(38,1613,3,10,14,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(39,1613,3,14,20,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(40,1613,3,20,25,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(41,1613,3,25,40,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(42,1613,3,40,200,1,'2011-06-20 21:07:39',0,NULL,NULL,1),(43,1612,4,10,14,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(44,1612,4,14,20,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(45,1612,4,20,25,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(46,1612,4,25,40,1,'2011-06-20 21:20:58',0,NULL,NULL,1),(47,1612,4,40,200,1,'2011-06-20 21:20:58',0,NULL,NULL,1),(48,2985,5,35,200,1,'2011-06-20 21:47:38',0,NULL,NULL,1),(49,7923,7,35,200,1,'2011-06-20 21:47:38',0,NULL,NULL,1),(50,2994,8,35,200,1,'2011-06-20 22:01:12',0,NULL,NULL,1),(51,916,0,0,200,1,'2011-06-22 17:28:12',0,NULL,NULL,0),(52,656,0,0,200,1,'2011-06-22 17:28:42',0,NULL,NULL,0),(53,7993,10,0,5,1,'2011-08-15 14:53:35',0,NULL,NULL,1),(54,7993,10,5,8,1,'2011-08-15 14:55:34',0,NULL,NULL,1),(55,7993,10,8,12,1,'2011-08-15 14:55:41',0,NULL,NULL,1),(56,7993,10,12,14,1,'2011-08-15 14:55:50',0,NULL,NULL,1),(57,7993,10,14,19,1,'2011-08-15 14:56:07',0,NULL,NULL,1),(58,7993,10,19,26,1,'2011-08-15 14:56:20',0,NULL,NULL,1),(59,7993,10,26,30,1,'2011-08-15 14:56:44',0,NULL,NULL,1),(60,7993,10,30,200,1,'2011-08-15 14:56:55',0,NULL,NULL,1),(62,7994,11,0,6,1,'2011-08-15 15:46:57',0,NULL,NULL,1),(63,7994,11,6,10,1,'2011-08-15 15:47:15',0,NULL,NULL,1),(64,7994,11,10,14,1,'2011-08-15 15:47:23',0,NULL,NULL,1),(65,7994,11,14,20,1,'2011-08-15 15:47:36',0,NULL,NULL,1),(66,7994,11,20,25,1,'2011-08-15 15:47:48',0,NULL,NULL,1),(67,7994,11,25,30,1,'2011-08-15 15:48:02',0,NULL,NULL,1),(68,1131,-1,30,38,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(69,1131,-1,38,55,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(70,1131,-1,55,75,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(71,1131,-1,75,200,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(72,1194,-1,0,8,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(73,1194,-1,8,10,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(74,1194,-1,10,15,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(75,1194,-1,15,20,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(76,1194,-1,20,25,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(77,1194,-1,25,30,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(78,1194,-1,30,38,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(79,1194,-1,38,55,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(80,1194,-1,55,75,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(81,1194,-1,75,200,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(82,768,-1,0,8,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(83,768,-1,8,10,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(84,768,-1,10,15,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(85,768,-1,15,20,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(86,768,-1,20,25,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(87,768,-1,25,30,1,'2011-08-22 15:57:21',0,NULL,NULL,2),(88,8023,-1,0,8,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(89,8023,-1,8,10,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(90,8023,-1,10,15,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(91,8023,-1,15,20,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(92,8023,-1,20,25,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(93,8023,-1,25,30,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(109,8024,-1,0,8,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(110,8024,-1,8,10,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(111,8024,-1,10,15,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(112,8024,-1,15,20,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(113,8024,-1,20,25,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(114,8024,-1,25,30,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(115,8024,-1,30,38,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(116,8024,-1,38,55,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(117,8024,-1,55,75,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(118,8024,-1,75,200,1,'2011-08-22 15:51:05',0,NULL,NULL,2),(124,8025,-1,0,8,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(125,8025,-1,8,10,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(126,8025,-1,10,15,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(127,8025,-1,15,20,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(128,8025,-1,20,25,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(129,8025,-1,25,30,1,'2011-08-22 16:02:53',0,NULL,NULL,2),(131,8022,-1,30,38,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(132,8022,-1,38,40,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(133,8022,-1,55,56,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(134,8022,-1,75,200,1,'2011-08-22 15:50:44',0,NULL,NULL,2),(138,8022,-1,40,55,1,'2011-08-22 16:02:53',0,NULL,NULL,0),(140,8022,-1,56,75,1,'2011-08-22 16:02:53',0,NULL,NULL,2);
/*!40000 ALTER TABLE `regimen` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regimen_drug_order`
--

DROP TABLE IF EXISTS `regimen_drug_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen_drug_order` (
  `regimen_drug_order_id` int(11) NOT NULL AUTO_INCREMENT,
  `regimen_id` int(11) NOT NULL DEFAULT '0',
  `drug_inventory_id` int(11) DEFAULT '0',
  `dose` double DEFAULT NULL,
  `equivalent_daily_dose` double DEFAULT NULL,
  `units` varchar(255) DEFAULT NULL,
  `frequency` varchar(255) DEFAULT NULL,
  `prn` tinyint(1) NOT NULL DEFAULT '0',
  `complex` tinyint(1) NOT NULL DEFAULT '0',
  `quantity` int(11) DEFAULT NULL,
  `instructions` text,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`regimen_drug_order_id`),
  UNIQUE KEY `regimen_drug_order_uuid_index` (`uuid`),
  KEY `regimen_drug_order_creator` (`creator`),
  KEY `user_who_voided_regimen_drug_order` (`voided_by`),
  KEY `map_regimen` (`regimen_id`),
  KEY `map_drug_inventory` (`drug_inventory_id`),
  CONSTRAINT `map_drug_inventory` FOREIGN KEY (`drug_inventory_id`) REFERENCES `drug` (`drug_id`),
  CONSTRAINT `map_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`),
  CONSTRAINT `regimen_drug_order_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_regimen_drug_order` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=130 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen_drug_order`
--

LOCK TABLES `regimen_drug_order` WRITE;
/*!40000 ALTER TABLE `regimen_drug_order` DISABLE KEYS */;
INSERT INTO `regimen_drug_order` VALUES (1,11,734,1,1,'tab(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 18:07:06',0,NULL,NULL,NULL,'5871aa8e-9b57-11e0-a2a8-544249e49b14'),(2,11,22,1,1,'tab(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 18:10:03',0,NULL,NULL,NULL,'c1e9841e-9b57-11e0-a2a8-544249e49b14'),(3,13,733,1,1,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:05:42',0,NULL,NULL,NULL,'9cf2dc5c-9b5f-11e0-a2a8-544249e49b14'),(4,14,733,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:34',0,NULL,NULL,NULL,'bbdd31da-9b5f-11e0-a2a8-544249e49b14'),(5,15,733,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:43',0,NULL,NULL,NULL,'c0be0594-9b5f-11e0-a2a8-544249e49b14'),(6,16,733,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:51',0,NULL,NULL,NULL,'c5f6d8ba-9b5f-11e0-a2a8-544249e49b14'),(7,17,733,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:07:52',0,NULL,NULL,NULL,'ea47245e-9b5f-11e0-a2a8-544249e49b14'),(8,18,733,4,8,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'4 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:08:26',0,NULL,NULL,NULL,'fe3e09fa-9b5f-11e0-a2a8-544249e49b14'),(9,19,733,4.5,9,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'4.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:08:44',0,NULL,NULL,NULL,'08e77b5c-9b60-11e0-a2a8-544249e49b14'),(10,20,94,1,2,'ml','TWICE A DAY (BD)',0,0,NULL,'1 ml TWICE A DAY (BD)',1,'2011-06-20 19:12:48',0,NULL,NULL,NULL,'9a5311f0-9b60-11e0-a2a8-544249e49b14'),(11,21,94,1.5,3,'ml','TWICE A DAY (BD)',0,0,NULL,'1.5 ml TWICE A DAY (BD)',1,'2011-06-20 19:15:03',0,NULL,NULL,NULL,'eaf9b62c-9b60-11e0-a2a8-544249e49b14'),(12,22,74,1,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) IN THE MORNING (QAM); 1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 19:17:46',0,NULL,NULL,NULL,'4be809a2-9b61-11e0-a2a8-544249e49b14'),(13,23,74,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:18',0,NULL,NULL,NULL,'cad6992c-9b61-11e0-a2a8-544249e49b14'),(14,24,74,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:33',0,NULL,NULL,NULL,'d391dfcc-9b61-11e0-a2a8-544249e49b14'),(15,25,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:58',0,NULL,NULL,NULL,'e2a2808e-9b61-11e0-a2a8-544249e49b14'),(17,26,72,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:15',0,NULL,NULL,NULL,'779820de-9b69-11e0-a2a8-544249e49b14'),(18,27,72,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:41',0,NULL,NULL,NULL,'87015518-9b69-11e0-a2a8-544249e49b14'),(19,28,72,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:53',0,NULL,NULL,NULL,'8e870f12-9b69-11e0-a2a8-544249e49b14'),(20,29,72,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:01',0,NULL,NULL,NULL,'9317b28e-9b69-11e0-a2a8-544249e49b14'),(21,30,72,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:10',0,NULL,NULL,NULL,'984b22ea-9b69-11e0-a2a8-544249e49b14'),(22,31,613,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:19',0,NULL,NULL,NULL,'9e04fc9c-9b69-11e0-a2a8-544249e49b14'),(23,32,732,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:02',0,NULL,NULL,NULL,'4849d91a-9b70-11e0-a2a8-544249e49b14'),(24,33,732,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:07',0,NULL,NULL,NULL,'4b6e7920-9b70-11e0-a2a8-544249e49b14'),(25,34,732,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:14',0,NULL,NULL,NULL,'4f78aab8-9b70-11e0-a2a8-544249e49b14'),(26,35,732,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:19',0,NULL,NULL,NULL,'529da662-9b70-11e0-a2a8-544249e49b14'),(27,36,732,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:24',0,NULL,NULL,NULL,'553b4398-9b70-11e0-a2a8-544249e49b14'),(28,37,731,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:29',0,NULL,NULL,NULL,'589e9fb2-9b70-11e0-a2a8-544249e49b14'),(29,38,737,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:08:33',0,NULL,NULL,NULL,'c6413d54-9b70-11e0-a2a8-544249e49b14'),(30,39,737,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:08:48',0,NULL,NULL,NULL,'cf10797c-9b70-11e0-a2a8-544249e49b14'),(31,40,737,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:02',0,NULL,NULL,NULL,'d73a6360-9b70-11e0-a2a8-544249e49b14'),(32,41,738,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:24',0,NULL,NULL,NULL,'e4a77826-9b70-11e0-a2a8-544249e49b14'),(33,42,738,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:34',0,NULL,NULL,NULL,'ea6a2952-9b70-11e0-a2a8-544249e49b14'),(34,38,30,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:11:41',0,NULL,NULL,NULL,'3603ba36-9b71-11e0-a2a8-544249e49b14'),(35,39,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:12:46',0,NULL,NULL,NULL,'5d1608ea-9b71-11e0-a2a8-544249e49b14'),(36,40,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:13:07',0,NULL,NULL,NULL,'697cb480-9b71-11e0-a2a8-544249e49b14'),(37,41,30,2,2,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:13:36',0,NULL,NULL,NULL,'7b016a84-9b71-11e0-a2a8-544249e49b14'),(38,42,11,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:14:55',0,NULL,NULL,NULL,'a99a2674-9b71-11e0-a2a8-544249e49b14'),(39,43,736,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:22:09',0,NULL,NULL,NULL,'ac8b3e80-9b72-11e0-a2a8-544249e49b14'),(40,44,736,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:22:59',0,NULL,NULL,NULL,'ca6853f2-9b72-11e0-a2a8-544249e49b14'),(41,45,736,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:13',0,NULL,NULL,NULL,'d26327bc-9b72-11e0-a2a8-544249e49b14'),(42,46,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:42',0,NULL,NULL,NULL,'e3e1ee42-9b72-11e0-a2a8-544249e49b14'),(43,47,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:51',0,NULL,NULL,NULL,'e9921c90-9b72-11e0-a2a8-544249e49b14'),(44,43,30,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:24:34',0,NULL,NULL,NULL,'02b48bd6-9b73-11e0-a2a8-544249e49b14'),(45,44,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:03',0,NULL,NULL,NULL,'14415104-9b73-11e0-a2a8-544249e49b14'),(46,45,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:14',0,NULL,NULL,NULL,'1ad02608-9b73-11e0-a2a8-544249e49b14'),(47,46,30,2,2,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:26',0,NULL,NULL,NULL,'223af5b2-9b73-11e0-a2a8-544249e49b14'),(48,47,11,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:27:04',0,NULL,NULL,NULL,'5c4d3f62-9b73-11e0-a2a8-544249e49b14'),(49,48,735,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:48:22',0,NULL,NULL,NULL,'56163b8c-9b76-11e0-a2a8-544249e49b14'),(50,49,734,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:56:18',0,NULL,NULL,NULL,'71b5c6d6-9b77-11e0-a2a8-544249e49b14'),(51,49,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:57:01',0,NULL,NULL,NULL,'8b792b62-9b77-11e0-a2a8-544249e49b14'),(52,50,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 22:01:39',0,NULL,NULL,NULL,'316a6b94-9b78-11e0-a2a8-544249e49b14'),(53,50,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 22:01:51',0,NULL,NULL,NULL,'38797d76-9b78-11e0-a2a8-544249e49b14'),(54,51,297,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-22 17:30:25',0,NULL,NULL,NULL,'8d4a0c18-9ce4-11e0-96f5-544249e49b14'),(55,52,24,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-22 17:31:04',0,NULL,NULL,NULL,'a47c7dd0-9ce4-11e0-96f5-544249e49b14'),(58,53,613,0.25,0.25,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.25 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:12:25',0,NULL,NULL,NULL,'37fdae82-c740-11e0-aac7-544249e49b14'),(59,53,738,0,0,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:16:07',0,NULL,NULL,NULL,'bc4851e2-c740-11e0-aac7-544249e49b14'),(60,54,613,0.25,0.25,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.25 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:16:58',0,NULL,NULL,NULL,'dac93924-c740-11e0-aac7-544249e49b14'),(61,54,738,0.25,0.25,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0.25 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:17:31',0,NULL,NULL,NULL,'eeca0566-c740-11e0-aac7-544249e49b14'),(62,55,613,0.25,0.25,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.25 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:17:53',0,NULL,NULL,NULL,'fb9982f8-c740-11e0-aac7-544249e49b14'),(63,55,738,0.5,0.5,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:18:12',0,NULL,NULL,NULL,'06fda1a6-c741-11e0-aac7-544249e49b14'),(64,56,613,0.5,0.5,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:25:00',0,NULL,NULL,NULL,'fa555f42-c741-11e0-aac7-544249e49b14'),(65,56,738,0.5,0.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.5 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:25:22',0,NULL,NULL,NULL,'0740334e-c742-11e0-aac7-544249e49b14'),(66,57,613,0.5,0.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.75 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:28:15',0,NULL,NULL,NULL,'6e7bb312-c742-11e0-aac7-544249e49b14'),(67,57,738,0.75,0.75,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0.75 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:28:56',0,NULL,NULL,NULL,'86edeee2-c742-11e0-aac7-544249e49b14'),(68,58,738,0.75,0.75,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'0.75 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:35:16',0,NULL,NULL,NULL,'691215c8-c743-11e0-aac7-544249e49b14'),(69,58,613,0.75,0.75,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.75 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:35:29',0,NULL,NULL,NULL,'714a0372-c743-11e0-aac7-544249e49b14'),(70,59,613,0.75,0.75,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'0.75 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:38:11',0,NULL,NULL,NULL,'d164b572-c743-11e0-aac7-544249e49b14'),(71,59,738,1,1,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:38:49',0,NULL,NULL,NULL,'e8817aec-c743-11e0-aac7-544249e49b14'),(72,60,613,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:39:51',0,NULL,NULL,NULL,'0d34cee8-c744-11e0-aac7-544249e49b14'),(73,60,738,1,1,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:39:58',0,NULL,NULL,NULL,'11b4f740-c744-11e0-aac7-544249e49b14'),(74,62,72,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:51:41',0,NULL,NULL,NULL,'b47acc42-c745-11e0-aac7-544249e49b14'),(75,62,737,1,1,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:52:31',0,NULL,NULL,NULL,'d23229ec-c745-11e0-aac7-544249e49b14'),(76,63,72,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:53:50',0,NULL,NULL,NULL,'0128a794-c746-11e0-aac7-544249e49b14'),(77,63,737,1.5,1.5,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'1.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:54:07',0,NULL,NULL,NULL,'0b5aa2b2-c746-11e0-aac7-544249e49b14'),(78,64,72,2,2,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:54:36',0,NULL,NULL,NULL,'1ca6cffa-c746-11e0-aac7-544249e49b14'),(79,64,737,2,2,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:54:50',0,NULL,NULL,NULL,'250a0cde-c746-11e0-aac7-544249e49b14'),(80,65,72,2.5,2.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2.5 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:55:43',0,NULL,NULL,NULL,'448bdb6e-c746-11e0-aac7-544249e49b14'),(81,65,737,2.5,2.5,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'2.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:55:54',0,NULL,NULL,NULL,'4b79745e-c746-11e0-aac7-544249e49b14'),(82,66,72,3,3,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'3 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:56:17',0,NULL,NULL,NULL,'58abcc4e-c746-11e0-aac7-544249e49b14'),(83,66,737,3,3,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:56:28',0,NULL,NULL,NULL,'5fc3a2ae-c746-11e0-aac7-544249e49b14'),(84,67,72,4,4,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'4 tab(s) IN THE EVENING (QPM)',1,'2011-08-15 15:56:49',0,NULL,NULL,NULL,'6beda228-c746-11e0-aac7-544249e49b14'),(85,67,737,4,4,'tab(s)','IN THE MORNING (QPM)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-15 15:57:01',0,NULL,NULL,NULL,'73461b2c-c746-11e0-aac7-544249e49b14'),(86,68,18,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'33918a66-cce6-11e0-8959-544249e32ba2'),(87,69,18,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391b7c0-cce6-11e0-8959-544249e32ba2'),(88,70,18,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391baea-cce6-11e0-8959-544249e32ba2'),(89,71,18,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391bdc4-cce6-11e0-8959-544249e32ba2'),(90,72,740,1,1,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391c094-cce6-11e0-8959-544249e32ba2'),(91,73,740,1.5,1.5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391c5ee-cce6-11e0-8959-544249e32ba2'),(92,74,740,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391c882-cce6-11e0-8959-544249e32ba2'),(93,75,740,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391cb02-cce6-11e0-8959-544249e32ba2'),(94,76,740,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391cd8c-cce6-11e0-8959-544249e32ba2'),(95,77,740,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391cff8-cce6-11e0-8959-544249e32ba2'),(96,78,19,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391d7f0-cce6-11e0-8959-544249e32ba2'),(97,79,19,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391dade-cce6-11e0-8959-544249e32ba2'),(98,80,19,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391dd86-cce6-11e0-8959-544249e32ba2'),(99,81,19,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391e010-cce6-11e0-8959-544249e32ba2'),(100,82,17,1,1,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391e272-cce6-11e0-8959-544249e32ba2'),(101,83,17,1.5,1.5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391ef4c-cce6-11e0-8959-544249e32ba2'),(102,84,17,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391f1ea-cce6-11e0-8959-544249e32ba2'),(103,85,17,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391f488-cce6-11e0-8959-544249e32ba2'),(104,86,17,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391f744-cce6-11e0-8959-544249e32ba2'),(105,87,17,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391fa00-cce6-11e0-8959-544249e32ba2'),(106,88,27,1,1,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391fca8-cce6-11e0-8959-544249e32ba2'),(107,89,27,1.5,1.5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3391ff5a-cce6-11e0-8959-544249e32ba2'),(108,90,27,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'339201f8-cce6-11e0-8959-544249e32ba2'),(109,91,27,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'3392048c-cce6-11e0-8959-544249e32ba2'),(110,92,27,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'33920716-cce6-11e0-8959-544249e32ba2'),(111,93,27,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'33922e3a-cce6-11e0-8959-544249e32ba2'),(112,88,17,1,1,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'29083bb4-e06c-11e0-87df-544249e32ba2'),(113,89,17,1.5,1.5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'1.5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'29084000-e06c-11e0-87df-544249e32ba2'),(114,90,17,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'290841ae-e06c-11e0-87df-544249e32ba2'),(115,91,17,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'2908433e-e06c-11e0-87df-544249e32ba2'),(116,92,17,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'290844ce-e06c-11e0-87df-544249e32ba2'),(117,93,17,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'2908465e-e06c-11e0-87df-544249e32ba2'),(119,131,18,2,2,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'2 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f50578-e06d-11e0-87df-544249e32ba2'),(120,132,18,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'3 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f509a6-e06d-11e0-87df-544249e32ba2'),(121,133,18,3,3,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'4 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f50b5e-e06d-11e0-87df-544249e32ba2'),(122,134,18,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f50cee-e06d-11e0-87df-544249e32ba2'),(128,140,18,5,5,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f50cee-e06d-11e0-87df-544249e32za2'),(129,138,18,4,4,'tabs(s)','ONCE A DAY (OD)',0,0,NULL,'5 tab(s) IN THE MORNING (QPM)',1,'2011-08-22 17:29:21',0,NULL,NULL,NULL,'89f50cee-e06d-11e0-87df-544249e32sa2');
/*!40000 ALTER TABLE `regimen_drug_order` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-09-16 19:45:13

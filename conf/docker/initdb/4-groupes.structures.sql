USE groupes;
-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (x86_64)
--
-- Host: cadidb.epfl.ch    Database: groupes
-- ------------------------------------------------------
-- Server version	5.1.73-log

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
-- Table structure for table `actualmembers`
--

DROP TABLE IF EXISTS `actualmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `actualmembers` (
  `sciper` char(6) DEFAULT NULL,
  `groupid` char(6) DEFAULT NULL,
  KEY `sciper` (`sciper`,`groupid`),
  KEY `groupid` (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admins`
--

DROP TABLE IF EXISTS `admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admins` (
  `membre` char(6) NOT NULL DEFAULT '',
  PRIMARY KEY (`membre`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `badnames`
--

DROP TABLE IF EXISTS `badnames`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `badnames` (
  `name` varchar(32) DEFAULT NULL,
  UNIQUE KEY `idx_badnames` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `excluded`
--

DROP TABLE IF EXISTS `excluded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `excluded` (
  `member` char(6) DEFAULT NULL,
  `groupid` char(6) DEFAULT NULL,
  KEY `member` (`member`,`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `externes`
--

DROP TABLE IF EXISTS `externes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `externes` (
  `sciper` varchar(6) NOT NULL DEFAULT '',
  `nom` varchar(64) DEFAULT NULL,
  `prenom` varchar(64) DEFAULT NULL,
  `entreprise` varchar(64) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `responsable` varchar(6) DEFAULT NULL,
  PRIMARY KEY (`sciper`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `groupes`
--

DROP TABLE IF EXISTS `groupes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groupes` (
  `id` mediumint(9) NOT NULL AUTO_INCREMENT,
  `nom` varchar(64) NOT NULL DEFAULT '',
  `owner` varchar(6) DEFAULT NULL,
  `description` text,
  `url` varchar(128) DEFAULT NULL,
  `access` enum('o','r','f') DEFAULT NULL,
  `registration` enum('o','w','f') DEFAULT NULL,
  `visible` char(1) DEFAULT NULL,
  `maillist` char(1) DEFAULT NULL,
  `visilist` char(1) DEFAULT 'n',
  `ldap` char(1) DEFAULT NULL,
  `afsgroup` char(1) DEFAULT NULL,
  `ad` char(1) DEFAULT NULL,
  `flushed` char(1) DEFAULT NULL,
  `gid` int(11) DEFAULT NULL,
  `creation` datetime DEFAULT NULL,
  PRIMARY KEY (`nom`),
  KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8828 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `logs`
--

DROP TABLE IF EXISTS `logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `logs` (
  `date` datetime DEFAULT NULL,
  `opcode` tinyint(4) DEFAULT NULL,
  `sciper` varchar(6) DEFAULT NULL,
  `detail` text,
  KEY `date` (`date`,`opcode`,`sciper`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `membres`
--

DROP TABLE IF EXISTS `membres`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `membres` (
  `membre` varchar(32) DEFAULT NULL,
  `groupe` varchar(64) DEFAULT NULL,
  `admin` char(1) DEFAULT NULL,
  KEY `membre` (`membre`,`groupe`),
  KEY `groupe` (`groupe`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newadmins`
--

DROP TABLE IF EXISTS `newadmins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newadmins` (
  `admin` char(6) DEFAULT NULL,
  `groupid` char(6) DEFAULT NULL,
  KEY `admin` (`admin`,`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newgroups`
--

DROP TABLE IF EXISTS `newgroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newgroups` (
  `numid` int(11) NOT NULL AUTO_INCREMENT,
  `id` char(6) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  `owner` varchar(6) DEFAULT NULL,
  `description` text,
  `url` varchar(128) DEFAULT NULL,
  `access` enum('o','r','f') DEFAULT NULL,
  `registration` enum('o','w','f') DEFAULT NULL,
  `visible` char(1) DEFAULT NULL,
  `maillist` char(1) DEFAULT NULL,
  `visilist` char(1) DEFAULT NULL,
  `listext` char(1) DEFAULT 'n',
  `public` char(1) DEFAULT NULL,
  `ldap` char(1) DEFAULT NULL,
  `gid` int(11) DEFAULT NULL,
  `creation` datetime DEFAULT NULL,
  PRIMARY KEY (`numid`),
  KEY `id` (`id`,`name`)
) ENGINE=MyISAM AUTO_INCREMENT=21966 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newmembers`
--

DROP TABLE IF EXISTS `newmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newmembers` (
  `member` char(6) DEFAULT NULL,
  `groupid` char(6) DEFAULT NULL,
  KEY `member` (`member`,`groupid`),
  KEY `groupid` (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newqueries`
--

DROP TABLE IF EXISTS `newqueries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newqueries` (
  `numid` int(11) NOT NULL AUTO_INCREMENT,
  `id` char(6) DEFAULT NULL,
  `label` varchar(64) DEFAULT NULL,
  `description` text,
  `query` text,
  `owner` char(6) DEFAULT NULL,
  `access` char(1) DEFAULT NULL,
  `creation` datetime DEFAULT NULL,
  PRIMARY KEY (`numid`),
  KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sousgroupes`
--

DROP TABLE IF EXISTS `sousgroupes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sousgroupes` (
  `groupe` varchar(40) DEFAULT NULL,
  `sousgroupe` varchar(40) DEFAULT NULL,
  KEY `groupe` (`groupe`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` int(11) DEFAULT NULL,
  `maxval` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-11-20  9:58:38

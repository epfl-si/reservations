USE bottin;
CREATE TABLE `annuaire_adrspost` (
  `pers_id` varchar(6) NOT NULL,
  `unit_id` varchar(12) NOT NULL,
  `type` varchar(10) NOT NULL,
  `type_related_id` int(11) DEFAULT NULL,
  `adr` varchar(255) DEFAULT NULL,
  `pays` varchar(24) DEFAULT NULL,
  `cmd_id` int(11) NOT NULL,
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`pers_id`,`unit_id`,`valid_from`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_commandes` (
  `cmd_id` int(11) NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL,
  `creator` varchar(6) NOT NULL,
  `pers_id` varchar(6) DEFAULT NULL,
  `unit_id` varchar(12) DEFAULT NULL,
  `room_id` int(11) DEFAULT NULL,
  `phone_id` int(11) DEFAULT NULL,
  `validation_unit_id` varchar(12) DEFAULT NULL,
  `validation_pers_id` varchar(6) DEFAULT NULL,
  `validation_right` varchar(5) NOT NULL DEFAULT 'admin',
  `commande` varchar(45) NOT NULL,
  `params` text,
  `date_valid` datetime DEFAULT NULL,
  `validator` varchar(6) DEFAULT NULL,
  `status` varchar(45) DEFAULT NULL,
  `comment` text,
  PRIMARY KEY (`cmd_id`),
  KEY `pers_id_idx` (`pers_id`),
  KEY `unit_id_idx` (`unit_id`),
  KEY `room_id_idx` (`room_id`),
  KEY `validation_idx` (`commande`,`validation_unit_id`,`pers_id`,`status`)
) ENGINE=MyISAM AUTO_INCREMENT=344765 DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_impers` (
  `phone_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `other_room` varchar(45) DEFAULT NULL,
  `unit_id` int(11) NOT NULL,
  `cmd_id` int(11) NOT NULL,
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`phone_id`,`room_id`,`valid_from`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_persons` (
  `pers_id` int(11) NOT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `cmd_id` int(11) NOT NULL,
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`pers_id`,`valid_from`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_persphones` (
  `pers_id` varchar(6) NOT NULL,
  `unit_id` varchar(12) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `other_room` varchar(45) DEFAULT NULL,
  `phone_id` int(11) NOT NULL,
  `phone_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `phone_order` int(11) NOT NULL DEFAULT '1',
  `cmd_id` varchar(45) DEFAULT NULL,
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`pers_id`,`unit_id`,`phone_id`,`valid_from`),
  KEY `pers_phone_unit_valid_idx` (`pers_id`,`phone_id`,`unit_id`,`valid_to`),
  KEY `phone_unit_valid_idx` (`phone_id`,`unit_id`,`valid_to`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_persrooms` (
  `pers_id` varchar(6) NOT NULL,
  `unit_id` varchar(12) NOT NULL,
  `room_id` int(11) NOT NULL,
  `room_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `room_order` int(11) NOT NULL DEFAULT '1',
  `cmd_id` int(11) NOT NULL,
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`pers_id`,`unit_id`,`room_id`,`valid_from`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `annuaire_phones` (
  `phone_id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_nb` varchar(45) DEFAULT NULL,
  `phone_type` varchar(45) DEFAULT NULL,
  `owner` varchar(6) DEFAULT NULL,
  `is_orphan` tinyint(1) NOT NULL DEFAULT '0',
  `comment` varchar(255) DEFAULT NULL,
  `outgoing_right` varchar(20) NOT NULL DEFAULT 'INTERNAL',
  `billable` tinyint(1) NOT NULL DEFAULT '0',
  `internal` tinyint(1) NOT NULL DEFAULT '0',
  `attribution_label` varchar(45) DEFAULT NULL,
  `cmd_id` int(11) NOT NULL DEFAULT '0',
  `valid_from` datetime NOT NULL,
  `valid_to` datetime DEFAULT NULL,
  PRIMARY KEY (`phone_id`,`valid_from`),
  KEY `phone_nb_idx` (`phone_nb`,`valid_to`)
) ENGINE=MyISAM AUTO_INCREMENT=10936 DEFAULT CHARSET=utf8;
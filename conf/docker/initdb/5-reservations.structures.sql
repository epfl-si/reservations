USE reservations;
CREATE TABLE `dates` (
  `res_id` int(11) NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`date`,`res_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `logs` (
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sciper` varchar(10) NOT NULL DEFAULT '',
  `obj_id` int(11) NOT NULL DEFAULT '0',
  `res_id` int(11) DEFAULT NULL,
  `msg` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ts`,`sciper`,`obj_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `obj` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nom` varchar(50) NOT NULL DEFAULT '',
  `descr` text,
  `disp` char(1) DEFAULT NULL,
  `visible` char(1) DEFAULT NULL,
  `datedeb` date DEFAULT NULL,
  `datefin` date DEFAULT NULL,
  `plan` text,
  `office` varchar(20) DEFAULT NULL,
  `maj` datetime DEFAULT NULL,
  `maj_by` varchar(10) DEFAULT NULL,
  `unites` text,
  `pool` int(11) NOT NULL DEFAULT '1',
  `max_pool` int(11) NOT NULL DEFAULT '1',
  `hide` char(1) DEFAULT NULL,
  `groupes` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4282 DEFAULT CHARSET=utf8;

CREATE TABLE `res` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nom` varchar(20) NOT NULL DEFAULT '',
  `descr` varchar(255) DEFAULT NULL,
  `obj_id` int(11) NOT NULL DEFAULT '0',
  `sciper` varchar(10) NOT NULL DEFAULT '',
  `datedeb` date DEFAULT NULL,
  `datefin` date DEFAULT NULL,
  `periodic` varchar(25) DEFAULT NULL,
  `jour` varchar(10) DEFAULT NULL,
  `hdeb` varchar(5) DEFAULT NULL,
    `hfin` varchar(5) DEFAULT NULL,
  `maj` datetime DEFAULT NULL,
  `maj_by` varchar(10) DEFAULT NULL,
  `unite` varchar(10) DEFAULT NULL,
  `pool` int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=531588 DEFAULT CHARSET=utf8;

CREATE TABLE `tokens` (
  `id` varchar(255) NOT NULL,
  `obj_id` int(11) NOT NULL,
  `rights` char(2) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `sciper` varchar(10) NOT NULL DEFAULT '',
  `obj_id` int(11) NOT NULL DEFAULT '0',
  `droit` tinyint(1) DEFAULT NULL,
  `mail` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`sciper`,`obj_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


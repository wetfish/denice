SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

DROP TABLE IF EXISTS `dictionary`;
CREATE TABLE `dictionary` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Word1` varchar(128) NOT NULL,
  `Word2` varchar(128) NOT NULL,
  `Word3` varchar(128) NOT NULL,
  `DateAdded` int(11) NOT NULL,
  PRIMARY KEY (`Index`),
  KEY `Word1` (`Word1`),
  KEY `Word2` (`Word2`),
  KEY `Word3` (`Word3`),
  FULLTEXT KEY `Word1_2` (`Word1`,`Word2`,`Word3`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `duelchars`;
CREATE TABLE `duelchars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nick` varchar(16) NOT NULL,
  `title` varchar(32) NOT NULL,
  `armor` int(11) NOT NULL,
  `attack` int(11) NOT NULL,
  `damage` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  `xp` int(11) NOT NULL,
  `hp` int(11) NOT NULL,
  `class` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `duelclasses`;
CREATE TABLE `duelclasses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `class` varchar(16) NOT NULL,
  `ac` int(11) NOT NULL,
  `attack` int(11) NOT NULL,
  `damage` int(11) NOT NULL,
  `hp` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `duelstats`;
CREATE TABLE `duelstats` (
  `index` int(11) NOT NULL AUTO_INCREMENT,
  `player1` varchar(16) NOT NULL,
  `player2` varchar(16) NOT NULL,
  `p1wins` int(11) NOT NULL,
  `p2wins` int(11) NOT NULL,
  PRIMARY KEY (`index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `greeting`;
CREATE TABLE `greeting` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Nick` varchar(32) NOT NULL,
  `Greeting` text,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `quotes`;
CREATE TABLE `quotes` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Quote` varchar(512) NOT NULL,
  `Time` int(11) NOT NULL,
  `Delete` tinyint(1) NOT NULL,
  `Blame` varchar(16) NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `remember`;
CREATE TABLE `remember` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Title` text NOT NULL,
  `Content` text NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `seen`;
CREATE TABLE `seen` (
  `nick` varchar(31) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `event` varchar(16) NOT NULL,
  `location` text NOT NULL,
  `message` text NOT NULL,
  UNIQUE KEY `nick` (`nick`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


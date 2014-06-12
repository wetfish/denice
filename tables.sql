CREATE TABLE `dictionary` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Word1` varchar(32) NOT NULL,
  `Word2` varchar(32) NOT NULL,
  `Word3` varchar(32) NOT NULL,
  `DateAdded` int(11) NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE `quotes` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Quote` varchar(512) NOT NULL,
  `Time` int(11) NOT NULL,
  `Delete` tinyint(1) NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE `remember` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Title` text NOT NULL,
  `Content` text NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE `seen` (
  `nick` varchar(31) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `event` varchar(16) NOT NULL,
  `location` varchar(16) NOT NULL,
  `message` text NOT NULL,
  UNIQUE KEY `nick` (`nick`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `greeting` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Nick` varchar(32) NOT NULL,
  `Greeting` text,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;


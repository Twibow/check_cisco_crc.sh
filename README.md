# check_cisco_crc.sh
Nagios / Centreon check CRC error on Cisco Switch

This plugin is a Fork of check_hp_crc.sh by Michael St

Usage : 
./check_hp_crc.sh -H HOSTADRESS -C <SNMP COMMUNITY> -v <SNMP VERSION> -w <NUMBER of CRC ERRORS> -c <NUMBER of CRC ERRORS>

-H = Hostaddress
-C = SNMP Community (optional, if not set we use public)
-v = SNMP Version (optional, if not set we use 2c)
-w = Warning Threshold
-c = Critical Threshold
-p = Enable Performance Data for all Ports

-h = Help - Print this Help!

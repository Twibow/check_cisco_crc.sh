#!/bin/bash
#
# check_cisco_crc.sh - Version 1.0
# check_cisco_crc.sh by @Twibow
# Fork of check_hp_crc.sh by Michael St - 23.10.2014
#
# This Script checks Cisco Switches on every Interface for CRC Errors
#


# MIBS
# get CRC ERRORS on INTERFACES
CRC_MIB="1.3.6.1.4.1.9.2.2.1.1.12"


# RETURN VALUES:
# OK = 0
# WARNING = 1
# CRITICAL = 2
# UNKNOWN = 3
#
LIBEXEC="/usr/bin/snmpwalk"
SNMPC="public"
SNMPV="2c"
HOST=""
WARN=0
CRIT=1
DEBUG=0
CNTIF=0
SETWARN=0
SETCRIT=0
SETUNKNOWN=0
SNMPOUTPUT=""
CRCPORTSWARN=""
CRCPORTSCRIT=""
CRCOKPERF=""
RETURN=3
PERFDATA=0
MODE_SELECTION="crc"


# here is the most important function in this script - the help function
function print_help 
{
echo "
./check_hp_crc.sh -H HOSTADRESS -C <SNMP COMMUNITY> -v <SNMP VERSION> -w <NUMBER of CRC ERRORS> -c <NUMBER of CRC ERRORS>

-H = Hostaddress
-C = SNMP Community (optional, if not set we use public)
-v = SNMP Version (optional, if not set we use 2c)
-w = Warning Threshold
-c = Critical Threshold
-p = Enable Performance Data for all Ports

-h = Help - Print this Help!
"
}

#check command line arguments
# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "H:C:v:w:c:hdpm:" opt; do
    case "$opt" in
    h)
        print_help
        exit 0
        ;;
    H)  HOST=$OPTARG
        ;;
    C)  SNMPC=$OPTARG
        ;;
    v)  SNMPV=$OPTARG
    ;;
    w)  WARN=$OPTARG
    ;;
    c)  CRIT=$OPTARG
    ;;
    d)  DEBUG=1
    ;;
    p)  PERFDATA=1
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# check if warn is smaller than CRIT &
if [ $WARN -ge $CRIT ]; then
    echo "ERROR - If a WARNING-Threshhold is set, you have to set a greater CRITICAL-Threshold too!"
    exit 3;
fi


# some debugging: activate with -d in cli
if [ "$DEBUG" -eq "1" ]; then
# debug out
echo [Debug] = "${DEBUG}"
echo [Host] = "${HOST}"
echo [Snmp Community] = "${SNMPC}"
echo [Snmp Version] = "${SNMPV}"
echo [Warn] = "${WARN}"
echo [Crit] = "${CRIT}"
echo [Perfdata] = "$PERFDATA"
echo [Mode slected] = "$MODE_SELECTION"
fi

function getInterfacesCRCErrors {

# some local variables - clear so far
ifarray=""
crcarray=""
IFS=$'\n'   #set separator to newline only

# do the snmpwalk and fetch data for all ports on switch
#SNMPOUT=( $(snmpwalk -v 2c -c public 10.255.30.99 RMON-MIB::etherStatsCRCAlignErrors) )
if ! SNMPOUT=( $($LIBEXEC -v $SNMPV -c $SNMPC $HOST $CRC_MIB) ); then
    SETUNKNOWN=1
fi

# now lets cut the snmpwalk output to portnumbers and crc-errors 
for i in "${SNMPOUT[@]}"
do
        ifarray+=( $(echo "$i" | awk -F. '{print $8}' | awk -F " " '{ print $1 }' | awk '/101./' | grep -o '.\{2\}$' | sed 's/^0//' ) )
        crcarray+=( $(echo "$i" | awk '/101./' | awk '{print $NF}') )
done

#now go over the array - here happens the magic
for i in ${ifarray[@]}
do
    if [ ${crcarray[i]} -ge $CRIT ]; then
        if [ $DEBUG -eq 1 ]; then
        echo "[DEBUG] CRIT THRESHOLD found: "${crcarray[i]} "CRC-Errors on Port: "${ifarray[i]}
        fi
                SETCRIT=1
                CRCPORTSCRIT+="Port ${ifarray[i]} has ${crcarray[i]} CRC-ERRORS <br>"
        elif [ ${crcarray[i]} -ge $WARN -a ${crcarray[i]} -lt $CRIT ]; then
        if [ $DEBUG -eq 1 ]; then
        echo "[DEBUG] WARN THRESHOLD found: "${crcarray[i]} "CRC-Errors on Port: "${ifarray[i]}
        fi
        SETWARN=1
        CRCPORTSWARN+="Port ${ifarray[i]} has ${crcarray[i]} CRC-ERRORS <br>"
    fi

    #here we create the performance data
    CRCPERF+="Port ${ifarray[i]}=${crcarray[i]};$WARN;$CRIT;; "
done

if [ $SETUNKNOWN -eq 1 ]; then
    echo "UNKNOWN"
    RETURN=3
elif [ $SETCRIT -eq 0 -a $SETWARN -eq 0 -a $SETUNKNOWN -eq 0 ]; then
    if [ $PERFDATA -eq 1 ]; then
        echo "OK - Switch has no CRC-Errors | $CRCPERF"
        RETURN=0
    else
        echo "OK - Switch has no CRC-Errors"
        RETURN=0
    fi
elif [ $SETCRIT -eq 1 ]; then
    if [ $PERFDATA -eq 1 ]; then
        echo "CRITICAL - $CRCPORTSCRIT | $CRCPERF"
        RETURN=2
    else
        echo "CRITICAL - $CRCPORTSCRIT"
        RETURN=2
    fi
elif [ $SETWARN -eq 1 ] &&  [ $SETCRIT -eq 0 ]; then
    if [ $PERFDATA -eq 1 ]; then
            echo "WARNING - $CRCPORTSWARN | $CRCPERF"
        RETURN=1
    else
        echo "WARNING - $CRCPORTSWARN"
        RETURN=1
    fi
fi

unset IFS
}

main() {

if [ -z $HOST ]; then
    print_help
elif [ "$MODE_SELECTION" != "crc" -a "$MODE_SELECTION" != "packetsin" -a "$MODE_SELECTION" != "packetsout" ]; then
    print_help
elif [ "$MODE_SELECTION" == "crc" ]; then
    getInterfacesCRCErrors
elif [ "$MODE_SELECTION" == "packetsin" -o "$MODE_SELECTION" == "packetsout" ]; then
    getInterfacesPacketErrors
else
    print_help
fi


if [ $DEBUG -eq 1 ]; then
echo "[Return Code] = $RETURN"
fi

exit $RETURN
}

main "$@"
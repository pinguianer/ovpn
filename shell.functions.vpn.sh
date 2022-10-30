#!/bin/bash
#########################################################################
#                                                                       #
#       AUTHOR      : Qingxiu Cui pinguianer@gmail.com                  #
#       VERSION     : 1.0                                               #
#       DESCRIPTION : OpenVPN Docker Shell Function                     #
#       CREATED     : Tue 22 Okt 2022 12:04:32 PM CEST                  #
#                                                                       #
#########################################################################


initialize() { #{{{
	VPN_ConfDir="/root/ovpn"
	PKI_Dir="/root/pki"
	Proto="tcp"
	IP=$(ifconfig -a|grep 192|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")

} #}}}

#===  FUNCTION  =======================================================
#          NAME:  pki_initialize				      #
#   DESCRIPTION:  EASY_RSA pki init	  			      #
#    PARAMETERS:  none						      #
#       RETURNS:  						      #
#======================================================================

pki_initialize() { #{{{

	EASYRSA="/usr/share/easy-rsa/easyrsa"
	PKI_Dir="/root/pki"
	CA_KEY_PATH="$PKI_Dir/private/ca.key"
	CA_CRT_PATH="$PKI_Dir/ca.crt"
	ServerKEY_PATH="$PKI_Dir/private/server.key"
	ServerCRT_PATH="$PKI_Dir/issued/server.crt"
	ServerCSR_PATH="$PKI_Dir/reqs/server.req"
	ClientKEY_PATH="$PKI_Dir/private/client.key"
	ClientCSR_PATH="$PKI_Dir/reqs/client.req"
	ClientCRT_PATH="$PKI_Dir/issued/client.crt"
	DhCert_PATH="$PKI_Dir/dh.pem"
	ExpirationDate="3650"
	KeyLength="1024"
	Email="pinguianer@gmail.com"

} #}}}


#===========+++++   Copyright©Pinguianer Bash Toolbox  Function  +++++==========#
#          NAME:  plausibility_check						#
#   DESCRIPTION:  checks input for error data			      		#
#    PARAMETERS:  type, var (look at code for possible types)	      		#
#       RETURNS:  either correct var or ""			      		#
#===============================================================================#

plausibility_check() { #{{{
        local Type="${1}"
        local Var="${2:-}"
        local Var2="${3:-}"
        local Returnstring=""
        case $Type in
                  vpnid ) # Check if user input is in valid list of officeVPNformat
			if [[ ${Var} =~ ^office[0-9]{3}$ ]] ; then 
				Returnstring="${Var}"
			fi
                        ;;
                delnull )
			Var=$(echo ${Var} | sed 's/^0\{1,3\}//g')
			Returnstring="${Var}"
                        ;;
                addnull )
			while [ ${#Var} -le 2 ]
			do
				Var="0"${Var};
			done
			Returnstring="${Var}"
                        ;;
                numeric ) # Check if user input is numeric
                        isNumeric "${Var}" && Returnstring="${Var}"
                        ;;
                * ) # Unknown Type, return ""
                        ;;
        esac
        echo "${Returnstring}"
        return 0
} #}}}

#===========+++++   Copyright©Pinguianer Bash Toolbox  Function  +++++==========#
#          NAME:  get_info							#
#   DESCRIPTION:  Display System Infos				      		#
#    PARAMETERS:  $1						      		#
#       RETURNS:  						      		#
#===============================================================================#

get_info() { #{{{

	local VPNID="$(plausibility_check vpnid ${1})"
	local Horizo="  ~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ~~- ~~~"

	dpkg --get-selections | grep easy-rsa
	dpkg --get-selections | grep openssl
	

cat << EOF > /dev/tty

/etc/iptables/rules.v4





                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===  
       /""""""""""""""""\___/ === `echo -e "\033[37;5m $VPNID \033[0m"`
`echo -e "\033[34;5m $Horizo \033[0m"`
       \______ o          __/            
         \    \        __/             
          \____\______/           


	  


EOF


} #}}}


#===========+++++   Copyright©Pinguianer Bash Toolbox  Function  +++++==========#
#          NAME:  isNumeric							#
#   DESCRIPTION:  simple function that checks if $@ is numeric (more or less)	#
#    PARAMETERS:  string							#
#       RETURNS:  0 if numeric							#
#===============================================================================#

isNumeric() { #{{{
        echo "$@" | grep -q -v "[^0-9\ \.]"
} #}}}
isRealNumeric() { #{{{
        echo "$@" | grep -q -v "[^0-9]"
} #}}}

officexxx() { #{{{
        echo "$@" | grep -q -v "^office[0-9]{1,3}$"
	
} #}}}


print() { printf "\e[31m $*\n" "%\e[31m\n"; }

#===========+++++   Copyright©Pinguianer Bash Toolbox  Function  +++++==========#
#          NAME:  die								#
#   DESCRIPTION:  Print Error Exception message					#
#    PARAMETERS:  string							#
#       RETURNS:  exit 1							#
#===============================================================================#

die() { #{{{
        print "
Shell function error:

$1" 1>&2
        prog_exit "${2:-1}"
} #}}} # => die()

printinfo() { printf "\e[34m $*\n" "%\e[34m\n"; }

shellinfo() { #{{{
        printinfo "
Shell function info:
	$1"
} #}}}



prog_exit() {
        ESTAT=0
        [ -n "$1" ] && ESTAT=$1
        (stty echo 2>/dev/null) || set -o echo
        echo "" # just to get a clean line
        exit "$ESTAT"
} # => prog_exit()


#if dpkg --get-selections | grep -q easy ; then echo ok ; fi


get_id_by_name() { #{{{

	echo ${1}
} #}}}


#===  FUNCTION  =======================================================
#          NAME:  delete_all					      #
#   DESCRIPTION:  delete all container config and certificate etc.    #
#    PARAMETERS:  none						      #
#       RETURNS:  						      #
#======================================================================

delete_all() { #{{{

	rm -fr ~/pki ; rm -fr /ovpn
	docker stop $(docker ps -aq); docker rm $(docker ps -aq)
	docker system prune
} #}}}


#===  FUNCTION  =======================================================
#          NAME:  create_ovpn					      #
#   DESCRIPTION:  create OpenVPN container and run it		      #
#    PARAMETERS:  none						      #
#       RETURNS:  						      #
#======================================================================

create_ovpn() { #{{{

	initialize # initialize standard
	local VPNID="$(plausibility_check vpnid ${1})"
	local OfficeID=$(echo $VPNID | sed "s/^office//")
	local OfficeNr="$(plausibility_check delnull ${OfficeID})"
	local IPrange="172.19.$OfficeNr.0/24"
	local IPdocker="172.19.$OfficeNr.2"
	
	if [[ "${VPNID}" == "" ]]
        then
                die "ERROR: create ovpn VPNID ${1} not allowed "
        fi

	create_ovpn_certificate $VPNID
	create_ovpn_configs $VPNID
	docker network create -d bridge --subnet=$IPrange $VPNID
	docker run --name $VPNID --net $VPNID --ip $IPdocker -itd -v $VPN_ConfDir/$VPNID:/etc/openvpn -itd -p 1194:1194/tcp --cap-add=NET_ADMIN pinguianer/ovpn
	get_info "${VPNID}"

} #}}}




#===  FUNCTION  =======================================================
#          NAME:  create_ovpn_configs			 	      #
#   DESCRIPTION:  create config for OpenVPN server and client	      #
#    PARAMETERS:  none						      #
#       RETURNS:  						      #
#======================================================================

create_ovpn_configs() { #{{{

	initialize # initialize standard
	pki_initialize # initialize standard EASYRSA pki
	
	local VPNID="$(plausibility_check vpnid ${1})"
	local OfficeID=$(echo $VPNID | sed "s/^office//")
	local OfficeNr="$(plausibility_check delnull ${OfficeID})"
	local IPrange="172.19.$OfficeNr.0/24"
	local IPdocker="172.19.$OfficeNr.2"
	local OUTPUT_DIR="$VPN_ConfDir/$VPNID"

###--- old data check ---###

	if [[ "${VPNID}" == "" ]]
        then
                die "ERROR: VPNID ${1} not allowed"
                exit 1

	elif [ -d "$VPN_ConfDir/$VPNID" ]; then
                die "VPN Server Config for $VPNID exists !"
		exit 1

	elif [ ! -d "$PKI_Dir" ]; then
                die "Certificate for $VPNID not exists ! "
		exit 1
        fi

	mkdir -p $VPN_ConfDir/$VPNID/ccd

###--- ccd export ---###
cat << EOF > $VPN_ConfDir/$VPNID/ccd/$VPNID
iroute 10.0.$OfficeNr.0 255.255.255.0
route 10.0.$OfficeNr.0 255.255.255.0
ifconfig-push 10.0.0.$OfficeNr 10.0.0.250
EOF

###--- server conf export ---###
cat << EOF > $VPN_ConfDir/$VPNID/server.conf
port 1194
proto tcp-server
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem

mode server
tls-server
ifconfig 10.0.0.250 10.0.0.251
ifconfig-pool 10.0.0.1 10.0.0.100
route 10.0.0.0 255.255.0.0
push "route 10.0.0.0"

user nobody
group nogroup
status /etc/openvpn/openvpn-status.log
log-append /etc/openvpn/openvpn.log
verb 2
mute 20
max-clients 100
keepalive 10 120
client-config-dir /etc/openvpn/ccd
comp-lzo
persist-key
persist-tun
ccd-exclusive
push "route 192.168.200.0 255.255.255.0"
push "route 192.168.210.0 255.255.255.0"
push "route 192.168.221.0 255.255.255.0"
push "route 10.2.221.0 255.255.255.0"
#push "redirect-gateway def1"
EOF

###--- copy certificate to docker volume ---###

	cp ${CA_CRT_PATH} $VPN_ConfDir/$VPNID/ca.crt 
	cp ${ServerKEY_PATH} $VPN_ConfDir/$VPNID/server.key
	cp ${ServerCRT_PATH} $VPN_ConfDir/$VPNID/server.crt
	cp ${DhCert_PATH} $VPN_ConfDir/$VPNID/dh.pem
	cp ${ClientCRT_PATH} $VPN_ConfDir/$VPNID/client.crt
	cp ${ClientKEY_PATH} $VPN_ConfDir/$VPNID/client.key


###--- client conf export ---###

cat << EOF > $VPN_ConfDir/$VPNID/client.ovpn

##############################################
# Sample client-side OpenVPN 2.0 config file #
#                                            #
# This configuration can be used by multiple #
# clients, however each client should have   #
# its own cert and key files.                #
#                                            #
# On Windows, you might want to rename this  #
# file so it has a .ovpn extension           #
#			  		     #
# openvpn --config client.ovpn # to start    #
##############################################


client
dev tun
remote-cert-tls server

proto tcp
remote serverip 11$(plausibility_check addnull ${OfficeID})

nobind

user nobody
group nogroup

# Try to preserve some state across restarts.
persist-key
persist-tun

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single ca
# file can be used for all clients.

ca ca.crt
cert client.crt
key client.key

comp-lzo
keepalive 10 120

# Set log file verbosity.
verb 3
# Silence repeating messages
mute 20
redirect-gateway def1
EOF

#--- create client.ovpn  ---#

cat <(echo -e "##### Certificate for client $VPNID") \
    <(echo -e '<ca>') \
    ${CA_CRT_PATH}\
    <(echo -e '</ca>\n<cert>') \
    ${ClientCRT_PATH}\
    <(echo -e '</cert>\n<key>') \
    ${ClientKEY_PATH}\
    <(echo -e '</key>\n') \
    >> ${OUTPUT_DIR}/client.ovpn

#---  print shell infos ---#

shellinfo "VPNID=$VPNID"
shellinfo "Docker Network=$IPrange"
shellinfo "ovpn Docker IP=$IPdocker"
shellinfo ""

} #}}}



#===  FUNCTION  =======================================================
#          NAME:  create_ovpn_certificate			      #
#   DESCRIPTION:  create new certificate for OpenVPN		      #
#    PARAMETERS:  none						      #
#       RETURNS:  						      #
#======================================================================
create_ovpn_certificate() { #{{{

	local VPNID="$(plausibility_check vpnid ${1})"
	pki_initialize # initialize standard EASYRSA pki

	if [[ "${VPNID}" == "" ]]
        then
                die "ERROR: VPNID ${1} not allowed"
                exit 1

	elif [ -d "$PKI_Dir" ]; then
                die "old PKI exists !" 
		exit 1
        fi

###--- vars export ---###

cat << EOF > /root/vars
set_var EASYRSA_PKI		"\$PWD/pki"
set_var EASYRSA_DN		"org"

set_var EASYRSA_REQ_COUNTRY	"DE"
set_var EASYRSA_REQ_PROVINCE	"Berlin"
set_var EASYRSA_REQ_CITY	"Berlin"
set_var EASYRSA_REQ_ORG		"My Ubuntu CA"
set_var EASYRSA_REQ_EMAIL	"pinguianer@gmail.com"
set_var EASYRSA_REQ_OU		"OpenVPN"
set_var EASYRSA_ALGO		ec
set_var EASYRSA_CURVE		secp521r1
#set_var EASYRSA_ALGO		rsa
set_var EASYRSA_KEY_SIZE	$KeyLength
set_var EASYRSA_CA_EXPIRE	$ExpirationDate
set_var EASYRSA_CERT_EXPIRE	365
set_var EASYRSA_CERT_RENEW	30
set_var EASYRSA_CRL_DAYS	90
set_var EASYRSA_DIGEST         "sha512"
EOF

###--- make certificate ---###
	$EASYRSA --pki-dir=$PKI_Dir init-pki
	echo "Pinguianer" | $EASYRSA --pki-dir=$PKI_Dir build-ca nopass
	echo "Server$VPNID" | $EASYRSA --pki-dir=$PKI_Dir gen-req server nopass
	echo "yes" | $EASYRSA --pki-dir=$PKI_Dir sign-req server server
	echo $VPNID | $EASYRSA --pki-dir=$PKI_Dir gen-req client nopass
	echo "yes" | $EASYRSA --pki-dir=$PKI_Dir sign-req client client
	$EASYRSA --pki-dir=$PKI_Dir gen-dh

} #}}}



#===  FUNCTION  =======================================================
#          NAME:  parse_args_create_ovpn			      #
#   DESCRIPTION:  parses the cli args				      #
#    PARAMETERS:  $@						      #
#       RETURNS:  $VPNID					      #
#======================================================================

parse_args_create_ovpn() { #{{{
        while getopts ":r:" Option
        do
                case $Option in
                        r     ) VPNID=${OPTARG} ;;
                        h     ) print_help_create_ovpn ;;
                        *     ) print_help_create_ovpn ;;   # DEFAULT
                esac
        done
        shift $(($OPTIND - 1))
} #}}}


#===  FUNCTION  =======================================================
#          NAME:  parse_args_new_vpndocker			      #
#   DESCRIPTION:  parses the cli args				      #
#    PARAMETERS:  $@						      #
#       RETURNS:  $VPNID						      #
#======================================================================
parse_args_new_vpndocker() { #{{{
        while getopts ":h:r:w:" Option
        do
                case $Option in
                        w     ) WaitTime="$(plausibility_check numeric "${OPTARG}")" ;;
                        h     ) print_help_new_vpndocker ;;
                        *     ) print_help_new_vpndocker ;;   # DEFAULT
                esac
        done
        shift $(($OPTIND - 1))
} #}}}

#===  FUNCTION  =======================================================
#          NAME:  print_help_create_ovpn		 	      #
#   DESCRIPTION:  Prints help and exits				      #
#======================================================================

print_help_create_ovpn() { #{{{
        echo "Usage: `basename $0` -r <VPNID> [ -h ] [ -c ]"
        echo ""
        echo "e.g. ./`basename $0` -r office045"
        echo ""
} #}}}

#===  FUNCTION  =======================================================
#          NAME:  Print_help_new_vpnconfig		 	      #
#   DESCRIPTION:  Prints help and exits				      #
#======================================================================

print_help_create_ovpnconfig() { #{{{
        echo "Usage: `basename $0` -r <VPNID> [ -h ] [ -c ]"
        echo ""
        echo "e.g. ./`basename $0` -r office45"
        echo ""
        exit 0
} #}}}


#===  FUNCTION  =======================================================
#          NAME:  Print_help_delet_vpndocker		 	      #
#   DESCRIPTION:  Prints help and exits				      #
#======================================================================

print_help_delet_vpndocker() { #{{{
        echo "Usage: `basename $0` -r <VPNID> [ -h ] [ -c ]"
        echo ""
        echo "e.g. ./`basename $0` -r office45"
        echo ""
        exit 0
} #}}}

#===  FUNCTION  =======================================================
#          NAME:  Print_help_status_vpndocker		 	      #
#   DESCRIPTION:  Prints help and exits				      #
#======================================================================

print_help_status_vpndocker() { #{{{
        echo "Usage: `basename $0` -r <VPNID> [ -h ] [ -c ]"
        echo ""
        echo "e.g. ./`basename $0` -r office45"
        echo ""
        exit 0
} #}}}


#-------------------------------------------------------------------------------
#   This MUST be at the end of the file, all functions must already be defined
#
#   this little snippet allows us to symlink function names to this file
#-------------------------------------------------------------------------------
if [[ "$INCLUDED"  != "1" ]]
then
        $(basename $0) "$@"
fi


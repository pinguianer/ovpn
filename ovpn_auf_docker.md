# openvpn auto config and install script


## Wichtige Infos



(issu311)[https://www.mailprofessionals.de/git/MailPro/Infrastruktur/Konzeption/issues/311]

(easy-rsa)[https://github.com/OpenVPN/easy-rsa]

(Liste_der_standardisierten_Ports)[https://de.wikipedia.org/wiki/Liste_der_standardisierten_Ports]

(OpenVPN unter Ubuntu 20.04 Focal)[https://wiki.ubuntuusers.de/OpenVPN/]



## PKG Abhängigkeit

openssl, easyrsa, docker, iptables-presistent muessen installiert werden.

## Abkuerzungen und Definitionen
OpenVPN:=ovpn

VPNID:=officexxx, wobei 000 < xxx < 254 

office34, office02 sind nicht erlaubt.

OfficeID: letze 3 Ziffe von VPNID z.B. 046

OfficeNr: letze Ziffe ohne Null von der linke Seite z.B. OfficeID 006 <=> OfficeNr 6

VPN_ConfDir:="/ovpn" , Wo Config und Certificate von ovpn liegt.

SSL_ConfDir:="/root/pki" , Wo Certificate fuer ovpn von EASY-RSA generiert.


## Wie benutzt man die Skript ?

ganz einfach z.B. ./create_ovpn_docker office046

Tipps: Jede Funktion aus Shell kann man mit SoftLink einzel ausfuehren.


## Was muss man angepasst werden ?

keine

## Was wurde schon automatisiert ? 


### 1.1 Certificate fuer OpenVPN-Container

Die Skript generiert Certificate fuer OpenVPN-Container und speichert unter `/root/.CAconf/offficeXXX`


### 1.2 Config fuer OpenVPN-Container

create_ovpn_configs

Die Skript generiert Config und speichert Config-dateien unter `/ovpn/officeXXX`

undter `/ovpn/officeXX` liegt auch Client-config-datei mit Name client.ovpn.

### 1.3 Subnet und  OpenVPN-Container

Die Skript generiert Docker-Subnet mit IPrange "172.19.OfficeNr.0/24" und nehmen IP "172.19.OfficeNr.2" fuer ovpn-Container

### 1.4 Iptables






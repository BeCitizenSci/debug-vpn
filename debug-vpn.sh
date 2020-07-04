#!/bin/bash

# debug-vpn.sh
# This program produces in-depth IP network information in order to aid
# in the discovery of issues that may be preventing a VPN solution
# from working.
# Tested to work on Debian GNU/Linux
# Copyright (C) 2020  Scott C. MacCallum
# scott@scm.guru

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

vpn_host=
local_interface=
vpn_port=
line_count=

touch local-addresses.txt
echo "LOCAL MAC AND IP ADDRESS" >> local-addresses.txt
echo " " >> local-addresses.txt
ip address show dev $local_interface >> local-addresses.txt

touch route.txt
echo " " >> route.txt
echo "ROUTE" >> route.txt
echo " " >> route.txt
ip route show dev $local_interface >> route.txt

touch address-resolution.txt
echo " " >> address-resolution.txt
echo "ADDRESS RESOLUTION" >> address-resolution.txt
echo " " >> address-resolution.txt
arp -n >> address-resolution.txt

touch hosts-file.txt
echo " " >> hosts-file.txt
echo "HOSTS FILE" >> hosts-file.txt
echo " " >> hosts-file.txt
cat /etc/hosts >> hosts-file.txt

touch domain-name.txt
echo " " >> domain-name.txt
echo "DOMAIN NAME RESOLVERS" >> domain-name.txt
echo " " >> domain-name.txt
cat /etc/resolv.conf >> domain-name.txt

touch vpn-host.txt
echo " " >> vpn-host.txt
echo "VPN HOST" >> vpn-host.txt
nmap -Pn -sn $vpn_host >> vpn-host.txt

touch vpn-host-ip.txt
cat vpn-host.txt | perl -n -l -e'/(\d+\.\d+\.\d+\.\d+)/ && print $1' | sed '1 d' >> vpn-host-ip.txt

touch vpn-connection.txt
echo " " >> vpn-connection.txt
echo "VPN CONNECTION" >> vpn-connection.txt
echo " " >> vpn-connection.txt
vpn_ip=$(cat vpn-host-ip.txt)
netstat -n | grep -i $vpn_ip >> vpn-connection.txt

touch route-trace.txt
echo " " >> route-trace.txt
echo "ROUTE TRACE" >> route-trace.txt
echo " " >> route-trace.txt
mtr -n --report --report-cycles 10 $vpn_host >> route-trace.txt
line_total=$(cat route-trace.txt | sed '1,7 d' | wc -l | sed 's/\s.*$//')

touch route-trace-whois.txt
echo " " >> route-trace-whois.txt
echo "ROUTE TRACE WHOIS" >> route-trace-whois.txt
echo " " >> route-trace-whois.txt

while [[ $line_count -le $line_total ]]
do
    cat route-trace.txt | perl -n -l -e'/(\d+\.\d+\.\d+\.\d+)/ && print $1' | sed "1,$line_count d" | head -1 > route-trace-ip.txt
    route_trace_ip=$(cat route-trace-ip.txt)
    echo $route_trace_ip >> route-trace-whois.txt
    whois $route_trace_ip >> route-trace-whois.txt
    ((line_count++))
done

touch route-trace-vpn_port.txt
echo "UDP and TCP VPN ROUTE TRACE ON $vpn_port" >> route-trace-vpn_port.txt
nmap -n -p $vpn_port -sU --traceroute $vpn_host >> route-trace-vpn_port.txt

cat route-trace-vpn_port.txt | perl -n -l -e'/(\d+\.\d+\.\d+\.\d+)/ && print $1' | sed "2 d" | head -1 > route-trace-ip.txt
route_trace_ip=$(cat route-trace-ip.txt)
echo $route_trace_ip >> route-trace-whois.txt
whois $route_trace_ip >> route-trace-whois.txt

touch results.txt
cat local-addresses.txt >> results.txt
cat route.txt >> results.txt
cat hosts-file.txt >> results.txt
cat address-resolution.txt >> results.txt
cat domain-name.txt >> results.txt
cat vpn-host.txt >> results.txt
cat vpn-connection.txt >> results.txt
cat route-trace.txt >> results.txt
cat route-trace-whois.txt >> results.txt
cat route-trace-vpn_port.txt >> results.txt

less results.txt

exit 0


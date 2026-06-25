Warning: Permanently added '10.202.1.9' (RSA) to the list of known hosts.
# 1970-01-14 15:46:39 by RouterOS 7.12.1
# software id = 219P-GVCW
#
# model = RB750Gr3
# serial number = HE208GGBW13
/interface bridge
add admin-mac=48:A9:8A:42:C0:80 auto-mac=no comment=defconf name=bridgeLocal
add name=lo
/interface list
add name=WAN
add name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip hotspot profile
set [ find default=yes ] html-directory=hotspot
/port
set 0 name=serial0
/routing bgp template
add as=65001 name=AS65001 router-id=2.2.2.2 routing-table=main
/interface bridge port
add bridge=bridgeLocal comment=defconf interface=ether3
add bridge=bridgeLocal comment=defconf interface=ether4
add bridge=bridgeLocal comment=defconf interface=ether5
add bridge=bridgeLocal comment=defconf interface=ether2
add bridge=bridgeLocal comment=defconf interface=ether1
/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=LAN
add interface=ether3 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
/ip address
add address=10.202.1.9/16 interface=ether2 network=10.202.0.0
add address=172.36.0.2/30 interface=ether5 network=172.36.0.0
add address=2.2.2.2 interface=lo network=2.2.2.2
/ip dhcp-client
add comment=defconf disabled=yes interface=bridgeLocal
/ip firewall address-list
add address=172.36.0.0/30 comment="Annonce lien direct R1" list=connected
add address=2.2.2.2 comment="Annonce loopback MikroTik" list=connected
/ip route
add dst-address=1.1.1.1/32 gateway=172.16.0.1
/ip ssh
set always-allow-password-login=yes
/routing bgp connection
add local.address=2.2.2.2 .role=ibgp name=to-r1 remote.address=1.1.1.1 .as=\
    65001 templates=AS65001
add local.address=172.36.0.2 .role=ibgp name=to-r1-direct output.network=\
    connected remote.address=172.36.0.1 .as=65001 routing-table=main \
    templates=AS65001
/system note
set show-at-login=no
Flags: E - established 
 0   name="to-r1-1" 
     remote.address=1.1.1.1 .as=65001 .id=1.1.1.1 .capabilities=mp,rr,as4,err 
     local.role=ibgp .address=2.2.2.2 .as=65001 .id=2.2.2.2 
     .capabilities=mp,rr,gr,as4 
     output.last-notification=ffffffffffffffffffffffffffffffff0015030400 
     input.last-notification=ffffffffffffffffffffffffffffffff0015030603 ibgp 
     multihop=yes keepalive-time=1m last-started=1970-01-09 22:56:05 
     last-stopped=1970-01-11 00:52:17 prefix-count=1 

 1 E name="to-r1-direct-1" 
     remote.address=172.36.0.1 .as=65001 .id=25.25.25.25 
     .capabilities=mp,rr,as4,err .messages=68 .bytes=5558 .eor=ip 
     local.role=ibgp .address=172.36.0.2 .as=65001 .id=2.2.2.2 
     .capabilities=mp,rr,gr,as4 .messages=8 .bytes=272 .eor="" 
     output.procid=20 .network=connected 
     input.procid=20 ibgp 
     multihop=yes hold-time=3m keepalive-time=1m uptime=5m20s280ms 
     last-started=1970-01-14 15:41:22 prefix-count=79 

Columns: ADDRESS, NETWORK, INTERFACE
# ADDRESS        NETWORK     INTERFACE
0 10.202.1.9/16  10.202.0.0  ether2   
1 172.36.0.2/30  172.36.0.0  ether5   
2 2.2.2.2/32     2.2.2.2     lo       

Flags: X - disabled, F - filtered, U - unreachable, A - active; 
c - connect, s - static, r - rip, b - bgp, o - ospf, i - is-is, d - dhcp, v - vpn, m - modem, a - ldp-address, l - ldp-mapping, g - slaac, y - bgp-mpls-vpn; 
H - hw-offloaded; + - ecmp, B - blackhole 
 Ab   afi=ip4 contribution=active dst-address=10.0.0.1/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.0.2/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.0.3/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.0.4/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.0.5/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.0.6/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.1.1/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.1.2/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050,65052,65051" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.1.3/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050,65052" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.1.4/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050,65053" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.0.1.5/32 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050,65054" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.0/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.4/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.8/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016,65050" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.12/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.16/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.1.0.20/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65014,65016" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.25.0.0/30 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.254 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.25.0.24/29 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.1 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

  b   afi=ip4 contribution=best-candidate dst-address=10.202.0.0/16 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .local-pref=100 .med=0 .atomic-aggregate=no 
       .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.202.7.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65070" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.1/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.1 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.2/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.2 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.3/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.3 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.11/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65081,65083" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.12/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65082,65084" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.13/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65082,65085" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.20/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.253/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.254 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.0.254/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.0.254 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.1.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.1.4/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.1.8/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.2.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.2.4/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.2.8/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.3.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.9.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.10.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=10.255.11.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=25.25.25.25/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .local-pref=100 .med=0 .atomic-aggregate=no 
       .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.7.0.0/29 routing-table=main 
       gateway=172.36.0.1 immediate-gw=172.36.0.1%bridgeLocal distance=200 
       scope=40 target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .local-pref=100 .med=0 .atomic-aggregate=no 
       .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.1.0/25 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.1.128/25 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.2.0/25 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.2.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=200 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.2.128/25 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65284" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.30.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.31.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65899" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.255.14/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=200 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.255.15/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=200 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.16.255.16/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=200 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.20.1.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.20.2.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65000" 
       .originator-id=10.255.255.2 .local-pref=200 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=172.37.0.0/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .originator-id=10.255.255.2 .local-pref=100 
       .med=0 .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.60/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.96/27 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.97/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.98/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.99/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.100/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.101/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.60.128/26 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65062" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65081,65083" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.96/27 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.97/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65282" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.98/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65283" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.99/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65284" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.100/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.101/32 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65016,65061,65281" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.128/25 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=incomplete 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.128/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65282" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.132/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65282" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.136/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65283" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.140/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65283" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.144/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65284" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.80.148/30 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65060,65280,65284" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.81.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65082,65084" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 

 Ab   afi=ip4 contribution=active dst-address=192.168.82.0/24 
       routing-table=main gateway=172.36.0.1 
       immediate-gw=172.36.0.1%bridgeLocal distance=200 scope=40 
       target-scope=30 belongs-to="bgp-IP-172.36.0.1" 
       bgp.peer-cache-id=*2800002 .as-path="65080,65082,65085" 
       .originator-id=10.255.255.2 .local-pref=100 .med=0 
       .atomic-aggregate=no .origin=igp 
       debug.fwp-ptr=0x20242300 


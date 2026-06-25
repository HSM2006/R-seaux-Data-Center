<mxfile host="app.diagrams.net" modified="2026-06-23T05:45:00.000Z" agent="Codex" version="24.7.17" type="device">
  <diagram id="devcloud-current" name="Infra actuelle DEVCloud">
    <mxGraphModel dx="1700" dy="1100" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1700" pageHeight="1200" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <mxCell id="title" value="Infrastructure DEVCloud actuelle - AS 65001" style="text;html=1;strokeColor=none;fillColor=none;fontSize=30;fontStyle=1;fontColor=#0b5394;align=center;" vertex="1" parent="1">
          <mxGeometry x="360" y="30" width="980" height="50" as="geometry" />
        </mxCell>

        <mxCell id="note" value="Note: aucun lien direct spine2 ↔ MikroTik. Le chemin de secours passe par R1 ↔ MikroTik." style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;fontSize=14;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="1060" y="90" width="470" height="60" as="geometry" />
        </mxCell>

        <mxCell id="spine1" value="spine1&lt;br&gt;lo 10.255.0.254/32&lt;br&gt;RR BGP / OSPF / EVPN" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="500" y="160" width="180" height="80" as="geometry" />
        </mxCell>
        <mxCell id="spine2" value="spine2&lt;br&gt;lo 10.255.0.253/32&lt;br&gt;RR BGP / OSPF / EVPN" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="920" y="160" width="180" height="80" as="geometry" />
        </mxCell>
        <mxCell id="leaf1" value="leaf1&lt;br&gt;lo 10.255.0.1/32&lt;br&gt;VLAN10 GW 10.25.0.30/29" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="280" y="420" width="190" height="80" as="geometry" />
        </mxCell>
        <mxCell id="leaf2" value="leaf2&lt;br&gt;lo 10.255.0.2/32&lt;br&gt;VLAN10 / VNI 1010" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="710" y="420" width="190" height="80" as="geometry" />
        </mxCell>
        <mxCell id="leaf3" value="leaf3&lt;br&gt;lo 10.255.0.3/32&lt;br&gt;VLAN10 VNI1010&lt;br&gt;VLAN40 GW 10.192.1.1/24 VNI1040" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="1120" y="420" width="230" height="95" as="geometry" />
        </mxCell>

        <mxCell id="r1" value="R1 perso&lt;br&gt;Gi1 10.202.1.7/16&lt;br&gt;Gi2 172.7.0.1/29&lt;br&gt;Gi3 172.36.0.1/30&lt;br&gt;Lo2 25.25.25.25/32&lt;br&gt;OSPF + iBGP / RR" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="150" y="150" width="210" height="130" as="geometry" />
        </mxCell>
        <mxCell id="mikrotik" value="MikroTik perso&lt;br&gt;10.202.1.9/16&lt;br&gt;ether5 172.36.0.2/30&lt;br&gt;lo 2.2.2.2/32&lt;br&gt;iBGP AS65001" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fce5cd;strokeColor=#d79b00;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="150" y="350" width="210" height="110" as="geometry" />
        </mxCell>
        <mxCell id="r1binome" value="R1 binôme&lt;br&gt;10.202.1.12&lt;br&gt;router-id 10.255.255.2&lt;br&gt;annonce DC2: 172.20.2.0/24, 172.16.255.14-16/32" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eadcf8;strokeColor=#9673a6;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="40" y="560" width="280" height="105" as="geometry" />
        </mxCell>
        <mxCell id="dc2" value="DC2 binôme&lt;br&gt;leaf3 VTEP 172.16.255.16&lt;br&gt;web3 10.192.1.22/24&lt;br&gt;web1 172.20.2.10/24" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eadcf8;strokeColor=#9673a6;fontStyle=1;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="1310" y="650" width="250" height="100" as="geometry" />
        </mxCell>

        <mxCell id="web1" value="web1&lt;br&gt;10.25.0.25/29&lt;br&gt;GW 10.25.0.30" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="300" y="650" width="150" height="70" as="geometry" />
        </mxCell>
        <mxCell id="annuaire" value="annuaire&lt;br&gt;10.25.0.26/29&lt;br&gt;GW 10.25.0.30" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="730" y="650" width="150" height="70" as="geometry" />
        </mxCell>
        <mxCell id="dns1" value="dns1&lt;br&gt;10.25.0.27/29&lt;br&gt;GW 10.25.0.30" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="1370" y="520" width="150" height="70" as="geometry" />
        </mxCell>
        <mxCell id="web2" value="web2&lt;br&gt;10.192.1.2/24&lt;br&gt;GW 10.192.1.1&lt;br&gt;VLAN40/VNI1040" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="1135" y="650" width="170" height="85" as="geometry" />
        </mxCell>

        <mxCell id="legend" value="Protocoles internes fabric:&lt;br&gt;• OSPF underlay sur les liens 10.25.0.0/30&lt;br&gt;• iBGP AS65001 entre loopbacks&lt;br&gt;• spine1/spine2 route-reflectors&lt;br&gt;• EVPN/VXLAN: VNI1010 services, VNI1040 binômes&lt;br&gt;• R1 échange les routes externes en iBGP AS65001" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;fontSize=13;align=left;" vertex="1" parent="1">
          <mxGeometry x="460" y="820" width="700" height="125" as="geometry" />
        </mxCell>

        <!-- Spine-leaf links -->
        <mxCell id="e_s1_l1" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine1 eth1 10.25.0.2/30&lt;br&gt;leaf1 eth1 10.25.0.1/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine1" target="leaf1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_s2_l1" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine2 eth1 10.25.0.6/30&lt;br&gt;leaf1 eth2 10.25.0.5/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine2" target="leaf1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_s1_l2" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine1 eth2 10.25.0.10/30&lt;br&gt;leaf2 eth1 10.25.0.9/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine1" target="leaf2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_s2_l2" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine2 eth2 10.25.0.14/30&lt;br&gt;leaf2 eth2 10.25.0.13/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine2" target="leaf2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_s1_l3" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine1 eth3 10.25.0.18/30&lt;br&gt;leaf3 eth1 10.25.0.17/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine1" target="leaf3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_s2_l3" value="OSPF underlay + iBGP/EVPN&lt;br&gt;spine2 eth3 10.25.0.22/30&lt;br&gt;leaf3 eth2 10.25.0.21/30" style="endArrow=none;html=1;rounded=0;strokeColor=#6c8ebf;fontSize=11;" edge="1" parent="1" source="spine2" target="leaf3"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- External routing links -->
        <mxCell id="e_r1_s1" value="Lien primaire R1 ↔ spine1&lt;br&gt;OSPF: 172.7.0.0/29 apprend loopback spine1&lt;br&gt;iBGP AS65001: 25.25.25.25 ↔ 10.255.0.254&lt;br&gt;R1 Gi2 172.7.0.1/29 | spine1 eth4 172.7.0.3/29" style="endArrow=none;html=1;rounded=0;strokeColor=#b85450;strokeWidth=2;fontSize=11;" edge="1" parent="1" source="r1" target="spine1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_r1_mk" value="Lien direct R1 ↔ MikroTik&lt;br&gt;iBGP AS65001 direct&lt;br&gt;R1 Gi3 172.36.0.1/30&lt;br&gt;MikroTik ether5 172.36.0.2/30" style="endArrow=none;html=1;rounded=0;strokeColor=#d79b00;strokeWidth=2;fontSize=11;" edge="1" parent="1" source="r1" target="mikrotik"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_r1_r1b" value="iBGP AS65001 via réseau salle 10.202.0.0/16&lt;br&gt;R1 10.202.1.7 / Lo2 25.25.25.25&lt;br&gt;R1 binôme 10.202.1.12&lt;br&gt;échange routes DC2" style="endArrow=none;html=1;rounded=0;dashed=1;strokeColor=#9673a6;strokeWidth=2;fontSize=11;" edge="1" parent="1" source="r1" target="r1binome"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_mk_r1b" value="Pas de lien vers spine2 perso&lt;br&gt;MikroTik perso seulement relié à R1 perso en 172.36.0.0/30" style="endArrow=none;html=1;rounded=0;dashed=1;strokeColor=#d79b00;fontSize=11;" edge="1" parent="1" source="mikrotik" target="r1binome"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Service links -->
        <mxCell id="e_l1_web1" value="Access VLAN10&lt;br&gt;web1 10.25.0.25/29" style="endArrow=none;html=1;rounded=0;strokeColor=#9673a6;fontSize=11;" edge="1" parent="1" source="leaf1" target="web1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_l2_ann" value="Access VLAN10 / VNI1010&lt;br&gt;annuaire 10.25.0.26/29" style="endArrow=none;html=1;rounded=0;strokeColor=#9673a6;fontSize=11;" edge="1" parent="1" source="leaf2" target="annuaire"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_l3_dns" value="Access VLAN10 / VNI1010&lt;br&gt;dns1 10.25.0.27/29" style="endArrow=none;html=1;rounded=0;strokeColor=#9673a6;fontSize=11;" edge="1" parent="1" source="leaf3" target="dns1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_l3_web2" value="Access VLAN40 / VNI1040&lt;br&gt;web2 10.192.1.2/24&lt;br&gt;GW leaf3 10.192.1.1" style="endArrow=none;html=1;rounded=0;strokeColor=#9673a6;fontSize=11;" edge="1" parent="1" source="leaf3" target="web2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="e_l3_dc2" value="VXLAN inter-binôme VNI1040 UDP/4789&lt;br&gt;VTEP local leaf3 10.255.0.3&lt;br&gt;VTEP distant DC2 leaf3 172.16.255.16&lt;br&gt;réseau containers 10.192.1.0/24" style="endArrow=none;html=1;rounded=0;dashed=1;strokeColor=#674ea7;strokeWidth=2;fontSize=11;" edge="1" parent="1" source="leaf3" target="dc2"><mxGeometry relative="1" as="geometry" /></mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

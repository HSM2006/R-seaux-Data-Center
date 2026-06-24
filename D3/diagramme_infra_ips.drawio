<mxfile host="app.diagrams.net" modified="2026-06-17T09:45:00.000Z" agent="Codex" version="24.7.17" type="device">
  <diagram id="devcloud-frr-evpn" name="DevCloud FRR EVPN-VXLAN">
    <mxGraphModel dx="1600" dy="1000" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1000" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <mxCell id="title" value="DevCloud Leaf-Spine FRR - OSPF underlay / iBGP EVPN AS 65001 / EVPN-VxLAN L2 overlay" style="text;html=1;strokeColor=none;fillColor=none;fontSize=24;fontStyle=1;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;" vertex="1" parent="1">
          <mxGeometry x="270" y="20" width="1060" height="40" as="geometry"/>
        </mxCell>

        <mxCell id="note" value="Services VLAN 10 / VNI 1010 - reseau 10.25.0.24/29 - pas de VRF" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="520" y="80" width="560" height="45" as="geometry"/>
        </mxCell>

        <mxCell id="spine1" value="spine1&#xa;lo 10.255.0.254/32&#xa;FRR RR EVPN" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontSize=15;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="430" y="160" width="190" height="90" as="geometry"/>
        </mxCell>
        <mxCell id="spine2" value="spine2&#xa;lo 10.255.0.253/32&#xa;FRR RR EVPN" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontSize=15;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="980" y="160" width="190" height="90" as="geometry"/>
        </mxCell>

        <mxCell id="leaf1" value="leaf1&#xa;lo 10.255.0.1/32&#xa;VTEP" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontSize=15;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="210" y="470" width="190" height="90" as="geometry"/>
        </mxCell>
        <mxCell id="leaf2" value="leaf2&#xa;lo 10.255.0.2/32&#xa;VTEP" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontSize=15;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="705" y="470" width="190" height="90" as="geometry"/>
        </mxCell>
        <mxCell id="leaf3" value="leaf3&#xa;lo 10.255.0.3/32&#xa;VTEP" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;fontSize=15;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="1200" y="470" width="190" height="90" as="geometry"/>
        </mxCell>

        <mxCell id="web1" value="web1&#xa;10.25.0.25/29&#xa;HTTP: site web mouhamadi" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="130" y="770" width="220" height="80" as="geometry"/>
        </mxCell>
        <mxCell id="annuaire" value="annuaire&#xa;10.25.0.26/29" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="690" y="770" width="220" height="80" as="geometry"/>
        </mxCell>
        <mxCell id="dns1" value="dns1 / unbound&#xa;10.25.0.27/29&#xa;mouhamadi.local" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="1060" y="770" width="220" height="80" as="geometry"/>
        </mxCell>
        <mxCell id="web2" value="web2&#xa;10.25.0.28/29&#xa;HTTP OK" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="1370" y="770" width="180" height="80" as="geometry"/>
        </mxCell>

        <mxCell id="e-l1-s1" value="10.25.0.0/30&#xa;leaf1 eth1 .1  |  spine1 eth1 .2" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf1" target="spine1"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-l1-s2" value="10.25.0.4/30&#xa;leaf1 eth2 .5  |  spine2 eth1 .6" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf1" target="spine2"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-l2-s1" value="10.25.0.8/30&#xa;leaf2 eth1 .9  |  spine1 eth2 .10" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf2" target="spine1"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-l2-s2" value="10.25.0.12/30&#xa;leaf2 eth2 .13  |  spine2 eth2 .14" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf2" target="spine2"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-l3-s1" value="10.25.0.16/30&#xa;leaf3 eth1 .17  |  spine1 eth3 .18" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf3" target="spine1"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-l3-s2" value="10.25.0.20/30&#xa;leaf3 eth2 .21  |  spine2 eth3 .22" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#6c8ebf;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="leaf3" target="spine2"><mxGeometry relative="1" as="geometry"/></mxCell>

        <mxCell id="e-web1" value="VLAN 10 / VNI 1010&#xa;web1 eth1 .25  |  leaf1 eth3" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#b85450;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="web1" target="leaf1"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-annuaire" value="VLAN 10 / VNI 1010&#xa;annuaire eth1 .26  |  leaf2 eth3" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#b85450;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="annuaire" target="leaf2"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-dns1" value="VLAN 10 / VNI 1010&#xa;dns1 eth1 .27  |  leaf3 eth3" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#b85450;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="dns1" target="leaf3"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="e-web2" value="VLAN 10 / VNI 1010&#xa;web2 eth1 .28  |  leaf3 eth4" style="endArrow=none;html=1;rounded=0;strokeWidth=2;strokeColor=#b85450;fontSize=12;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="web2" target="leaf3"><mxGeometry relative="1" as="geometry"/></mxCell>

        <mxCell id="legend" value="Legende: liens bleus = underlay OSPF /30 ; liens rouges = acces services VLAN 10 ; leafs = VTEP ; spines = Route Reflector EVPN" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;fontSize=13;" vertex="1" parent="1">
          <mxGeometry x="390" y="900" width="820" height="50" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

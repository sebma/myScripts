#!/usr/bin/env sh

#Gives and connects to the first PlanetLab available server

upmcGateway=ssh
protocol=ssh
sshCommand="$(which ssh) -t -A -Y -C"
NETMETPlanetLabUser=upmc_netmet2016
planetLabServerList="ple3.ipv6.lip6.fr planetlab3.cesnet.cz planetlab-05.cs.princeton.edu planetlab1.ifi.uio.no planetlab2.tlm.unavarra.es dplanet2.uoc.edu planetlab2.utt.fr dschinni.planetlab.extranet.uni-passau.de planetlab01.dis.unina.it planetlab2.di.unito.it mars.planetlab.haw-hamburg.de ple1.det.uvigo.es planetlab13.net.in.tum.de planetlab2.upm.ro planetlab2.u-strasbg.fr planetlab1.tlm.unavarra.es planetlab-5.eecs.cwru.edu ple2.det.uvigo.es planetlab1.unr.edu planetlab2.rd.tut.fi planetlab-coffee.ait.ie planetlab2.um.es planetlab1.dtc.umn.edu ple1.hpca.ual.es merkur.planetlab.haw-hamburg.de planetlab2.urv.cat ple3.ipv6.lip6.fr ricepl-1.cs.rice.edu planetlab1.postel.org planetlab1.cs.purdue.edu planetlab3.cs.uoregon.edu cs-planetlab3.cs.surrey.sfu.ca planetlab2.csie.nuk.edu.tw planetlab8.millennium.berkeley.edu planetlab4.rutgers.edu planetlab1.jhu.edu pln.zju.edu.cn planetlab2.unr.edu plgmu1.ite.gmu.edu planet1.cs.rochester.edu planetlab1.cs.du.edu planet-lab3.uba.ar pl2.zju.edu.cn planetlab2.cs.okstate.edu planetlab1.extern.kuleuven.be planetlab1.um.es planetlab1.virtues.fi pl1.eng.monash.edu.au onelab1.pl.sophia.inria.fr onelab2.pl.sophia.inria.fr planetlab-2.fhi-fokus.de pl2.eng.monash.edu.au pl1.sos.info.hiroshima-cu.ac.jp planet-lab-node1.netgroup.uniroma2.it planetlab1.net.in.tum.de ple2.cesnet.cz planetlab2.inf.ethz.ch planetlab3.inf.ethz.ch planetlab4.inf.ethz.ch planet-lab-node2.netgroup.uniroma2.it planetvs2.informatik.uni-stuttgart.de planetlab3.di.unito.it planetlab2.informatik.uni-goettingen.de planetlab-tea.ait.ie"

#if [ ssh = $upmcGateway ]
if [ $(hostname) = $upmcGateway ]
then
	for planetLabServer in $planetLabServerList
	do
		$(which nc) -v -z -w 1 $planetLabServer $protocol 2>/dev/null && break
	done
	
	firstPlanetLabAvailableServer=$planetLabServer
#	echo "=> firstPlanetLabAvailableServer = $firstPlanetLabAvailableServer"
	echo "=> Connecting to the first planet Lab server available : $firstPlanetLabAvailableServer as $NETMETPlanetLabUser ..."
	$sshCommand $NETMETPlanetLabUser@$firstPlanetLabAvailableServer
else
	echo "=> ERROR : You must first connect to the UPMC gateway." >&2
	echo "=> INFO : So I will do it for you :) ..." >&2
	echo "=> Please rerun <$(basename $0)>" >&2
	echo >&2
	$sshCommand $upmcGateway
fi

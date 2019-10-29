#!/usr/bin/env sh

myOpenRepos="Acce BloodyFoxy CepiPerez Dax DrYak HtheB Larswad MSameer Mariusmssj MartinK Matoking Mister_Magister Morpog NielDK Osanwe Penguin Rikudou_Sennin RobertMe Schturman Sfiet_Konstantin Simom Thaodan V10lator ade backpackjoe balta basil beidl birdzhang bulkin bwalter cnlpete coderus cornedor dcaliste eatdirt edgley ellefj equeim fface forgrimm fravaccaro halftux iKozzz ilpianista inte jabbounet jobe kelvan kimmoli krobelus kuba77 leppa llelectronics lourens marco73f matolainen mikel83 mitakuuluu neochapay omnight osetr r0kk3rz ruedigergad rzr sailfish_lib steffen_f taixzo titilambert tunp vasvlad vevgeniev walokra yoktobit yuvraaj"

set -x
for repo in $myOpenRepos
do
	repoURL=http://sailfish.openrepos.net/$repo/personal/main
	ssu repos | grep -q $repoURL || ssu addrepo $repo $repoURL
done
ssu updaterepos
ssu repos

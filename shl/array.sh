#/bin/sh -x

declare -a Tab=(192.32.139.29 192.170.0.157 192.32.139.30 192.170.0.158 192.32.139.137 192.170.0.159)
declare -a Tab1=(192.32.139.29 192.32.139.30 192.32.139.137)
declare -a Tab2=(192.170.0.157 192.170.0.158 192.170.0.159)

NbElem=${#Tab[@]}

seq -s' ' 1 10

echo "NbElem=$NbElem"
echo "Tab = $Tab"
echo -e "Tab[@] = ${Tab[@]}\n"

declare -i Even
declare -i I
declare -i J
for((I=0;I<NbElem;I++))
do
	let Odd=I%2
	#Si l'index du Tableau est impair
	[ "$Odd" = "1" ] && {
	  echo "COUCOU"
	  echo "-> Tab[$(expr $I - 1)] = ${Tab[$I-1]}"
	  echo "-> Tab[$I] = ${Tab[$I]}"
	}	
done

echo -e "\n -> NEXT METHOD !"
I=0
for Elem in ${Tab[@]}
do
	let Odd=I%2
	#Si l'index du Tableau est impair
  [ "$Odd" = "1" ] && {
	  echo "COUCOU"
	  echo "-> Elem[$(expr $I - 1)] = $precedent"
	  echo "-> Elem[$I] = $Elem"
	}
	precedent=$Elem
	let I++
done

echo -e "\n -> NEXT METHOD !"
[ "$(expr $NbElem % 2)" = "0" ] && {
	for((J=0;J<=NbElem/2+1;J+=2))
	do
	  echo "-> Tab[$J] = ${Tab[$J]}"
	  echo "-> Tab[$(expr $J + 1)] = ${Tab[$J+1]}"
	done
}

echo -e "\n -> NEXT METHOD !"
for((J=0;J<NbElem/2;J++))
do
	  echo "-> Tab1[$J] = ${Tab1[$J]}"
	  echo "-> Tab2[$J] = ${Tab2[$J]}"
done

echo -e "\n -> NEXT METHOD !"
for((I=0;I<=NbElem/2+1;I+=2))
do
  ipsrc=${Tab[$I]}
	ipdst=${Tab[$I+1]}
  echo -e "ipsrc = $ipsrc\tipdst = $ipdst"
done

echo -e "\n -> NEXT METHOD !"
declare -i I=0,J=0
for ipsrc in ${Tab1[@]}
do
	J=0
	for ipdst in ${Tab2[@]}
	do
	  #echo "I = $I\tJ = $J"
	  if [ "$I" = "$J" ] ; then
      echo -e "ipsrc = $ipsrc\tipdst = $ipdst"
		fi
		let J++
	done
	let I++
done


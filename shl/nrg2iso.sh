#!/bin/sh

echo L\'operation de conversion prend environ 6 min !!
read -p "Entrez le nom de l'image NRG sans l'extention: " NRGFileName
echo "-> dd if=${NRGFileName}.nrg of=${NRGFileName}.iso bs=4k skip=75 ..."
dd if=${NRGFileName}.nrg of=${NRGFileName}.iso bs=4k skip=75

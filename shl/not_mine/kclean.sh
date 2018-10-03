#!/bin/bash

# Historique :
# 1.0 : mode texte uniquement
# 2.0 : Ajout du mode graphique
# 2.1 : légères modifications cosmetiques
# 2.2 : Support des kernel 3.X, ajout de --keep-prev
# 3.0 : Utilisation de getopts, refonte du mode terminal, ajout d'un lanceur
# 3.1 : Gestion des nouvelles options en mode graphique, mode term par defaut
# 3.2 : Prise en compte des paquets linux-image-extra* et ajout de --version
# 3.3 : Arret du script si un noyau > au courant est trouve, ajout des 4.X
# 3.4 : Correction de : if [ "FORCE_YES" = "VRAI" ] (Ne provoquait qu'un bug d'affichage)
# 3.5 : Calcul de l'espace disque theoriquement libere
# 3.6 : Correctifs (suppression non fonctionelle en mode graphique)
# 3.7 : Ajout d'un icone et de la dependance a gnome-sudo
# 3.8 : dpkg -p devient dpkg -s
# 3.9 : Prise en compte des noyaux "signed" et "lowlatency"
# 4.0 : Voir: https://forum.ubuntu-fr.org/viewtopic.php?id=242358&p=26

CURRENT_VER=4.0

## Bugs connus
# Une fois les suppressions lancées en mode graphique,
# il n'est pas possible de les interompre 
# L'option force-yes ne fonctionne qu'en mode texte

###################
# Fonctions
###################

function clean_exit
{
    rm -f /tmp/clean_kernel.tmp
    exit $1
}

function display_syntaxe 
{
echo " "
echo " Syntaxe : $0 [options]"
echo " Options disponibles : "
echo "	-t	--term		Lance le script en mode console (mode par defaut)"
echo "	-g	--gui		Lance le script en mode graphique"
echo "	-k	--keep-prev	Conserve automatiquement le noyau precedent" 
echo "	-s	--simulate	Aucune suppression reelle, simple simulation"
echo "	-h	--help		Affichage de la syntaxe"
echo "	-f	--force-yes	Suppression sans aucune demande de confirmation !"
echo "	-v	--version	Informations sur les versions"
echo " "
echo " Exemple d'utilisation en ligne de commande : sudo kclean -k "
echo " "
}

function remove_kernel
{
echo " "
echo " Suppression en cours :"
echo " "
for i in `grep -v "$KERNEL" /tmp/clean_kernel.tmp`
do
    if [ "$SIMULATE" = "VRAI" ]
    then
        echo "Suppression du paquet $i (simple simulation...)  "
    else
        apt-get remove --yes --purge $i
    fi
done
echo " "
echo " -------------- Suppression effectuee ---------------"
echo " "
clean_exit 0
}

# interpretation des parametres

TERMINAL="VRAI"
KEEP_PREV="FAUX"
SIMULATE="FAUX"
HELP="FAUX"
FORCE_YES="FAUX"
VERSION="FAUX"

while getopts ":tgksvf-:" OPT 
do
    # gestion des options longues avec ou sans argument
    [ $OPT = "-" ] && case "${OPTARG%%=*}" in
        term) OPT="t" ;;
        gui) OPT="g" ;;
        keep-prev) OPT="k" ;;
        simulate) OPT="s" ;;
        help) OPT="h" ;;
        force-yes) OPT="f" ;;
        version) OPT="v" ;;
        *) display_syntaxe ; clean_exit 1 ;;
    esac
    # puis gestion des options courtes
    case $OPT in
        t) ;;
        g) TERMINAL="FAUX"  ;;
        k) KEEP_PREV="VRAI" ;;
        s) SIMULATE="VRAI" ;;
        h) HELP="VRAI" ;;
        f) FORCE_YES="VRAI" ;;
        v) VERSION="VRAI" ;;
        *) display_syntaxe ; clean_exit 1 ;;
    esac
done 

## Aide

if [ "$HELP" = "VRAI" ]
then
    display_syntaxe
    clean_exit 0
fi

## Version

if [ "$VERSION" = "VRAI" ]
then
    echo " "
    echo "kclean version $CURRENT_VER"
    head -19 $0 | grep -v bash
    clean_exit 0
fi


## Le script a t-il bien ete lance en tant que root ?

if [ "$USER" != "root" -a "$SIMULATE" = "FAUX" ]
then
    echo " "
    echo " Erreur : Vous devez avoir les droits de root pour supprimer des paquets"
    echo " Avez vous oublie sudo devant le nom du script ?"
    echo " "
    clean_exit 2
fi

## Traitements communs

KERNEL=`uname -r | cut -d '-' -f 1,2`
dpkg -l | grep linux | grep ubuntu | grep ii | awk '{print $2}' | grep -E '2\.6|3\.|4\.' >/tmp/clean_kernel.tmp
dpkg -l | grep linux | grep restricted | grep ii | awk '{print $2}' | grep -E '2\.6|3\.|4\.' >>/tmp/clean_kernel.tmp
dpkg -l | grep linux | grep image| grep ii | awk '{print $2}' | grep -E '2\.6|3\.|4\.' >>/tmp/clean_kernel.tmp
dpkg -l | grep linux | grep headers | grep ii | awk '{print $2}' | grep -E '2\.6|3\.|4\.' >>/tmp/clean_kernel.tmp
dpkg -l | grep linux | grep tools | grep ii | awk '{print $2}' | grep -E '2\.6|3\.|4\.' >>/tmp/clean_kernel.tmp

#On supprime immediatement de la liste le noyau courant :
sed -i -e /$KERNEL/D /tmp/clean_kernel.tmp

#On cherche le noyau precedent
NB_KERNEL=`dpkg -l | grep linux | grep image | grep ^ii | egrep -v "extra|signed|lowlatency" | awk '{print $2}' | grep -E '2\.6|3\.|4\.' | wc -l`
if [ $NB_KERNEL -eq 1 ]
then
    PREVIOUS_V=""
else
    PREVIOUS_V=`dpkg -l | grep linux | grep image | grep ^ii | egrep -v "extra|signed|lowlatency" | awk '{print $2}' | grep -E '2\.6|3\.|4\.' | sort -V | tail -2 | head -1 | cut -d '-' -f3,4`
fi

# On cherche le noyau le plus recent pour le comparer au noyau courant
LAST_KERNEL=`dpkg -l | grep linux | grep image | grep ^ii | egrep -v "extra|signed|lowlatency" | awk '{print $2}' | grep -E '2\.6|3\.|4\.' | sort -V | tail -1 | cut -d '-' -f 3,4`

########  Mode texte ############

if [ "$TERMINAL" = "VRAI" ]
then
    echo " "
    echo "Noyau actuellement en cours d'utilisation : $KERNEL"
    echo "Par defaut, seul ce noyau est conserve."
    echo " "

    if [ "$LAST_KERNEL" != "$KERNEL" ]
    then
    if [ "$FORCE_YES" = "VRAI" ]
        then 
        echo "ATTENTION : Presence de noyau(x) plus recent(s) sur le systeme."
        echo "Ce script va neanmoins poursuivre (utilisation du -f)"
        else
            echo "ATTENTION : Au moins un noyau plus recent ( $LAST_KERNEL ) a ete detecte."
            echo "Ce phenomene peut avoir plusieurs causes mais, par securite,"
            echo "ce script va s'arreter."
            echo " "
            echo "Si vous comprenez exactement ce qui se passe,"
            echo "et si vous souhaitez reelement supprimer tous les noyaux"
            echo "y compris les plus recents, utilisez l'option -f seule."
            clean_exit 4
        fi
    fi

    if [ "$KEEP_PREV" = "VRAI" ]
    then
        echo "Ce script va tenter de trouver la version precedente du noyau pour la conserver."
        if [ "$FORCE_YES" = "FAUX" ]
        then
            echo "Verifiez les informations fournies avant de valider la suppression."
        fi
        echo " "
        if [ -z "$PREVIOUS_V" ]
        then
            echo "Aucune version precedente trouvee, il n'y a donc rien a supprimer."
            echo "Abandon."
            echo " "
            clean_exit 0
        fi
        echo "La version precedemment installee (a conserver) est la version : $PREVIOUS_V"
        sed -i -e /$PREVIOUS_V/D /tmp/clean_kernel.tmp
    fi
 
    if [ `cat /tmp/clean_kernel.tmp |wc -l` -eq 0 ]
    then
        echo "Aucun noyau a supprimer."
        echo "Abandon."
        echo " "
        clean_exit 0
    fi

    #Calcul de l'espace libere
    ESPACEKB=0
    for i in `grep -v "$KERNEL" /tmp/clean_kernel.tmp`
    do
        ESPACEKB=$(($ESPACEKB+`dpkg -s $i | grep Installed-Size | awk '{print $2}'`))
    done
    ESPACEMB=$(($ESPACEKB / 1024))

    echo "Les paquets suivants vont etre supprimes :"
    echo " "
    cat /tmp/clean_kernel.tmp | sed -e "s@^@    @g"
    echo " "
    echo "Cela devrait liberer environ $ESPACEMB MiB d'espace disque"
    echo " "
    
    ## Mode non interactif

    if [ "$FORCE_YES" = "VRAI" ]
    then 
        remove_kernel
    fi

    ## Mode interactif

    echo -n " Voulez vous indiquer manuellement des paquets à conserver ? [o/N] :"
    read REP
    if [ "$REP" = "o" -o "$REP" = "O" ]
    then
        echo " indiquez la liste des paquets à conserver en les separant par un espace : "
        read REP
        for i in `echo "$REP"`
        do
            sed -i -e /$i/D /tmp/clean_kernel.tmp
        done
        echo " "
        echo " Voila la liste des paquets qui seront donc supprimes :"
        echo " "
        grep -v "$KERNEL" /tmp/clean_kernel.tmp | sed -e "s@^@    @g"
        echo " "
    fi
    echo -n " Voulez vous supprimer l'ensemble des paquets indiques ? [o/N] :"
    read REP
    if [ "$REP" = "o" -o "$REP" = "O" ]
    then
        remove_kernel
    else
        echo " "
        echo " Abandon de l'operation..."
        echo " "
        clean_exit 0
    fi
else
	
    ############### Mode graphique ##################

    ## On verifie que zenity est installé
    which zenity > /dev/null
    if [ $? -ne 0 ]
    then
        echo " "
        echo " le mode graphique necessite zenity pour fonctionner."
        echo " Installez zenity ou utilisez uniquement le mode texte."
        echo " "
        clean_exit 3
    fi

    ## On verifie qu'un display graphique est disponible
    if [ -z "$DISPLAY" ]
    then
        echo " "
        echo " Aucun serveur graphique disponible (variable DISPLAY vide)"
        echo " Si vous utilisez un serveur en mode texte uniquement,"
        echo " vous pouvez utiliser ce logiciel en mode console en tapant:"
        echo " "
        echo " $0 --term"
        echo " "
        clean_exit 3
    fi

    ## As t-on bien les droits admin ?
    if [ $USER != "root" ]
    then
        zenity --error --text="Ce programme necessite les droits root pour fonctioner.\nRelancer le en tapant : gksudo $0"
        clean_exit 2
    fi

    if [ "$LAST_KERNEL" != "$KERNEL" ]
    then
        zenity --error --text="Vous utilisez actuellement le noyau $KERNEL\nOr, au moins un noyau plus récent ( $LAST_KERNEL ) a été détecté.\nCe phénomène peut avoir plusieurs causes mais,\npar securité, ce script va s'arreter.\n\nSi vous souhaitez réelement supprimer ce (ou ces) noyaux,\nlancez kclean en ligne de commande."
        clean_exit 4
    fi
    
    ## Faut il conserver le noyau precedent ?
    if [ "$KEEP_PREV" = "FAUX" ]
    then
        zenity --question --text "Voulez vous conservez le noyau précédent ?"
        if [ $? -eq 0 ]
        then
            KEEP_PREV="VRAI"
        fi
    fi
    
    ## Y a t-il vraiment des paquets à supprimer ?
    ## Si il faut conserver le noyau precedent, on le supprime de a liste

    if [ "$KEEP_PREV" = "VRAI" -a ! -z "$PREVIOUS_V" ]
    then
        sed -i -e /$PREVIOUS_V/D /tmp/clean_kernel.tmp
    fi

    TEXT="Le noyau actuellement utilisé a pour verison : <b>$KERNEL</b>.\n"
    if [ "$KEEP_PREV" = "VRAI" -a ! -z "$PREVIOUS_V" ]
    then
        TEXT="$TEXT Le noyau précédent a pour version : $PREVIOUS_V.\n"
    fi
    TEXT="$TEXT Aucun paquet faisant référence à un noyau plus ancien n'a été trouvé sur le système...\n\nAppuyez sur OK pour quitter le programme."

    if [ -z "`grep -v "$KERNEL" /tmp/clean_kernel.tmp`" ]
    then
        zenity --info --title "Netoyage dans les noyaux..." \
        --text="$TEXT"
        clean_exit 0
    fi

    ## Oui, il y a des paquets à supprimer...

    if [ "$FORCE_YES" = "VRAI" ]
    then
        TEXT="ATTENTION : L'option -f (force-yes) n'est pas prise en compte en mode graphique."
        zenity --warning --width=500 --height=200 --title "Netoyage dans les noyaux..." --text="$TEXT"
    fi

    LISTE_PAQUET=""
    ## Construction de la liste des paquets a supprimer pour zenity
    ESPACE_TOTAL=0
    for i in `grep -v "$KERNEL" /tmp/clean_kernel.tmp` 
    do
	ESPACEKB=`dpkg -s $i | grep Installed-Size | awk '{print $2}'`
        ESPACE_TOTAL=$(($ESPACE_TOTAL+$ESPACEKB))
        ESPACEMB=$(($ESPACEKB / 1024))
        LISTE_PAQUET="$LISTE_PAQUET TRUE $i $ESPACEMB"
    done
    ESPACE_TOTAL=$(($ESPACE_TOTAL / 1024))
    TEXT="Vous utilisez actuellement la version <b>$KERNEL</b> de Linux.\n"
    if [ "$KEEP_PREV" = "VRAI" ]
    then
        TEXT="$TEXT Le noyau précédent a pour version : $PREVIOUS_V, il sera conservé.\n"
    fi
    TEXT="$TENT En cliquant sur <b>Valider</b> les paquets suivants seront supprimés:"

    CHOIX=$(zenity \
    --title "Nettoyage dans les noyaux" \
    --text="$TEXT" \
    --width=500 --height=400 \
    --list --print-column="3" --checklist --separator=' ' \
    --column="Supprimer" \
    --column="Nom des paquets" \
    --column="MiB" \
    --print-column=2 \
    $LISTE_PAQUET )

    ## Si on clic sur Annuler...
    if [ $? -ne 0 ]
    then
        clean_exit 2
    fi
    ## Sinon
    
    NBSUP=`echo $CHOIX | wc -w`
    PROGRES=0
    INCREMENT=`expr 100 / $NBSUP`
    (
    for i in `echo $CHOIX`
    do
        if [ "$SIMULATE" = "FAUX" ]
        then
            apt-get remove --purge --yes "$i" >/dev/null 2>&1
        fi
        PROGRES=$(($PROGRES+$INCREMENT))
        echo "$PROGRES"
        echo "# Suppression de $i"
    done
    ) | 
    zenity --progress --width=420 --auto-close --percentage=0 \
    --text="Suppression des paquets sélectionnés..."

    if [ "$SIMULATE" = "FAUX" ]
    then
        TEXTE_FINAL="Les paquets sélectionnés ont bien étés supprimés.\nSi tout était coché, vous avez libéré $ESPACE_TOTAL MiB sur le disque."
    else
        TEXTE_FINAL="Mode simulation terminé, aucun paquet supprimé."
    fi
    
    zenity --info --title "Nettoyage dans les noyaux..." \
    --text="$TEXTE_FINAL"
    clean_exit 0
fi


#!/usr/bin/env bash

#==============================================================================#
#
# dieses Skript wandelt die Kontoauszüge der Postbank aus dem PDF-Format
# erst in das PS-Format, dann in das Text-Format und zum Schluss in ein
# CSV-Format um
#
#==============================================================================#
#
# ACHTUNG!
# Seit Juli 2014 wird von der Postbank ein anderes PDF-Format verwendet!
#
#==============================================================================#

VERSION="v2017081000"

#set -x

if [ -z "${1}" ] ; then
        echo "${0} Datei1.pdf Datei2.pdf Datei3.pdf"
        exit 1
fi

#------------------------------------------------------------------------------#
### Funktion

postbank_pdf2txt_bis_062014()
{
#
# diese Funktion wandelt die Dateien aus dem PDF-Format
# erst in das PS-Format, dann in das Text-Format um
#

#echo "Parameter: ${1} ${2}"

if [ -z "${2}" ] ; then
        echo "${0} Datei1.pdf Datei1"
        exit 1
fi

if [ -z "$(which pdf2ps)" ] ; then
        echo "pdf2ps (Ghostscript) ist nicht installiert"
        exit 1
fi

if [ -z "$(which ps2ascii)" ] ; then
        echo "ps2ascii (Ghostscript) ist nicht installiert"
        exit 1
fi

#echo "pdf2ps ${1} ${2}.ps"
pdf2ps ${1} ${2}.ps

#echo "ps2ascii ${2}.ps > ${2}.txt && rm -f ${2}.ps"
ps2ascii ${2}.ps > ${2}.txt && rm -f ${2}.ps

rm -f ${2}.ps
}

#------------------------------------------------------------------------------#

for _datei in ${@}
do

NEUERNAME="$(echo "${_datei}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

postbank_pdf2txt_bis_062014 ${_datei} ${NEUERNAME}

#------------------------------------------------------------------------------#

(
### Postbank-Reihenfolge
#echo -n "Buchungstag;Wertstellung;PN-Nummer;Buchungsinformation;Betrag;Ist/Soll;Verwendungszweck;"

### 1822-Reihenfolge
echo -n "Buchungstag;Wertstellung;Betrag;Buchungsschlüssel;Buchungsart;Empfänger/Auftraggeber Name;Verwendungszweck;"

cat ${NEUERNAME}.txt | sed 's#a"#ä#g;s#o"#ö#g;s#u"#ü#g;s#A"#Ä#g;s#O"#Ö#g;s#U"#Ü#g' | while read TEXTZEILE
do
      JAHRESZAHL="$(echo "${TEXTZEILE}"|grep -Ea "^Datum [0-9][0-9][.][0-9][0-9][.][0-9][0-9][0-9][0-9]"|awk -F'.' '{print $NF}')"
      if [ -n "${JAHRESZAHL}" ] ; then
              JAHR0="${JAHRESZAHL}"
      fi
      JAHRESZAHL=""

      MONATSZAHL="$(echo "${TEXTZEILE}"|grep -Ea "^Datum [0-9][0-9][.][0-9][0-9][.][0-9][0-9][0-9][0-9]"|awk -F'.' '{print $(NF-1)}')"
      if [ -n "${MONATSZAHL}" ] ; then
              MONAT0="${MONATSZAHL}"
      fi
      MONATSZAHL=""

      INHALT="$(echo "${TEXTZEILE}"|grep -Ea "^[0-9][0-9][.][0-9][0-9][.] [0-9][0-9][.][0-9][0-9][.]")"
      if [ -z "${TEXTZEILE}" ] ; then
              WEITER="NEIN"
              if [ -n "${VERWENDUNGSZWECK}" ] ; then
                      echo -n "${VERWENDUNGSZWECK};"
                      VERWENDUNGSZWECK=""
              fi
      fi

      if [ -z "${INHALT}" ] ; then
              if [ "${WEITER}" == "JA" ] ; then
                      VERWENDUNGSZWECK="${VERWENDUNGSZWECK};${TEXTZEILE}"
              fi
      else
              while read BUCHUNGSDATUM WERTSTELLUNGSDATUM PNN BUCHUNGSINFORMATION0 REST
              do
                      MONAT1="$(echo "${BUCHUNGSDATUM}"|grep -Ea "^[0-9][0-9][.][0-9][0-9][.]"|awk -F'.' '{print $2}')"

                      if [ "${MONAT0}" -lt "${MONAT1}" ] ; then
                              JAHR1="$(echo "${JAHR0}"|awk '{print $1-1}')"
                      else
                              JAHR1="${JAHR0}"
                      fi
                      BUCHUNGSDATUM="$(echo "${BUCHUNGSDATUM}${JAHR1}"|awk -F'.' '{print $3"-"$2"-"$1}')"

                      while read PM1 BETRAG1 BUCHUNGSINFORMATION1
                      do
                              PM2="$(echo "${PM1}" | rev)"
                              BETRAG2="$(echo "${BETRAG1}" | rev)"
                              BUCHUNGSINFORMATION2="$(echo "${BUCHUNGSINFORMATION1}" | rev)"

                              echo ""
                              ### original Postbank-Reihenfolge
                              #echo -n "${BUCHUNGSDATUM};${WERTSTELLUNGSDATUM};${PNN};${BUCHUNGSINFORMATION0} ${BUCHUNGSINFORMATION2};${BETRAG2};${PM2};"

                              ### 1822-Reihenfolge
                              echo -n "${BUCHUNGSDATUM};${WERTSTELLUNGSDATUM};${PM2}${BETRAG2};${PNN};${BUCHUNGSINFORMATION0} ${BUCHUNGSINFORMATION2}"

                              WEITER="JA"

                      done < <(echo "${REST}" | rev)
              done < <(echo "${INHALT}")
      fi
done | sort -n
) > ${NEUERNAME}.csv

rm -f ${NEUERNAME}.txt
ls -lh ${NEUERNAME}.csv

done

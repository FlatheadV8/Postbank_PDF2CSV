#!/usr/bin/env bash

#==============================================================================#
#
# CSV -> QIF (Quicken Interchange Format)
#
#------------------------------------------------------------------------------#
#
# dieses Skript wandelt die mit "postbank_pdf2csv.sh" generieren CSV-Datei in eine QIF-Datei
# für GnuCache um
#
# Quelle (2014-12-07):
# http://wiki.gnucash.org/wiki/FAQ#Q:_How_do_I_convert_from_CSV.2C_TSV.2C_XLS_.28Excel.29.2C_or_SXC_.28OpenOffice.org_Calc.29_to_a_QIF.3F
#
#==============================================================================#

VERSION="v2015060300"

#------------------------------------------------------------------------------#
### Hinweis geben

if [ -z "${1}" ] ; then
        echo "${0} Datei1.csv"
        exit 1
fi

#------------------------------------------------------------------------------#

for CSVDATEI in ${@}
do
	NEUERNAME="$(echo "${CSVDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"
	ZEITSPANNE="$(cat "${CSVDATEI}" | grep -E '^Betrag;Buchung;Wert;Vorgang/Buchungsinformation;' | rev | awk -F';' '{print $1,$2}' | rev)"
	JAHR="$(echo "${ZEITSPANNE}" | awk '{gsub("[.]"," ");print $2}')"

	(echo '!Type:Bank'
	###
	### CSV: Betrag;Buchung;Wert;Vorgang/Buchungsinformation;
	###
	### echo -n "Buchung;Wert;Vorgang/Buchungsinformation;Soll;Haben"
	###
	cat "${CSVDATEI}" | grep -Ev '^Betrag;Buchung;Wert;Vorgang/Buchungsinformation;' | while read ZEILE
	do
		BETRAG="$(echo "${ZEILE}" | awk -F';' '{print $1}')"
		BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR} '{ gsub("[.]"," "); print $2,jahr }' | awk '{print $3"-"$2"-"$1}')"
		VERWENDUNGSZWECK="$(echo "${ZEILE}" | sed 's/;/|/;s/;/|/;' | awk -F'|' '{ print $3 }')"
		echo -e "D${BUCHUNGSDATUM}\nM${VERWENDUNGSZWECK}\nT${BETRAG}\n^"
	done) > ${NEUERNAME}.qif

	ls -lh ${NEUERNAME}.qif
done

#==============================================================================#

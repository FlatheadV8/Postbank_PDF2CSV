#!/usr/bin/env bash

#
# CSV -> QIF (Quicken Interchange Format)
#
#
# dieses Skript wandelt die mit "postbank_pdf2csv.sh" generieren CSV-Datei in eine QIF-Datei
# für GnuCache um
#
# Quelle (2014-12-07):
# http://wiki.gnucash.org/wiki/FAQ#Q:_How_do_I_convert_from_CSV.2C_TSV.2C_XLS_.28Excel.29.2C_or_SXC_.28OpenOffice.org_Calc.29_to_a_QIF.3F
#

if [ -z "${1}" ] ; then
        echo "${0} Datei1.csv"
        exit 1
fi

if [ -z "${JAHR}" ] ; then
        JAHR="$(date +'%Y')"
fi

#------------------------------------------------------------------------------#

for CSVDATEI in ${@}
do
NEUERNAME="$(echo "${CSVDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

(echo '!Type:Bank'
	###
	### echo -n "Buchung;Wert;Vorgang/Buchungsinformation;Soll;Haben"
	###
	cat "${CSVDATEI}" | grep -Ev '^Buchung;' | while read ZEILE
	do
		BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR} '{ gsub("[.]"," "); print $1,jahr }' | awk '{print $3"-"$2"-"$1}')"
		WERTSTELLUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR} '{ gsub("[.]"," "); print $2,jahr }' | awk '{print $3"-"$2"-"$1}')"
		VERWENDUNGSZWECK="$(echo "${ZEILE}" | awk -F';' '{ print $3 }')"
		NEG_BETR="$(echo "${ZEILE}" | awk -F';' '{print $4}' | awk '{print $2}')"
		POS_BETR="$(echo "${ZEILE}" | awk -F';' '{print $5}' | awk '{print $2}')"
		BETRAG="$(if [ -n "${NEG_BETR}" ] ; then echo "-${NEG_BETR}"; elif [ -n "${POS_BETR}" ] ; then echo "+${POS_BETR}"; fi)"
		echo -e "D${BUCHUNGSDATUM}\nM${WERTSTELLUNGSDATUM} ${VERWENDUNGSZWECK}\nT${BETRAG}\n^"
	done
) > ${NEUERNAME}.qif

ls -lh ${NEUERNAME}.qif
done

#==============================================================================#

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

#VERSION="v2015060400"
VERSION="v2017102900"

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

	### ZEITSPANNE='12.2014 01.2015'
	ZEITSPANNE="$(cat "${CSVDATEI}" | grep -E '^Kontoauszug: |^Betrag;Buchung;Wert;Vorgang;Buchungsinformation;' | rev | awk -F';' '{print $1,$2}' | rev)"
	#echo "ZEITSPANNE='${ZEITSPANNE}'"

	### MONAT_BEGINN='12'
	MONAT_BEGINN="$(echo "${ZEITSPANNE}" | awk '{print $1}' | awk -F'.' '{print $1}')"
	#echo "MONAT_BEGINN='${MONAT_BEGINN}'"

	### JAHR_BEGINN='2014'
	JAHR_BEGINN="$(echo "${ZEITSPANNE}" | awk '{print $1}' | awk -F'.' '{print $2}')"
	#echo "JAHR_BEGINN='${JAHR_BEGINN}'"

	### MONAT_ENDE='01'
	MONAT_ENDE="$(echo "${ZEITSPANNE}" | awk '{print $2}' | awk -F'.' '{print $1}')"
	#echo "MONAT_ENDE='${MONAT_ENDE}'"

	### JAHR_ENDE='2015'
	JAHR_ENDE="$(echo "${ZEITSPANNE}" | awk '{print $2}' | awk -F'.' '{print $2}')"
	#echo "JAHR_ENDE='${JAHR_ENDE}'"

	(echo '!Type:Bank'
	###
	### CSV: Betrag;Buchung;Wert;Vorgang;Buchungsinformation
	###
	cat "${CSVDATEI}" | grep -Ev '^Kontoauszug: |^Betrag;Buchung;Wert;Vorgang;Buchungsinformation;' | while read ZEILE
	do
		BETRAG="$(echo "${ZEILE}" | awk -F';' '{print $1}')"

		### BUCHUNGS_MONAT="12"
		BUCHUNGS_MONAT="$(echo "${ZEILE}" | awk -F';' '{print $2}' | awk -F'.' '{print $2}')"
		#echo "BUCHUNGS_MONAT='${BUCHUNGS_MONAT}'"

		if [ "${BUCHUNGS_MONAT}" = "${MONAT_BEGINN}" ] ; then
			BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR_BEGINN} '{ gsub("[.]"," "); print $2,jahr }' | awk '{print $3"-"$2"-"$1}')"
		elif [ "${BUCHUNGS_MONAT}" = "${MONAT_ENDE}" ] ; then
			BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR_ENDE} '{ gsub("[.]"," "); print $2,jahr }' | awk '{print $3"-"$2"-"$1}')"
		else
			BUCHUNGSDATUM=""
		fi

		VERWENDUNGSZWECK="$(echo "${ZEILE}" | sed 's/;/|/;s/;/|/;' | awk -F'|' '{ print $3 }')"

		echo -e "D${BUCHUNGSDATUM}\nM${VERWENDUNGSZWECK}\nT${BETRAG}\n^"
	done) > ${NEUERNAME}.qif

	ls -lh ${NEUERNAME}.qif
done

#==============================================================================#

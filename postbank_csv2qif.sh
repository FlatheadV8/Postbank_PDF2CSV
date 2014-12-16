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

#------------------------------------------------------------------------------#

for CSVDATEI in ${@}
do
NEUERNAME="$(echo "${CSVDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

(echo '!Type:Bank'
	###
	### ACHTUNG!!!
	### Diese Konvertierung funktioniert nur mit der
	### "1822-Reihenfolge"-Einstellung (Standardeinstellung)
	### in der Datei "postbank_pdf2csv.sh",
	### weil der Verwendungszweck (Buchungsinformationen) eine undefinierte
	### Anzahl an Trennzeichen (Semikolon) enthält.
	### Um diese trotzdem sinnvoll verarbeiten zu können, müssen diese
	### Informationen am Ende stehen.
	###
	### echo -n "${BUCHUNGSDATUM};${WERTSTELLUNGSDATUM};${PM2}${BETRAG2};${PNN};${BUCHUNGSINFORMATION0} ${BUCHUNGSINFORMATION2}"
	cat "${CSVDATEI}" | grep -Ev '^Buchung;' | while read ZEILE
	do
		BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' '{ print $1 }')"
		WERTSTELLUNGSDATUM="$(echo "${ZEILE}" | awk -F';' '{ print $2 }')"
		BETRAG="$(echo "${ZEILE}" | awk -F';' '{print $4,$5}' | awk '{print $1,$2}')"
		VERWENDUNGSZWECK="$(echo "${ZEILE}" | awk -F';' '{ print $3 }')"
		echo -e "D${BUCHUNGSDATUM}\nM${WERTSTELLUNGSDATUM} ${VERWENDUNGSZWECK}\nT${BETRAG}\n^"
	done
) > ${NEUERNAME}.qif

ls -lh ${NEUERNAME}.qif
done

#==============================================================================#

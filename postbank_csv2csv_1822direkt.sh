#!/usr/bin/env bash

#
# CSV (Postbank) -> CSV (1822direkt Frankfurter Sparkassen)
#

if [ -z "${1}" ] ; then
        echo "${0} Datei1.csv Datei2.csv Datei3.csv"
        exit 1
fi

if [ -z "${JAHR}" ] ; then
        JAHR="$(date +'%Y')"
fi

#------------------------------------------------------------------------------#

for CSVDATEI in ${@}
do
NEUERNAME="$(echo "${CSVDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

#
# Postbank  : Buchung;Wert;Vorgang/Buchungsinformation;Soll;Haben
# 1822direkt (original): Buchungstag;Wertstellung;Betrag;Buchungsschlüssel;Buchungsart;Empfänger/Auftraggeber Name;Verwendungszweck
# 1822direkt (verkürzt): Buchungstag;Wertstellung;Betrag;Verwendungszweck
#

(echo "Buchungstag;Wertstellung;Betrag;Verwendungszweck"
	cat "${CSVDATEI}" | grep -Ev '^Buchung;' | while read ZEILE
	do
		BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR} '{ gsub("[.]"," "); print $1,jahr }' | awk '{print $3"-"$2"-"$1}')"
		WERTSTELLUNGSDATUM="$(echo "${ZEILE}" | awk -F';' -v jahr=${JAHR} '{ gsub("[.]"," "); print $2,jahr }' | awk '{print $3"-"$2"-"$1}')"
		VERWENDUNGSZWECK="$(echo "${ZEILE}" | awk -F';' '{ print $3 }')"
		NEG_BETR="$(echo "${ZEILE}" | awk -F';' '{print $4}' | awk '{print $2}')"
		POS_BETR="$(echo "${ZEILE}" | awk -F';' '{print $5}' | awk '{print $2}')"
		BETRAG="$(if [ -n "${NEG_BETR}" ] ; then echo "-${NEG_BETR}"; elif [ -n "${POS_BETR}" ] ; then echo "+${POS_BETR}"; fi)"
		echo "${BUCHUNGSDATUM};${WERTSTELLUNGSDATUM};${BETRAG};${VERWENDUNGSZWECK}"
	done
) > ${NEUERNAME}_1822direkt.csv

ls -lh ${NEUERNAME}_1822direkt.csv
done

#==============================================================================#

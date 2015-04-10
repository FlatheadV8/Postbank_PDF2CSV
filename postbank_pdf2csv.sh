#!/bin/bash

#==============================================================================#
#
# PDF -> PS -> TXT -> CSV
#
#==============================================================================#

#------------------------------------------------------------------------------#
### Eingabeüberprüfung

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ -z "${1}" ] ; then
	echo "${0} Kontoauszug_der_Postbank.pdf"
	exit 1
fi

#------------------------------------------------------------------------------#
### Betriebssystem-Werkzeug-Name setzen

if [ "$(uname -o)" = "FreeBSD" ] ; then
        UMDREHEN="tail -r"
elif [ "$(uname -o)" = "GNU/Linux" ] ; then
        UMDREHEN="tac"
else
        echo "Dieses Skript funktioniert nur mit FreeBSD und Linux."
        exit 1
fi

#------------------------------------------------------------------------------#
### Hinweis geben

echo "
================================================================================
=> das kann jetzt ein paar Minuten dauern ...
================================================================================
"

VERZEICHNIS="$(dirname ${0})"

for PDFDATEI in ${@}
do

	#----------------------------------------------------------------------#
	### PDF -> PS -> TXT -> CSV

	#----------------------------------------------------------------------#
	### Dateiname ermitteln

	unset NEUERNAME
	NEUERNAME="$(echo "${PDFDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

	#----------------------------------------------------------------------#
	### Datei initialisieren

	### Originalreihenfolge
	#echo "Betrag;Vorgang/Buchungsinformation;Buchung;Wert;" > ${NEUERNAME}.csv

	### bevorzugte Reihenfolge
	echo "Betrag;Buchung;Wert;Vorgang/Buchungsinformation;" > ${NEUERNAME}.csv

	#----------------------------------------------------------------------#
	### Anzahl der Seiten in der PDF-Datei ermitteln

	SEITEN="$(pdftohtml -c -i -xml -enc UTF-8 -noframes -nodrm -hidden "${PDFDATEI}" ${NEUERNAME}_alle_Seiten.xml | nl | awk '{print $1}' ; rm -f ${NEUERNAME}_alle_Seiten.xml)"

	#----------------------------------------------------------------------#
	### Datei seitenweise umwandeln

	for i in ${SEITEN}
	do
		### PDF -> PS -> TXT
		pdftops -f ${i} -l ${i} "${PDFDATEI}" ${NEUERNAME}_Seite_${i}.ps >/dev/null
		pstotext ${NEUERNAME}_Seite_${i}.ps > ${NEUERNAME}_Seite_${i}.txt
		rm -f ${NEUERNAME}_Seite_${i}.ps

	#----------------------------------------------------------------------#
	### TXT -> CSV
	#
	### die Textdatei in Buchungsbloecke umwandeln
	### und diese dann in CSV-Zeiloen umwandeln

	### die ganze Datei in eine Zeile zmwandeln
	cat ${NEUERNAME}_Seite_${i}.txt | tr -s '\n' '|' > ${NEUERNAME}_Seite_${i}.txt_1

	### den unbrauchbaren Anfang entfernen
	sed -ie 's#^.*Haben|Soll|Vorgang/Buchungsinformation|Wert|Buchung|##;' ${NEUERNAME}_Seite_${i}.txt_1

	### hinter den Buchungsdaten einen Zeilenumbruch einbauen
	sed -ie 's/[|][0-3][0-9][.][0-1][0-9][.][|][0-3][0-9][.][0-1][0-9][.][|]/&\`/g;' ${NEUERNAME}_Seite_${i}.txt_1
	#sed -ie 's/Sie m.chten unsere Angaben nicht mehr erhalten?.*//;' ${NEUERNAME}_Seite_${i}.txt_1
	#sed -ie 's/Mit freundlichen Gr..en.*//;' ${NEUERNAME}_Seite_${i}.txt_1
	cat ${NEUERNAME}_Seite_${i}.txt_1 | tr -s '[`]' '\n' > ${NEUERNAME}_Seite_${i}.txt_2

	### Werbung und Hinweise entfernen
	sed -ie 's/[|][ \t]*$//;s/^Postbank K.*ln|Postfach|51222 K.*$//;' ${NEUERNAME}_Seite_${i}.txt_2
	sed -ie 's/Summe Zahlungseing.*nge|BLZ|Kontonummer|.*//;' ${NEUERNAME}_Seite_${i}.txt_2
	sed -ie 's/^Der Abschluss gilt als genehmigt, wenn Sie Ihre Einwendungen nicht binnen sechs Wochen seit Zugang dieses Abschlusses.*//;' ${NEUERNAME}_Seite_${i}.txt_2
	sed -ie 's/^EUR|Zinsen, Porto, Versandentgelte und Entgelte.*//;' ${NEUERNAME}_Seite_${i}.txt_2
	sed -ie 's/^.nderung der Allgemeinen Gesch.ftsbedingungen zum.*//;' ${NEUERNAME}_Seite_${i}.txt_2

	mv ${NEUERNAME}_Seite_${i}.txt_2 ${NEUERNAME}_Seite_${i}.txt_
	cat ${NEUERNAME}_Seite_${i}.txt_ | egrep -v '^$' | while read ZEILE
	do
#		echo "--------------------------------------------------------"
        	BLOCK="$(echo "${ZEILE}" | tr -s '|' '\n')"
        	#echo "${BLOCK}" | tail -n +2 | ${UMDREHEN} | tail -n +3 | ${UMDREHEN}

        	ERSTEZEILE="$(echo "${BLOCK}" | head -n1)"
        	ALLERLETZT="$(echo "${BLOCK}" | tail -n1)"
        	VORLETZTEZ="$(echo "${BLOCK}" | tail -n2 | head -n1)"

		# ueberpruefen ob es eine Buchung mit Betrag ist oder nicht
        	BETRAG="$(echo "${ERSTEZEILE}" | grep -E " [0-9][0-9.]*[,][0-9][0-9]*")"
        	if [ -n "${BETRAG}" ] ; then
			# es ist eine Buchung mit Betrag
                	BUCHUINFOS="$(echo "${BLOCK}" | tail -n +2 | ${UMDREHEN} | tail -n +3 | ${UMDREHEN} | tr -s '\n' '|' | sed 's#|# / #g')"
        	else
			# es gibt keinen Betrag, kann z.B. der Rechnungsabschluss sein
                	ERSTEZEILE=""
                	BUCHUINFOS="$(echo "${BLOCK}" | ${UMDREHEN} | tail -n +3 | ${UMDREHEN} | tr -s '\n' '|' | sed 's#|# / #g')"
        	fi

		### zum testen
		#echo "
		#================================================================
		#ERSTEZEILE='${ERSTEZEILE}';
		#----------------------------------------------------------------
		#BUCHUINFOS='${BUCHUINFOS}';
		#----------------------------------------------------------------
		#VORLETZTEZ='${VORLETZTEZ}';
		#----------------------------------------------------------------
		#ALLERLETZT='${ALLERLETZT}';
		#----------------------------------------------------------------
		#"

		### Originalreihenfolge
        	#echo "${ERSTEZEILE};${BUCHUINFOS};${VORLETZTEZ};${ALLERLETZT};"

		### bevorzugte Reihenfolge
        	echo "${ERSTEZEILE};${VORLETZTEZ};${ALLERLETZT};${BUCHUINFOS};"
	done

	### aufraeumen
	rm -f ${NEUERNAME}_Seite_${i}.txt*
done >> ${NEUERNAME}.csv

ls -lha ${NEUERNAME}.csv
echo "
libreoffice --calc ${NEUERNAME}.csv
${VERZEICHNIS}/postbank_csv2qif.sh ${NEUERNAME}.csv
------------------------------------------------------------------------"
done

#------------------------------------------------------------------------------#

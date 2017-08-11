#!/usr/bin/env bash

#==============================================================================#
#
# Dieses Skript wandelt die Kontoauszüge der Postbank aus dem PDF-Format
# erst in das CSV-Format um.
#
# Es wird das Paket "poppler-utils" benötigt.
#
#==============================================================================#
#
# PDF -> TXT -> CSV
#
#==============================================================================#
#
# ACHTUNG!
# Seit Juli 2017 wird von der Postbank ein anderes PDF-Format
# für die Kontoauszüge verwendet!
#
#==============================================================================#

VERSION="v2017081102"

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

#==============================================================================#
VERZEICHNIS="$(dirname ${0})"

for PDFDATEI in ${@}
do
	#======================================================================#
	### PDF -> TXT -> CSV

	#----------------------------------------------------------------------#
	### Dateiname ermitteln

	unset NEUERNAME
	NEUERNAME="$(echo "${PDFDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"

	#----------------------------------------------------------------------#
	### die Kontoauszüge der Postbank seit Juli 2017 können so verarbeitet werden
	### PDF -> TXT

	pdftotext -fixed 8 -enc UTF-8 -eol unix "${PDFDATEI}" ${NEUERNAME}.txt
	cat ${NEUERNAME}.txt | sed 's/^­ /-/g' > ${NEUERNAME}_.txt
	rm -f ${NEUERNAME}.txt

	### Kontoauszug: Postbank Giro plus vom 21.07.2017 bis 28.07.2017
	VON_ZEILE="$(cat ${NEUERNAME}_.txt | grep -Ea '        Kontoauszug: Postbank .* vom [0-3][0-9].[0-1][0-9].20[0-9][0-9] bis [0-3][0-9].[0-1][0-9].20[0-9][0-9]')"
	MONAT_JAHR_VON="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//' | awk -F'.' '{print $3"-"$2"-"$1}')"
	MONAT_JAHR_BIS="$(echo "${VON_ZEILE}" | sed 's/.* bis //' | awk -F'.' '{print $3"-"$2"-"$1}')"
	VON_DATUM="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//' | awk -F'.' '{print $2$1}')"
	VON_JAHR="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//;s/.*[.]//')"
	BIS_JAHR="$(echo "${VON_ZEILE}" | sed 's/.* bis //;s/.*[.]//')"

	ERSTE_ZEILE='          Buchung/Wert'
	ZWEITE_ZEILE='                  Vorgang/Buchungsinformation            Soll      Haben'
	LETZTE_ZEILE='          Kontonummer         BLZ                Summe Zahlungseingänge'

	#ls -lha ${NEUERNAME}_.txt
	cat ${NEUERNAME}_.txt | \
		sed -ne "/          Buchung[/]Wert/,/${LETZTE_ZEILE}/p" | \
		grep -Fv "${ERSTE_ZEILE}" | \
		grep -Fv "${ZWEITE_ZEILE}" | \
		grep -Fv "${LETZTE_ZEILE}" > \
		${NEUERNAME}.txt

	rm -f ${NEUERNAME}_.txt

	#echo "
	#========================================================
	# VON_ZEILE='${VON_ZEILE}';
	#--------------------------------------------------------
	# VON_DATUM='${VON_DATUM}';
	# VON_JAHR='${VON_JAHR}';
	# BIS_JAHR='${BIS_JAHR}';
	#--------------------------------------------------------
	#"
	#exit

	#----------------------------------------------------------------------#
	### TXT -> CSV
	#
	### die Textdatei in Buchungsbloecke umwandeln
	### und diese dann in CSV-Zeilen umwandeln

	#----------------------------------------------------------------------#
	### CSV-Datei initialisieren

	# Konto-Informationen
	echo "${VON_ZEILE}" | sed 's/^[ ][ ]*//' > ${NEUERNAME}.csv

	#----------------------------------------------------------------------#
	### Tabellenkopf

	### Originalreihenfolge
	#echo "Betrag;Vorgang/Buchungsinformation;Buchung;Wert;${MONAT_JAHR_VON};${MONAT_JAHR_BIS}" >> ${NEUERNAME}.csv

	### bevorzugte Reihenfolge
	#echo "'${MONAT_JAHR_VON};'"
	#echo "'${MONAT_JAHR_BIS};'"
	#echo "Betrag;Buchung;Wert;Vorgang/Buchungsinformation;${MONAT_JAHR_VON};${MONAT_JAHR_BIS}"
	echo "Betrag;Buchung;Wert;Vorgang;Buchungsinformation;${MONAT_JAHR_VON};${MONAT_JAHR_BIS}" >> ${NEUERNAME}.csv

	#----------------------------------------------------------------------#
	### Textdatei Zeilenweise in das CSV-Format umwandeln

	#ls -lha ${NEUERNAME}.txt
	cat ${NEUERNAME}.txt | sed 's/^$/|/' | tr -s '\n' '³' | tr -s '|' '\n' | tr -s '³' '|' | grep -Eva '^$|^[|]$' | while read ZEILE
	do
		#echo "-0----------------------------------------------"
       		#echo "ZEILE='${ZEILE}'"
       		BLOCK="$(echo "${ZEILE}" | sed 's/|/³/;s/|/³/;s/|/³/;s/|/ /g' | tr -s '³' '\n' | tr -s '|' '\n' | grep -Eva '^$' | sed 's/^[ ][ ]*//;s/[ ] [ ]*$//')"
       		#echo "³${BLOCK}³"

		#echo "-1----------------------------------------------"
       		BUCHUNG="$(echo "${BLOCK}" | head -n1 | tr -s '/' '\n' | head -n1 | awk '{print $1}' | awk -F'.' '{print $2"-"$1}')"	# erste Zeile, erste Spalte
		#echo "-2----------------------------------------------"
       		WERT="$(echo "${BLOCK}" | head -n1 | tr -s '/' '\n' | tail -n1 | awk '{print $1}' | awk -F'.' '{print $2"-"$1}')"	# erste Zeile, zweite Spalte
		#echo "-3----------------------------------------------"
       		BETRAG="$(echo "${BLOCK}" | head -n2 | tail -n1 | awk '{print $(NF-1),$NF}')"						# zweite Zeile, beide letzte Spalten
		#echo "-4----------------------------------------------"
       		VORGANG="$(echo "${BLOCK}" | head -n2 | tail -n1 | sed "s/[ ]*${BETRAG}//;s/^[ ][ ]*//;s/[ ] [ ]*$//")"			# zweite Zeile, beide letzte Spalten
		#echo "-5----------------------------------------------"
       		BUCHUNGSINFO="$(echo "${BLOCK}" | tail -n1)"										# letzte Zeile

		#========================================================
		### das Datum um das richtige Jahr ergänzen

		#--------------------------------------------------------
		B_ZIFFERN="$(echo "${BUCHUNG}" | awk -F'-' '{print $1$2}')"

		#echo "
		# B_ZIFFERN='${B_ZIFFERN}';
		# VON_DATUM='${VON_DATUM}';
		#"

		if [ "${B_ZIFFERN}" -lt "${VON_DATUM}" ] ; then
			DATUM_BUCHUNG="${BIS_JAHR}-${BUCHUNG}";
		else
			DATUM_BUCHUNG="${VON_JAHR}-${BUCHUNG}";
		fi

		#--------------------------------------------------------
		W_ZIFFERN="$(echo "${WERT}" | awk -F'-' '{print $1$2}')"

		#echo "
		# W_ZIFFERN='${W_ZIFFERN}';
		# VON_DATUM='${VON_DATUM}';
		#"

		if [ "${W_ZIFFERN}" -lt "${VON_DATUM}" ] ; then
			DATUM_WERT="${BIS_JAHR}-${WERT}";
		else
			DATUM_WERT="${VON_JAHR}-${WERT}";
		fi

		#========================================================
		### zum testen

		#echo "
		#========================================================
		# BETRAG='${BETRAG}';
		#--------------------------------------------------------
		# BUCHUNG='${BUCHUNG}';
		# DATUM_BUCHUNG='${DATUM_BUCHUNG}';
		#--------------------------------------------------------
		# WERT='${WERT}';
		# DATUM_WERT='${DATUM_WERT}';
		#--------------------------------------------------------
		# VORGANG='${VORGANG}';
		#--------------------------------------------------------
		# BUCHUINFOS='${BUCHUINFOS}';
		#--------------------------------------------------------
		#"

		#--------------------------------------------------------
		### Reihenfolge der Ausgabe
       		echo "${BETRAG};${DATUM_BUCHUNG};${DATUM_WERT};${VORGANG};${BUCHUNGSINFO};" | sed 's/[ ][ ]*/ /g' >> ${NEUERNAME}.csv

		unset BLOCK
		unset BUCHUNG
		unset WERT
		unset BETRAG
		unset VORGANG
		unset BUCHUNGSINFO
		unset B_ZIFFERN
		unset W_ZIFFERN
		unset DATUM_BUCHUNG
		unset DATUM_WERT
	done

	#exit

	#----------------------------------------------------------------------#
	### aufräumen
	rm -f ${NEUERNAME}.txt

	#----------------------------------------------------------------------#
	### Ergebnisse anzeigen

	ls -lha ${NEUERNAME}.csv

done
#==============================================================================#

#------------------------------------------------------------------------------#
### Hinweise anzeigen

echo "
libreoffice --calc ${NEUERNAME}.csv
${VERZEICHNIS}/postbank_csv2qif.sh ${NEUERNAME}.csv
------------------------------------------------------------------------"

#------------------------------------------------------------------------------#

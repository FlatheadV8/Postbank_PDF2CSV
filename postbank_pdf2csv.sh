#!/usr/bin/env bash

#==============================================================================#
#
# Dieses Skript wandelt die Kontoauszüge der Postbank
# aus dem PDF-Format erst das CSV-Format um.
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

#VERSION="v2017081103"
#VERSION="v2019082500"
#VERSION="v2020091200"		# Fehler behoben
#VERSION="v2021060400"		# ♥ gegen ¶ ausgetauscht
VERSION="v2023013100"		# die RegEx, die die Variable ZEILE_4 füllt, kannte das Tausendertrennzeichen nicht

#------------------------------------------------------------------------------#
### Eingabeüberprüfung

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ -z "${1}" ] ; then
	echo "${0} Kontoauszug_der_Postbank.pdf"
	exit 1
fi

#------------------------------------------------------------------------------#
### Betriebssystem-Werkzeug-Name setzen

if [ "$(uname -o)" = "FreeBSD" ] || [ "$(uname -o)" = "Darwin" ] ; then
        UMDREHEN="tail -r"
elif [ "$(uname -o)" = "GNU/Linux" ] ; then
        UMDREHEN="tac"
else
        echo "Dieses Skript funktioniert nur mit FreeBSD, Linux oder MacOS."
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

	### Kontoauszug: Postbank Giro plus vom
	cat ${NEUERNAME}.txt | sed 's/^[ ][ ]*Kontoauszug: Postbank Giro plus vom /ABCDEFG_entfernen_GFEDCBA¶&/' | tr -s '¶' '\n' | sed 's/^­ /-/g;/Unser Tipp für Sie:/,//d;/Wichtige Hinweise/,//d' > ${NEUERNAME}_.txt
	rm -f ${NEUERNAME}.txt

	### Kontoauszug: Postbank Giro plus vom 21.07.2017 bis 28.07.2017
	VON_ZEILE="$(cat ${NEUERNAME}_.txt | grep -Ea '        Kontoauszug: Postbank .* vom [0-3][0-9].[0-1][0-9].20[0-9][0-9] bis [0-3][0-9].[0-1][0-9].20[0-9][0-9]')"
	MONAT_JAHR_VON="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//' | awk -F'.' '{print $3"-"$2"-"$1}')"
	MONAT_JAHR_BIS="$(echo "${VON_ZEILE}" | sed 's/.* bis //' | awk -F'.' '{print $3"-"$2"-"$1}')"
	VON_DATUM="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//' | awk -F'.' '{print $2$1}')"
	VON_JAHR="$(echo "${VON_ZEILE}" | sed 's/.* vom //;s/ bis .*//;s/.*[.]//')"
	BIS_JAHR="$(echo "${VON_ZEILE}" | sed 's/.* bis //;s/.*[.]//')"


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


	#         2/6
	#^L          AuszugJahrSeite
	#                        von   IBAN               Übertrag
	#          001   20183   6     DE98 3701 0050 0903 4645 03
	#                                                 EUR              + 297,00

	ZEILE_0='^[ ]+[0-9]+/[0-9]+$'
	ZEILE_1='^.[ ]+AuszugJahrSeite$'
	ZEILE_2='^                        von   IBAN               Übertrag$'
	ZEILE_3='^[ ]+[0-9][0-9][0-9][ ]+[0-9][0-9][0-9][0-9][0-9][ ]+[0-9]+[ ]+[A-Z][A-Z][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9]$'
	ZEILE_4='^[ ]+[A-Z]+[ ]+[+-][ ][0-9][0-9,-.]+$'
	ZEILE_5='^[ \t]*$'
	ERSTE_ZEILE='          Buchung/Wert'
	ZWEITE_ZEILE='                  Vorgang/Buchungsinformation            Soll      Haben'
	LETZTE_ZEILE='          Kontonummer         BLZ                Summe Zahlungseingänge'

	#ls -lha ${NEUERNAME}_.txt
	cat ${NEUERNAME}_.txt | \
		sed -nre "/          Buchung[/]Wert/,/${LETZTE_ZEILE}/p" | \
		grep -Ev "${ZEILE_0}" | \
		grep -Ev "${ZEILE_1}" | \
		grep -Ev "${ZEILE_2}" | \
		grep -Ev "${ZEILE_3}" | \
		grep -Ev "${ZEILE_4}" | \
		grep -Ev "${ZEILE_5}" | \
		grep -Fv "${ERSTE_ZEILE}" | \
		grep -Fv "${ZWEITE_ZEILE}" | \
		grep -Ev "${LETZTE_ZEILE}" > \
		${NEUERNAME}.txt

	rm -f ${NEUERNAME}_.txt


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
	# ☻ 13.12./13.12.; Kartenzahlung ¶- 9,62¶; Shell Deutschland Oil GmbH Referenz; 77777777704300121217777777 Mandat 277777 Einreicher-; ID DE7777772345077777 SHELL 8729// Bad Camberg /DE; Terminal 77777755 2017-12-12T08:58:56 Folgenr. 01 Verfalld.; 1912

	ls -lha ${NEUERNAME}.txt
	cat ${NEUERNAME}.txt | sed 's/[+-] [0-9][0-9]*[0-9,.]*$/¶&¶/;s/^[ ][ ]*[0-3][0-9][.][0-1][0-9][.][/][0-3][0-9][.][0-1][0-9][.]/☻&/' | tr -s '\n' ';' | sed 's/  */ /g;s/^;//;s/;$//' | tr -s '☻' '\n' | grep -Fv 'Rechnungsabschluss - siehe Hinweis' | grep -Ev '^[ ]*$' | while read ZEILE
	do
		#echo "-0----------------------------------------------"
       		BETRAG="$(echo "${ZEILE}" | awk -F'¶' '{print $2}' | sed 's/^[ ][ ]*//')"
		#echo "-1----------------------------------------------"
       		BUCHUNG="$(echo "${ZEILE}" | awk -F';' '{gsub("[ ]+","");print $1}' | awk -F'/' '{print $1}' | awk -F'.' '{print $2"-"$1}' | sed 's/^[ ][ ]*//')"
		#echo "-2-------------------------------------"
       		WERT="$(echo "${ZEILE}" | awk -F';' '{gsub("[ ]+","");print $1}' | awk -F'/' '{print $2}' | awk -F'.' '{print $2"-"$1}' | sed 's/^[ ][ ]*//')"
		#echo "-3-------------------------------------"
       		VORGANG="$(echo "${ZEILE}" | sed 's/¶.*¶//' | awk -F';' '{print $2}' | sed 's/^[ ]*//;s/[ ]*$//' | sed 's/^[ ][ ]*//')"
		#echo "-4----------------------------------------------"
       		BUCHUNGSINFO="$(echo "${ZEILE}" | sed 's/^.*¶.*¶//;s/;//g' | sed 's/^[ ]*//;s/[ ]*$//;s/[;][;]*/,/g;')"

		#echo "
		# ZEILE='${ZEILE}';
		#========================================================
		# BETRAG='${BETRAG}';
		#--------------------------------------------------------
		# BUCHUNG='${BUCHUNG}';
		#--------------------------------------------------------
		# WERT='${WERT}';
		#--------------------------------------------------------
		# VORGANG='${VORGANG}';
		#--------------------------------------------------------
		# BUCHUNGSINFO='${BUCHUNGSINFO}';
		#--------------------------------------------------------
		#"
		#exit


		#========================================================
		### das Datum um das richtige Jahr ergänzen


		#--------------------------------------------------------
		B_ZIFFERN="$(echo "${BUCHUNG}" | awk -F'-' '{print $1$2}')"

		#echo "
		# B_ZIFFERN='${B_ZIFFERN}';
		# VON_DATUM='${VON_DATUM}';
		#"

		if [ "${B_ZIFFERN}" -lt "${VON_DATUM}" ] ; then
			#echo "# B 1"
			DATUM_BUCHUNG="${BIS_JAHR}-${BUCHUNG}";
		else
			#echo "# B 2"
			DATUM_BUCHUNG="${VON_JAHR}-${BUCHUNG}";
		fi

		#--------------------------------------------------------
		W_ZIFFERN="$(echo "${WERT}" | awk -F'-' '{print $1$2}')"

		#echo "
		# W_ZIFFERN='${W_ZIFFERN}';
		# VON_DATUM='${VON_DATUM}';
		#"

		if [ "${W_ZIFFERN}" -lt "${VON_DATUM}" ] ; then
			#echo "# W 1"
			DATUM_WERT="${BIS_JAHR}-${WERT}";
		else
			#echo "# W 1"
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
		# BUCHUNGSINFO='${BUCHUNGSINFO}';
		#--------------------------------------------------------
		#"
		#exit

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

#!/bin/bash


#
# PDF -> XML -> CSV
#


#------------------------------------------------------------------------------#
### Eingabeüberprüfung
if [ -z "${1}" ] ; then
	echo "${0} Kontoauszug_der_Postbank.pdf"
	exit 1
else
	PDFDATEI="${1}"
fi


#------------------------------------------------------------------------------#
### PDF -> XML+TXT

NEUERNAME="$(echo "${PDFDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"
SEITEN="$(pdftohtml -c -i -xml -enc UTF-8 -noframes -nodrm -hidden "${PDFDATEI}" ${NEUERNAME}_alle_Seiten.xml | nl | awk '{print $1}' ; rm -f ${NEUERNAME}_alle_Seiten.xml)"
for i in ${SEITEN}
do
	pdftohtml -c -i -xml -enc UTF-8 -noframes -nodrm -hidden -f ${i} -l ${i} "${PDFDATEI}" ${NEUERNAME}_Seite_${i}.xml >/dev/null
	pdftops -f ${i} -l ${i} "${PDFDATEI}" ${NEUERNAME}_Seite_${i}.ps >/dev/null
	pstotext ${NEUERNAME}_Seite_${i}.ps > ${NEUERNAME}_Seite_${i}.txt
	rm -f ${NEUERNAME}_Seite_${i}.ps
	DATEI_SEITEN="${DATEI_SEITEN} ${NEUERNAME}_Seite_${i}"
done

#------------------------------------------------------------------------------#
### XML+TXT -> Text -> XML

XMLDATEIEN="$(for SEITE in ${DATEI_SEITEN}
do
	cat "${SEITE}.xml" | grep -E '^[<]text top=' | awk -F'>' '{print $1}' | nl | while read ZNR POSITION
	do
		echo "${POSITION}>$(cat "${SEITE}.txt" | head -n${ZNR} | tail -n1)</text>"
	done > ${SEITE}.text
	rm -f ${SEITE}.txt
	mv ${SEITE}.text ${SEITE}.xml
	echo "${SEITE}.xml"
done)"
#done | head -n1)"

#------------------------------------------------------------------------------#
### XML -> CSV

echo "Buchung;Wert;Verwendungszweck;Soll;Haben" > ${NEUERNAME}.csv

for EINEXML in ${XMLDATEIEN}
do
	CSVNAME="$(echo "${EINEXML}" | rev | sed 's/.*[.]//' | rev)"
	#----------------------------------------------------------------------#
	### Zeilen- und Spalten-Angaben extrahieren
	### und Zeilen in die richtige Reihenfolge bringen

	NR_XMLDAT="$(cat ${EINEXML} | grep -E '^[<]text ' | while read ZEILE
	do
		SPALTE_01="$(echo "${ZEILE}" | awk -F'>' '{print $1}')"
		TOP="$(echo "${SPALTE_01}" | tr -s ' ' '\n' | grep -E '^top=' | tr -d '"' | awk -F'=' '{print $2}')"
		LEFT="$(echo "${SPALTE_01}" | tr -s ' ' '\n' | grep -E '^left=' | tr -d '"' | awk -F'=' '{print $2}')"
		WIDTH="$(echo "${SPALTE_01}" | tr -s ' ' '\n' | grep -E '^width=' | tr -d '"' | awk -F'=' '{print $2}')"
		HEIGHT="$(echo "${SPALTE_01}" | tr -s ' ' '\n' | grep -E '^height=' | tr -d '"' | awk -F'=' '{print $2}')"
		echo "${TOP} ${LEFT} ${WIDTH} ${HEIGHT} ${ZEILE}"
	done | sort -n)"

	#----------------------------------------------------------------------#
	### Spalten in die richtige Reihenfolge bringen
	#
	# Weil in der PDF- und demzurfolge auch in der XML-Datei die Zeilen und
	# Spalten frei positioniert stehen, ist es für den PDF- bzw. XML-Kode
	# auch legitim, die Zeilen und Spalten dort in einer beliebigen
	# Reihenfolge abzulegen... darum muss das hier sortiert werden.
	#

	ALLE_ZEILENNR="$(echo "${NR_XMLDAT}" | awk '{print $1}' | sort -n | uniq)"
	ZEILEN_SORTIERT="$(for ZEILEN_NR in ${ALLE_ZEILENNR}
	do
		echo "${NR_XMLDAT}" | egrep "^${ZEILEN_NR} " | while read Z_NR ZEILE
		do
			echo "${ZEILE}"
		done | sort -n | sed "s/.*/${ZEILEN_NR} &/"
	done)"

	#----------------------------------------------------------------------#
	### die Werbung (von oben und unten) entfernen

	XML_DATEN="$(echo "${ZEILEN_SORTIERT}" | sed '1,/[>]Haben[<][/]text[>]/d; /[>][<]b[>]/,//d;')"
	ZEILENNR_SORTIERT="$(echo "${XML_DATEN}" | awk '{print $1}' | uniq)"

	#----------------------------------------------------------------------#
	### die Hoehentolleranz muss hier ermittelt werden
	###
	### Die Einträge, die in einer Zeile stehen, weichen in der Höhe u.u.
	### um ein paar Pixel ab.
	### In der Praxis wurden Einträge beobachtet, die um 1/3 Schrifthöhe
	### nach unten versetzt stehen.
	###
	### hier wird eine maximale Abweichung von 1/2 Schrifthöhe
	### nach unten angenommen

	ZEILENNR_TOLLERANZ="$(for ZEILEN_NR in ${ZEILENNR_SORTIERT}
	do
		### Hoehentolleranz berechnen
		H_TOLLERANZ="$(echo "${XML_DATEN}" | egrep "^${ZEILEN_NR} " | grep -Ev '^$' | nl | awk '{z=$5;s+=z}END{printf "%.0f %.0f\n", $2,s/$1/2+$2}')"
		echo "${H_TOLLERANZ}"
	done)"
	#echo "${ZEILENNR_TOLLERANZ}"

	#----------------------------------------------------------------------#
	### Die abweichenden Zeilennummern werden hier korrigiert

	RICHTIGE_XMLDATEN="$(for ZEILEN_NR in ${ZEILENNR_SORTIERT}
	do
		echo "${XML_DATEN}" | egrep "^${ZEILEN_NR} " | while read ZEILEN_NR SPALTEN_NR SPLATEN_BREITE ZEILEN_HOEHE XML_ZEILE
		do
			### Hoehentolleranz berechnen
			RICHTIGE_NUMMER="$(echo "${ZEILENNR_TOLLERANZ}" | awk -v t="${ZEILEN_NR}" '{min=$1;max=$2;if (t >= min) {if (t < max) print min}}' | head -n1)"
			echo "${RICHTIGE_NUMMER} ${SPALTEN_NR} ${SPLATEN_BREITE} ${ZEILEN_HOEHE} ${XML_ZEILE}"
		done
	done)"

	#----------------------------------------------------------------------#
	### die Spaltentrennstellen können nicht automatisch ermittelt werden

	### Tabellenkopf
        #
        #  86 + 41 = 127 - Spalte 1 - Umsatzdatum
        # 162 + 68 = 230 - Spalte 2 - Unternehmen
        # 353 + 16 = 369 - Spalte 3 - Ort
        # 552 + 45 = 597 - Spalte 4 - Währung
        # 649 + 24 = 673 - Spalte 5 - Kurs
        # 722 + 33 = 755 - Spalte 6 - Buch.-datum
        # 786 + 71 = 857 - Spalte 7 - Betrag in EUR

	### eine der wenigen voll beschriebenen Zeilen
        #
        #  47 +  17 =  64  13 3  DB
        #  90 +  30 = 120  13 3  18 03
        # 142 + 111 = 253  13 3  Coop-3657 Vaduz St
        # 353 +  34 = 387  13 3  Vaduz
        # 543 +  30 = 573  13 3  11,20
        # 587 +  25 = 612  13 3  CHF
        # 671 +  37 = 708  13 3  1,2144
        # 725 +  30 = 755  13 3  19 03
        # 835 +  23 = 858  13 3  9,22
        #
        #   1     |     2      |      3             |    4    |     5
        # --------+------------+--------------------+---------+----------
        # Buchung |   Wert     |  Verwendungszweck  | Soll    |  Haben
        # --------+------------+--------------------+---------+----------
        # 113-151 |  176-214   |   240-576          | 655-697 |  752-816
        # --------+------------+--------------------+---------+----------
        #  09.10. |   09.10.   | Coop-3657 Vaduz St |  Vaduz  |   11,20
        #100     170          235                  600       750        820
        #

        ### die von Hand festgelegten Spaltentrennstellen lauten wie folgt
        #
        SPALTEN_TR="100 170 235 600 750 820"

	#----------------------------------------------------------------------#
	### Daten aufarbeiten

	#RICHTIGE_XMLDATEN="$(echo "${RICHTIGE_XMLDATEN}" | head -n3)"
	#echo "RICHTIGE_XMLDATEN='
	#${RICHTIGE_XMLDATEN}'"

	ZEILENNR_SORTIERT="$(echo "${RICHTIGE_XMLDATEN}" | awk '{print $1}' | uniq)"
	for ZEILEN_NR in ${ZEILENNR_SORTIERT}
	do
		SPALTE="0"
		AKTUALLE_ZEILE="$(echo "${RICHTIGE_XMLDATEN}" | egrep "^${ZEILEN_NR} " | while read ZEILEN_NR SPALTEN_NR SPLATEN_BREITE ZEILEN_HOEHE XML_ZEILE
		do
                	XML_DAT="$(echo "${XML_ZEILE}" | awk -F'>' '{print $2}' | awk -F'<' '{print $1}')"
                	echo "${SPALTEN_NR} ${XML_DAT}"
		done)"

		#--------------------------------------------------------------#

		SP_LINKS=""
		for SP_RECHTS in ${SPALTEN_TR}
		do
			if [ -z "${SP_LINKS}" ] ; then
				SP_LINKS="${SP_RECHTS}"
			fi

			echo "${AKTUALLE_ZEILE}" | grep -Ev '^$' | while read SP_PIXEL SP_WERT
			do
				if [ "${SP_PIXEL}" -gt "${SP_LINKS}" ] ; then
					### rechts vom vorhergehenden Spaltentrenner
					if [ "${SP_PIXEL}" -le "${SP_RECHTS}" ] ; then
						### links vom aktuellen Spaltentrenner
						echo -n "${SP_WERT}"
					fi
				fi
			done

			if [ "${SP_LINKS}" -ne "${SP_RECHTS}" ] ; then
				### am Zeilenanfang braucht kein Semikolon
				echo -n ";"
			fi

			### vorhergehenden Spaltentrenner sichern
			SP_LINKS="${SP_RECHTS}"
		done
		echo ""
		#--------------------------------------------------------------#
	done
done >> ${NEUERNAME}.csv

rm -f ${XMLDATEIEN}
ls -lha ${NEUERNAME}.csv
echo "
libreoffice --calc ${NEUERNAME}.csv"

#------------------------------------------------------------------------------#

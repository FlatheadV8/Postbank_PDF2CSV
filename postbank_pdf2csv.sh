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

echo "
das kann jetzt ein paar Minuten dauern ...
"

#------------------------------------------------------------------------------#
### PDF -> XML+TXT

NEUERNAME="$(echo "${PDFDATEI}" | sed 's/[( )][( )]*/_/g' | rev | sed 's/.*[.]//' | rev)"
#SEITEN="$(pdftohtml -c -i -xml -enc UTF-8 -noframes -nodrm -hidden "${PDFDATEI}" ${NEUERNAME}_alle_Seiten.xml | nl | awk '{print $1}' | head -n1 ; rm -f ${NEUERNAME}_alle_Seiten.xml)"
#SEITEN="$(pdftohtml -c -i -xml -enc UTF-8 -noframes -nodrm -hidden "${PDFDATEI}" ${NEUERNAME}_alle_Seiten.xml | nl | awk '{print $1}' | tail -n1 ; rm -f ${NEUERNAME}_alle_Seiten.xml)"
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

#------------------------------------------------------------------------------#
### XML -> CSV

echo "Buchung;Wert;Vorgang/Buchungsinformation;Soll;Haben" > ${NEUERNAME}.csv

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

	XML_DATEN="$(echo "${ZEILEN_SORTIERT}" | sed '1,/[>]Haben[<][/]text[>]/d; /[>][<]b[>]/,//d; /width="0"/d')"
	ZEILENNR_SORTIERT="$(echo "${XML_DATEN}" | awk '{print $1}' | uniq)"

	#----------------------------------------------------------------------#
	### nur weiter machen, wenn auf der Seite Buchungen stehen

	if [ -n "${ZEILENNR_SORTIERT}" ] ; then
	### Begin, Seite bearbeiten

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
        ### die von Hand festgelegten Spaltentrennstellen lauten wie folgt

        SPALTEN_TR="100 170 235 600 750 820"
	ERSTE_SPALTE="$(echo "${SPALTEN_TR}" | awk '{print $1}')"
	ZWEITE_SPALTE="$(echo "${SPALTEN_TR}" | awk '{print $2}')"

	#----------------------------------------------------------------------#
	### alle Zeilen, die zum selben Eintrag gehören, bekommen hier die
	### gleiche Zeilennummer

	XML_DATEN_MIT_NL="$(echo "${RICHTIGE_XMLDATEN}" | while read ZEILEN_NR SPALTEN_NR SPLATEN_BREITE ZEILEN_HOEHE XML_ZEILE
	do
		NEUE_SPALTEN_NR="$(echo "${ZEILEN_NR} ${SPALTEN_NR}" | awk '{print $2 * 1000 + $1}')"
		#echo "${ERSTE_SPALTE}|${ZWEITE_SPALTE}|${SPALTEN_NR}"
		if [ "${ERSTE_SPALTE}" -le "${SPALTEN_NR}" ] ; then
			### rechts vom vorhergehenden Spaltentrenner
			if [ "${ZWEITE_SPALTE}" -ge "${SPALTEN_NR}" ] ; then
               			ZEILENNR1="${ZEILEN_NR}"
			fi
		fi
       		echo "${ZEILENNR1} ${NEUE_SPALTEN_NR} ${SPALTEN_NR} ${SPLATEN_BREITE} ${ZEILEN_HOEHE} ${XML_ZEILE}"
	done)"
	ZEILEN_NR_SORTIERT="$(echo "${XML_DATEN_MIT_NL}" | awk '{print $1}' | uniq)"
#echo "
#--------------------------------------------------------------------------------
#XML_DATEN_MIT_NL='${XML_DATEN_MIT_NL}'"
#ZEILEN_NR_SORTIERT=""

	#----------------------------------------------------------------------#
	### Daten aufarbeiten

	for Z_NR in ${ZEILEN_NR_SORTIERT}
	do
		SPALTE="0"
                AKTUALLE_ZEILE="$(echo "${XML_DATEN_MIT_NL}" | egrep "^${Z_NR} " | while read ZZ_NR NEUE_SPALTEN_NR SPALTEN_NR SPLATEN_BREITE ZEILEN_HOEHE XML_ZEILE
                do
                        XML_DAT="$(echo "${XML_ZEILE}" | awk -F'>' '{print $2}' | awk -F'<' '{print $1}')"
                        echo "${NEUE_SPALTEN_NR} ${SPALTEN_NR} ${XML_DAT}"
                done | sort -n | while read NEUE_SPALTEN_NR DIE_ZEILE
		do
                        echo "${DIE_ZEILE}"
		done)"

		#--------------------------------------------------------------#

                ZEILE_SPALTEN="$(echo "${AKTUALLE_ZEILE}" | awk '{print $1}' | sort -n | uniq)"
                SORTIERTE_ZEILE="$(for SP_NR in ${ZEILE_SPALTEN}
		do
			echo "${SP_NR} $(echo "${AKTUALLE_ZEILE}" | egrep "^${SP_NR} " | while read  SP_NR DIE_ZEILE
                	do
                        	echo "${DIE_ZEILE},"
			done | tr -s '\n' ' ' | sed 's/[,] $//')"
		done)"

		#--------------------------------------------------------------#

		SP_LINKS=""
		for SP_RECHTS in ${SPALTEN_TR}
		do
			if [ -z "${SP_LINKS}" ] ; then
				SP_LINKS="${SP_RECHTS}"
			fi

			echo "${SORTIERTE_ZEILE}" | grep -Ev '^$' | while read SP_PIXEL SP_WERT
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

	#----------------------------------------------------------------------#
	### nur weiter machen, wenn auf der Seite Buchungen stehen

	fi
	### Ende, Seite bearbeiten

done | sed '/^Kontonummer;;BLZSumme Zahlungseing/,//d' >> ${NEUERNAME}.csv

rm -f ${XMLDATEIEN}
ls -lha ${NEUERNAME}.csv
echo "
libreoffice --calc ${NEUERNAME}.csv"

#------------------------------------------------------------------------------#

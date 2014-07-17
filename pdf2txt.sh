#!/usr/bin/env bash

#
# dieses Skript wandelt die Dateien aus dem PDF-Format
# erst in das PS-Format, dann in das Text-Format
#

if [ -z "${1}" ] ; then
        echo "${0} Datei1.pdf Datei2.pdf Datei3.pdf"
        exit 1
fi

if [ -z "$(which pdf2ps)" ] ; then
        echo "pdf2ps (Ghostscript) ist nicht installiert"
        exit 1
fi

if [ -z "$(which ps2ascii)" ] ; then
        echo "ps2ascii (Ghostscript) ist nicht installiert"
        exit 1
fi

for _datei in ${@}
do
        DATEINAME="$(echo "$(basename ${_datei})" | rev | sed 's/.*[.]//' | rev)"

        pdf2ps ${_datei} ${DATEINAME}.ps
        ps2ascii ${DATEINAME}.ps > ${DATEINAME}.txt && rm -f ${DATEINAME}.ps
done

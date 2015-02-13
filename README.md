Postbank_PDF2CSV
================

Leider kann man im Onlineportal der Postbank (und auch per EBICS) seine Umsätze nur für die letzten 100 Tage als CSV runter runterladen.  Braucht man mehr in einem elektronisch verarbeitbaren Format, dann muss man auf die Kontoauszüge zurückgreifen, die aber leider nur im nicht bearbeitbaren PDF-Format vorliegen.  Um diese ins Text-Format und dann ins CSV-Format umzuwandeln, damit man sie in einer Tabellenkalkulation aufarbeiten kann, habe ich die folgenden beiden Skripte geschrieben, die beide zusammen hierfür benötigt werden.

Beide Dateien müssen im selben Verzeichnis liegen (z.B.: ~/bin/)!

In den Dateinamen der PDF-Dateien dürfen keine Leezeichen, Umlaute, Sonderzeichen, Klammern o.ä. sein!

--------------------------------------------------------------------------------

Um die neuen Skripte für die Kontoauszüge, ab Februar 2014, übersetzten zu können, reicht es nicht das Paket "ghostscript" zu installieren, hierfür müssen auch die Pakete "pstotext" und "poppler-utils" noch installiert werden!

--------------------------------------------------------------------------------
Vorbereitungen/Installationen mit Ubuntu 14.04 bzw. Mint 17
-----------------------------------------------------------

Es wird das Kommando "bash" benötigt, das ist in der Basisinstallation der meisten Linux-Distributionen bereits vorhanden.

Es werden auch die Kommandos "pdf2ps" und "ps2ascii" benötigt, um sie zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    aptitude update ; aptitude -y install ghostscript

Es werden auch die Kommandos "pdftohtml" und "pdftops" benötigt, um sie zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    aptitude update ; aptitude -y install poppler-utils

Es wird das Kommando "pstotext" benötigt, um es zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    aptitude update ; aptitude -y install pstotext

--------------------------------------------------------------------------------
Vorbereitungen/Installationen mit FreeBSD 10
--------------------------------------------

Es wird das Kommando "bash" benötigt, um es zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    pkg install shells/bash
    ln -s /usr/local/bin/bash /bin/bash

Es werden auch die Kommandos "pdf2ps" und "ps2ascii" benötigt, um sie zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    pkg install print/ghostscript9-nox11

Es werden auch die Kommandos "pdftohtml" und "pdftops" benötigt, um sie zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    pkg install graphics/poppler-utils

Es wird das Kommando "pstotext" benötigt, um es zu installieren, muss das folgende Installationskommando ausgeführt werden:
    
    pkg install print/pstotext

--------------------------------------------------------------------------------
Ab Juli 2014:

beispielsweise könnte man das so machen,
als erstes die neueste Version saugen:
    
    wget https://github.com/FlatheadV8/Postbank_PDF2CSV/archive/1.2.0.tar.gz

dann entpacken:
    
    tar xzvf 1.2.0.tar.gz

den Kontoauszug aus dem PDF-Format ins CSV-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_pdf2csv.sh PB_KAZ_KtoNr_0903464503_11-11-2014_0437.pdf
    
    das kann jetzt ein paar Minuten dauern ...
    
    -rw-r--r-- 1 ich ich 2,2K Dez 16 03:33 PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv
    
    libreoffice --calc PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv

evtl. die CSV-Datei ins QIF-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_csv2qif.sh PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv 
    -rw-r--r-- 1 ich ich 2,2K Dez 16 03:33 PB_KAZ_KtoNr_0903464503_11-11-2014_0437.qif

--------------------------------------------------------------------------------
Bis Juni 2014:

den Kontoauszug aus dem PDF-Format ins CSV-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_pdf2csv_bis_2013.sh Postbank/Kontoauszug_2014-01-10.pdf 
    -rw-r--r-- 1 ich ich 2,7K Dez 16 13:55 Postbank/Kontoauszug_2014-01-10.csv

evtl. die CSV-Datei ins QIF-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_csv2qif_bis_2013.sh Postbank/Kontoauszug_2014-01-10.csv 
    -rw-r--r-- 1 ich ich 2,8K Dez 16 13:57 Postbank/Kontoauszug_2014-01-10.qif

--------------------------------------------------------------------------------

Die Dateinamen dürfen keine Leerzeichen und keine Sonderzeichen (zum Beispiel Klammern) enthalten.

Achtung, durch die vielen ineinander geschachtelten Schleifen, verursacht das Skript wärend seiner Laufzeit eine erhöhte Last und läuft relativ langsam.

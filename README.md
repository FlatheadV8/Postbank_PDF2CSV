Postbank_PDF2CSV
================

Leider kann man im Onlineportal der Postbank (und auch per EBICS) seine Umsätze nur für die letzten 100 Tage als CSV runter runterladen.  Braucht man mehr in einem elektronisch verarbeitbaren Format, dann muss man auf die Kontoauszüge zurückgreifen, die aber leider nur im nicht bearbeitbaren PDF-Format vorliegen.  Um diese ins Text-Format und dann ins CSV-Format umzuwandeln, damit man sie in einer Tabellenkalkulation aufarbeiten kann, habe ich die folgenden beiden Skripte geschrieben, die beide zusammen hierfür benötigt werden.

Beide Dateien müssen im selben Verzeichnis liegen (z.B.: ~/bin/)!

In den Dateinamen der PDF-Dateien dürfen keine Leezeichen, Umlaute, Sonderzeichen, Klammern o.ä. sein!

--------------------------------------------------------------------------------

beispielsweise könnte man das so machen:

    # mkdir test
    # cd test
    
    # ~/bin/postbank_pdf2txt.sh ~/postbank/kontoauszuege/PB_KAZ_KtoNr_0908765403_10-09-2011_0219.pdf
    
    # ls -lh
    -rw-r--r-- 1 fritz fritz 3,4K 2012-04-01 02:05 PB_KAZ_KtoNr_0908765403_10-09-2011_0219.txt
    -rw-r--r-- 1 fritz fritz  278 2012-04-01 02:12 postbank.csv
    
    # libreoffice postbank.csv

oder aber auch gleich alle Kontoauszüge vom ganzen Jahr:

    # mkdir 2011
    # cd 2011
    # ~/bin/postbank_pdf2txt.sh ~/postbank/kontoauszuege/2011/*.pdf
    # libreoffice postbank.csv

Achtung, durch die vielen ineinander geschachtelten Schleifen, verursacht das Skript wärend seiner Laufzeit eine erhöhte Last und läuft relativ langsam.

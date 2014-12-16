Postbank_PDF2CSV
================

Leider kann man im Onlineportal der Postbank (und auch per EBICS) seine Umsätze nur für die letzten 100 Tage als CSV runter runterladen.  Braucht man mehr in einem elektronisch verarbeitbaren Format, dann muss man auf die Kontoauszüge zurückgreifen, die aber leider nur im nicht bearbeitbaren PDF-Format vorliegen.  Um diese ins Text-Format und dann ins CSV-Format umzuwandeln, damit man sie in einer Tabellenkalkulation aufarbeiten kann, habe ich die folgenden beiden Skripte geschrieben, die beide zusammen hierfür benötigt werden.

Beide Dateien müssen im selben Verzeichnis liegen (z.B.: ~/bin/)!

In den Dateinamen der PDF-Dateien dürfen keine Leezeichen, Umlaute, Sonderzeichen, Klammern o.ä. sein!

--------------------------------------------------------------------------------

beispielsweise könnte man das so machen,
als erstes die neueste Version saugen:
    
    wget https://github.com/FlatheadV8/Postbank_PDF2CSV/archive/1.2.0.tar.gz

dann entpacken:
    
    tar xzvf 1.2.0.tar.gz

den Kontoauszug aus dem PDF-Format ins CSV-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_pdf2csv.sh PB_KAZ_KtoNr_0903464503_11-11-2014_0437.pdf
    
    das kann jetzt ein paar Minuten dauern ...
    
    -rw-r--r-- 1 manfred manfred 2,2K Dez 16 03:33 PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv
    
    libreoffice --calc PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv

evtl. die CSV-Datei ins QIF-Format umwandeln:
    
    Postbank_PDF2CSV-1.2.0/postbank_csv2qif.sh PB_KAZ_KtoNr_0903464503_11-11-2014_0437.csv 
    -rw-r--r-- 1 manfred manfred 2,2K Dez 16 03:33 PB_KAZ_KtoNr_0903464503_11-11-2014_0437.qif

Die Dateinamen dürfen keine Leerzeichen und keine Sonderzeichen (zum Beispiel Klammern) enthalten.

Achtung, durch die vielen ineinander geschachtelten Schleifen, verursacht das Skript wärend seiner Laufzeit eine erhöhte Last und läuft relativ langsam.

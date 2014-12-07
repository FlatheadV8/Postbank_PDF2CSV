#
# Quelle (2014-12-07):
# http://wiki.gnucash.org/wiki/FAQ#Q:_How_do_I_convert_from_CSV.2C_TSV.2C_XLS_.28Excel.29.2C_or_SXC_.28OpenOffice.org_Calc.29_to_a_QIF.3F
# Anwendung:
# awk -f postbanken.awk kontoutskrift.csv > import.qif
#
# awk convert fra Postbankens CSV til QIF(Gnucash, quicken, osv)
# CSV fra Postbanken er ikke en kommaseparert fil, men en tekstfil med feltene på fast plass.
# Bruker derfor fieldwidths i awk. Det går også ant å bruke substr().
# Kilder:
# http://wiki.gnucash.org/wiki/FAQ
# http://www.ibm.com/developerworks/library/l-awk1.html
# http://www.ibm.com/developerworks/library/l-awk2.html
# http://www.grymoire.com/Unix/Awk.html#uh-67
# Samt manualen til awk og egrep.
#
# Bruk filen slik:
# $ awk -f postbanken.awk kontoutskrift.csv > import.qif
#
#
# Arve Seljebu - juni 2010


# Del opp filen i felter og skriv "!Type:Bank" bare en gang i toppen av filen
BEGIN {FIELDWIDTHS="8 5 17 35 31 11 1 11"; print "!Type:Bank";}
# Bare bruk linjen hvis den inneholder dato
{ if ($0 ~ /[0-9][0-9].[0-9][0-9].[0-9][0-9]/) {
# Dato
  print "D" $1;
# Avkommenter neste linje for å bruke BETALING, BETALING UTLAND osv som konto/kategori
# print "L" $3;
# Beskrivelse/memo
  print "M" $4;
# Debit eller kredit
  if ($6 == 0) { print "T-" $8; }
  else { print "T" $6; }
  print "^";
  }
}

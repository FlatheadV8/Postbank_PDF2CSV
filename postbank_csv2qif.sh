#!/usr/bin/env bash

#
# CSV -> QIF (Quicken Interchange Format)
#
#
# dieses Skript wandelt die mit "postbank_pdf2csv.sh" generieren CSV-Datei in eine QIF-Datei
# für GnuCache um
#
# Quelle (2014-12-07):
# http://wiki.gnucash.org/wiki/FAQ#Q:_How_do_I_convert_from_CSV.2C_TSV.2C_XLS_.28Excel.29.2C_or_SXC_.28OpenOffice.org_Calc.29_to_a_QIF.3F
#

if [ -z "${1}" ] ; then
        echo "${0} Datei1.csv"
        exit 1
fi

#------------------------------------------------------------------------------#

(echo '!Type:Bank'
	###
	### ACHTUNG!!!
	### Diese Konvertierung funktioniert nur mit der
	### "1822-Reihenfolge"-Einstellung (Standardeinstellung)
	### in der Datei "postbank_pdf2csv.sh",
	### weil der Verwendungszweck (Buchungsinformationen) eine undefinierte
	### Anzahl an Trennzeichen (Semikolon) enthält.
	### Um diese trotzdem sinnvoll verarbeiten zu können, müssen diese
	### Informationen am Ende stehen.
	###
	### echo -n "${BUCHUNGSDATUM};${WERTSTELLUNGSDATUM};${PM2}${BETRAG2};${PNN};${BUCHUNGSINFORMATION0} ${BUCHUNGSINFORMATION2}"
	cat "${1}" | grep -Ev '^Buchungstag' | while read ZEILE
	do
		BUCHUNGSDATUM="$(echo "${ZEILE}" | awk -F';' '{ print $1 }')"
		WERTSTELLUNGSDATUM="$(echo "${ZEILE}" | awk -F';' '{ print $2 }')"
		BETRAG="$(echo "${ZEILE}" | awk -F';' '{ print $3}')"
		PNN="$(echo "${ZEILE}" | awk -F';' '{ print $4 }')"
		VERWENDUNGSZWECK="$(echo "${ZEILE}" | tr -s ';' '\n' | tail -n+5 | sed 's/.*/&,/' | tr -s '\n' ',')"
		echo -e "D${BUCHUNGSDATUM}\nN${PNN}\nM${WERTSTELLUNGSDATUM} ${VERWENDUNGSZWECK}\nT${BETRAG}\n^"
	done
) > postbank.qif

ls -lh postbank.qif

#==============================================================================#
exit
#------------------------------------------------------------------------------#
D 	Date. Leading zeroes on month and day can be skipped. Year can be either 4 digits or 2 digits or '6 (=2006). 	All 	D25 December 2006
T 	Amount of the item. For payments, a leading minus sign is required. For deposits, either no sign or a leading plus sign is accepted. Do not include currency symbols ($, £, ¥, etc.). Comma separators between thousands are allowed. 	All 	T-1,234.50
M 	Memo—any text you want to record about the item. 	All 	Mgasoline for my car
C 	Cleared status. Values are blank (not cleared), "*" or "c" (cleared) and "X" or "R" (reconciled). 	All 	CR
N 	Number of the check. Can also be "Deposit", "Transfer", "Print", "ATM", "EFT". 	Banking, Splits 	N1001
P 	Payee. Or a description for deposits, transfers, etc. 	Banking, Investment 	PStandard Oil, Inc.
A 	Address of Payee. Up to 5 address lines are allowed. A 6th address line is a message that prints on the check. 1st line is normally the same as the Payee line—the name of the Payee. 	Banking, Splits 	A101 Main St.
L 	Category or Transfer and (optionally) Class. The literal values are those defined in the Quicken Category list. SubCategories can be indicated by a colon (":") followed by the subcategory literal. If the Quicken file uses Classes, this can be indicated by a slash ("/") followed by the class literal. For Investments, MiscIncX or MiscExpX actions, Category/class or transfer/class. 	Banking, Splits 	LFuel:car
F 	Flag this transaction as a reimbursable business expense. 	Banking 	F???
S 	Split category. Same format as L (Categorization) field. 	Splits 	Sgas from Esso
E 	Split memo—any text to go with this split item. 	Splits 	Ework trips
$ 	Amount for this split of the item. Same format as T field. 	Splits 	$1,000.50
% 	Percent. Optional—used if splits are done by percentage. 	Splits 	%50
N 	Investment Action (Buy, Sell, etc.). 	Investment 	NBuy
Y 	Security name. 	Investment 	YIDS Federal Income
I 	Price. 	Investment 	I5.125
Q 	Quantity of shares (or split ratio, if Action is StkSplit). 	Investment 	Q4,896.201
O 	Commission cost (generally found in stock trades) 	Investment 	O14.95
$ 	Amount transferred, if cash is moved between accounts 	Investment 	$25,000.00
X 	Extended data for Quicken Business. Followed by a second character subcode (see below) followed by content data. 	Invoices 	XI3
XA 	Ship-to address 	Invoices 	XAATTN: Receiving
XI 	Invoice transaction type: 1 for invoice, 3 for payment 	Invoices 	XI1
XE 	Invoice due date 	Invoices 	XE6/17' 2
XC 	Tax account 	Invoices 	XC[*Sales Tax*]
XR 	Tax rate
XT 	Tax amount 	Invoices 	XT15.40
XS 	Line item description 	Invoices 	XSRed shoes
XN 	Line item category name 	Invoices 	XNSHOES
X# 	Line item quantity 	Invoices 	X#1
X$ 	Line item price per unit (multiply by X# for line item amount) 	Invoices 	X$150.00
XF 	Line item taxable flag 	Invoices 	XFT

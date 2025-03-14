#!/usr/bin/env bash

echo "Extract reservation"

for o in 3753 3827 3829 3830 4132 4233 4466; do
	echo "------- $o"
	curl -s 'https://reservations.epfl.ch/cgi-bin/res/extract' \
		-X POST \
		-H 'User-Agent: ReservationExtractor999' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
	       	-H 'Accept-Language: en-US,en;q=0.5' \
		-H 'Referer: https://reservations.epfl.ch/cgi-bin/res/extract' \
		-H 'Content-Type: application/x-www-form-urlencoded' \
		-H 'Origin: https://reservations.epfl.ch' \
		-H 'Cookie: csrftoken=1234[...]; Tequila_res=1234[...]' \
	       	-H 'Upgrade-Insecure-Requests: 1' \
		-H 'Sec-Fetch-Dest: document' \
		-H 'Sec-Fetch-Mode: navigate' \
		-H 'Sec-Fetch-Site: same-origin' \
		-H 'Sec-Fetch-User: ?1' \
		-H 'Priority: u=0, i' \
		-H 'Pragma: no-cache' \
		-H 'Cache-Control: no-cache' \
		--data-raw "csv=1&objID=$o&date1=01%2F01%2F2025&date2=31%2F03%2F2040&go=extraire" \
		-O -J
	ls reservations*.csv
	mv reservations20250101.20400331.csv "reservations-$o-20250101.20400331.csv"
done

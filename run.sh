#!/bin/bash

working_path="/to/my/path"
origin_file="credit_card_202212.pdf"
destination_file="credit_card_202212.csv"

rm -f ${working_path}/tmp
rm -f ${working_path}/tmp1
rm -f ${working_path}/tmp2
rm -f ${working_path}/${destination_file}

echo "Date;Description;Amount" >> ${working_path}/${destination_file}

# send the pdf content to a file
pdftotext -raw ${working_path}/${origin_file} ${working_path}/tmp

# filter transaction lines (ie having a month in column 2)
backwards=($(seq 0 11))
for backward in ${backwards[@]};
do
    pattern=$(date -d "$backward months ago" +%b)
    awk -v m=$pattern '$2 == m' ${working_path}/tmp.txt >> ${working_path}/tmp1
done

# a little bit of clean-up (to be changed for your needs)
sed -i "s/MAILGUN TECHNOLOGIES, SAN ANTONIO TX/MAILGUN TECHNOLOGIES/g" ${working_path}/tmp1
sed -i "s/cr//g" ${working_path}/tmp1

# get the actual values
awk 'BEGIN {OFS=";";} {print $1, $2, $0, $NF}' ${working_path}/tmp1 >> ${working_path}/tmp2

# work on the dates:
for backward in ${backwards[@]};
do
    pattern=$(date -d "$backward months ago" +%b)
    replace=$(date -d "$backward months ago" +"%Y-%m")
    sed -i "s/$pattern/$replace/g" ${working_path}/tmp2
done

while IFS= read -r line
do
    # echo $line
    day="$(cut -d';' -f1 <<< "$line")"
    month="$(cut -d';' -f2 <<< "$line")"
    description="$(cut -d';' -f3 <<< "$line")"
    amount="$(cut -d';' -f4 <<< "$line")"

    full_date="${month}-$(printf %02d $day)"

    description=${description/$day /}
    description=${description/$month /}
    description=${description/$amount/}

    chain="${full_date};${description};${amount}"
    echo $chain >> ${working_path}/${destination_file}
    
done < "${working_path}/tmp2"

rm ${working_path}/tmp
rm ${working_path}/tmp1
rm ${working_path}/tmp2

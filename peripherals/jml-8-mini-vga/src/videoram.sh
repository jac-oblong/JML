# simple script for generating the binary videoram.txt file

rm videoram.txt
for i in {1..480}
do
    for j in {1..640}
    do
        echo -n "0 " >> videoram.txt
    done
    echo "" >> videoram.txt
done

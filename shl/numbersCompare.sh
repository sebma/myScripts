#!/usr/bin/env bash
echo "enter two numbers"

read a b

echo "a=$a"
echo "b=$b"

#if [ $a \> $b ]
if (( $a > $b ))
then 
    echo "$a is greater than $b"
else
	echo "$b is greater than $a"
fi

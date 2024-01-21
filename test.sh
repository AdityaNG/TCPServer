#!/bin/bash

# Check if ENABLE_LOGGING is set
if [ -z "$ENABLE_LOGGING" ]
then
    ENABLE_LOGGING=0
fi

# Check if port is set
if [ -z "$PORT" ]
then
    PORT=8080
fi

# Check if PARALLEL is set
if [ -z "$PARALLEL" ]
then
    PARALLEL=0
fi

# Check if NUM_CLIENTS is set
if [ -z "$NUM_CLIENTS" ]
then
    NUM_CLIENTS=5
fi

START=$(($(date +%s%N)/1000000))

rm tests/inputs_generated/*.txt
rm tests/outputs/*.txt

mkdir -p tests/inputs_generated
mkdir -p tests/outputs

# Use tests/inputs/ALL_SUB.txt as a template
# Substitute all instances of "key" with $i
# Generate 100 input files at tests/inputs_generated/$i.txt
for ((i=1;i<=NUM_CLIENTS;i++))
do
    sed "s/key/$i/g" tests/inputs/ALL_SUB.txt > tests/inputs_generated/$i.txt
done

# Run 100 clients
# Each client sends tests/inputs_generated/$i.txt to localhost:$PORT
# Each client writes the response to tests/outputs/$i.txt
# Each client runs in the background if PARALLEL
for ((i=1;i<=NUM_CLIENTS;i++))
do
    if [ $PARALLEL -eq 0 ]
    then
        ncat localhost $PORT < tests/inputs_generated/$i.txt &> tests/outputs/$i.txt
    fi
    if [ $PARALLEL -eq 1 ]
    then
        ncat localhost $PORT < tests/inputs_generated/$i.txt &> tests/outputs/$i.txt &
    fi
done


# Wait for all clients to finish
NUMFILES=$(ls -l tests/outputs/*.txt | wc -l)
OPENED=$(lsof -t tests/outputs/*.txt | wc -l)

while [ $OPENED -ne 0 ]
do
    NUMFILES=$(ls -l tests/outputs/*.txt | wc -l)
    OPENED=$(lsof -t tests/outputs/*.txt | wc -l)
    #sleep 0.010
done 

declare -i ERR_COUNT=0

for ((i=1;i<=NUM_CLIENTS;i++))
do
    DIFF=$(cmp tests/expected_outputs/ALL_SUB.txt tests/outputs/$i.txt | wc -l)
    if [ $DIFF -ne 0 ]
    then
        echo "Error: " $i".txt"
        if [ $ENABLE_LOGGING -eq 1 ]
        then
            echo "Got: "
            cat tests/outputs/$i.txt
            echo "Expected: "
            cat tests/expected_outputs/ALL_SUB.txt
        fi
        ERR_COUNT=$ERR_COUNT+1
    fi
done


END=$(($(date +%s%N)/1000000))
DIFF=$(( $END - $START ))
echo "Time: $DIFF ms"
echo "Err Rate: $ERR_COUNT / $NUM_CLIENTS"

# Exit with error code if there are errors
if [ $ERR_COUNT -ne 0 ]
then
    exit 1
fi

exit 0

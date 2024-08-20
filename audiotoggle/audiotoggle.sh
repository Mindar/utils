#!/bin/bash


# This script was translated from natural language
# to bash on ChatGPT.com with GPT-4o and proofread
# by a human.
# The prompts used are documented in prompts.md


# User-configurable list of sources
SOURCES=($(pactl list sinks short | awk '{print $2}'))


# Step 1: Get the current default sink
CURRENT_SINK=$(pactl get-default-sink)

# Step 2: Find the index of the current sink in the SOURCES array
CURRENT_INDEX=-1
for i in "${!SOURCES[@]}"; do
    if [ "${SOURCES[$i]}" == "$CURRENT_SINK" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

# Step 3: Calculate the index of the next sink in the list
if [ $CURRENT_INDEX -ge 0 ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#SOURCES[@]} ))
else
    NEXT_INDEX=0
fi

# Step 4: Set the default sink to the next one in the list
NEXT_SINK=${SOURCES[$NEXT_INDEX]}
pactl set-default-sink "$NEXT_SINK"

#echo "Default sink switched to $NEXT_SINK"
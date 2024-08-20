# Info
This file documents the prompts used to translate the natural-language instructions to bash syntax.

One notable thing that surprised me was that ChatGPT was able to automatically deduce that it needs to parse the tab-separated output of `pactl list sinks short` and that this output contains the relevant data in the second field. It then used `awk` to get that field. My expectation was that ChatGPT would hallucinate some kind kind of fantasy format for that output, but not be able to deduce how the output is structured.

Another thing that surprised me, but probably wouldn't surprise anyone who regularly uses it, was GPTs usage of `awk`. I expected it to write custom parsing logic, though `awk` is obviously a much more robust and better choice here.


# Prompts
What follows are the prompts used and responses given when developing the script. I intentionally went with a more step-by-step approach to not overwhelm it with writing a huge script at once.
My intent was to use ChatGPT for translation to bash-syntax, not for development, since I already knew exactly what I wanted, just couldn't be bothered to look up relevant bash syntax.

---
*Human:*


write a bash script that does the following:

1. it calls pactl get-default-sink and stores the value in a variable
2. it checks if the variable is equal to either "sourceA" or "sourceB"
3. if it is equal to "sourceA", call pactl set-default-sink sourceB
   if it isn't equal to "sourceA", then set it to "sourceA".

Please note that that "sourceA" and "sourceB" can be changed by a user by editing two variables.

---
*GPT-4o:*


Here's a bash script that accomplishes the task:

```bash
#!/bin/bash

# User-configurable variables
SOURCE_A="sourceA"
SOURCE_B="sourceB"

# Step 1: Get the current default sink
CURRENT_SINK=$(pactl get-default-sink)

# Step 2: Check if the current sink is equal to either SOURCE_A or SOURCE_B
if [ "$CURRENT_SINK" == "$SOURCE_A" ]; then
    # Step 3: If it is equal to SOURCE_A, switch to SOURCE_B
    pactl set-default-sink "$SOURCE_B"
    echo "Default sink switched to $SOURCE_B"
else
    # Otherwise, switch to SOURCE_A
    pactl set-default-sink "$SOURCE_A"
    echo "Default sink switched to $SOURCE_A"
fi
```

### Explanation:
1. **User-configurable variables**: 
   - `SOURCE_A` and `SOURCE_B` are defined at the top of the script. Users can change these values to whatever they want.
   
2. **Get the current default sink**: 
   - The `pactl get-default-sink` command is used to retrieve the current default audio sink and store it in the `CURRENT_SINK` variable.

3. **Check and switch**: 
   - If the `CURRENT_SINK` is equal to `SOURCE_A`, the script switches to `SOURCE_B`.
   - If it's not `SOURCE_A`, the script switches to `SOURCE_A`. 

### Usage:
- Save this script to a file, for example, `switch_sink.sh`.
- Make it executable with `chmod +x switch_sink.sh`.
- Run it using `./switch_sink.sh`.

This script allows for easy toggling between two default sinks.

---
*Human:*

actually, can you change the script so sourceA and sourceB are in some sort of a editable list. The script should now simply cycle through the list entries instead 

---

Certainly! Here's a modified version of the script that cycles through a list of sources:

```bash
#!/bin/bash

# User-configurable list of sources
SOURCES=("sourceA" "sourceB" "sourceC")  # Add as many sources as needed

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
echo "Default sink switched to $NEXT_SINK"
```

### Explanation:
1. **User-configurable list**: 
   - `SOURCES` is an array where you can list as many sources as needed (e.g., `sourceA`, `sourceB`, `sourceC`, etc.).

2. **Get the current default sink**:
   - The script retrieves the current default sink and stores it in the `CURRENT_SINK` variable.

3. **Find the index of the current sink**:
   - The script iterates through the `SOURCES` array to find the index of the current sink. If it finds a match, it stores the index in `CURRENT_INDEX`.

4. **Calculate the index of the next sink**:
   - If the current sink is found in the list, it calculates the index of the next sink. If not, it defaults to the first source in the list.

5. **Set the next sink**:
   - The script then sets the default sink to the next one in the list and prints a message indicating the change.

### Usage:
- Save this script to a file, e.g., `cycle_sinks.sh`.
- Make it executable with `chmod +x cycle_sinks.sh`.
- Run it using `./cycle_sinks.sh`.

This script allows you to easily cycle through a list of sources, making it more flexible if you have more than two audio sinks to manage.

---
*Human:*

ok, now instead of having a hardcoded list SOURCES=(...) please call the command "pactl list sinks short". The output of that command should be parsed and the sink name should be extracted and put into the list. I.e. the list should be automatically generated

---
*GPT-4o:*

Certainly! Here's a modified version of the script that dynamically generates the list of available sinks using the `pactl list sinks short` command:

```bash
#!/bin/bash

# Step 1: Generate the list of available sinks
SOURCES=($(pactl list sinks short | awk '{print $2}'))

# Step 2: Get the current default sink
CURRENT_SINK=$(pactl get-default-sink)

# Step 3: Find the index of the current sink in the SOURCES array
CURRENT_INDEX=-1
for i in "${!SOURCES[@]}"; do
    if [ "${SOURCES[$i]}" == "$CURRENT_SINK" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

# Step 4: Calculate the index of the next sink in the list
if [ $CURRENT_INDEX -ge 0 ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#SOURCES[@]} ))
else
    NEXT_INDEX=0
fi

# Step 5: Set the default sink to the next one in the list
NEXT_SINK=${SOURCES[$NEXT_INDEX]}
pactl set-default-sink "$NEXT_SINK"
echo "Default sink switched to $NEXT_SINK"
```

### Explanation:
1. **Generate the list of available sinks**:
   - The `pactl list sinks short` command lists all available sinks in a short format.
   - The `awk '{print $2}'` command extracts the second field from each line, which corresponds to the sink names.
   - The list of sink names is stored in the `SOURCES` array.

2. **Get the current default sink**:
   - The script retrieves the current default sink and stores it in the `CURRENT_SINK` variable.

3. **Find the index of the current sink**:
   - The script searches for the current sink's index in the dynamically generated `SOURCES` array.

4. **Calculate the index of the next sink**:
   - The next index is calculated based on the position of the current sink in the list.

5. **Set the next sink**:
   - The script sets the default sink to the next one in the list and prints a message indicating the change.

### Usage:
- Save this script to a file, e.g., `cycle_sinks_dynamic.sh`.
- Make it executable with `chmod +x cycle_sinks_dynamic.sh`.
- Run it using `./cycle_sinks_dynamic.sh`.

This script now dynamically generates the list of available sinks each time it runs, making it more adaptable to different environments where the available sinks may change.
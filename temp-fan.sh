#!/bin/bash

ontemp=48
buffer_time=600  # 10 minutes buffer time in seconds
fan_state_file="/tmp/fan_state.txt"
gpio_pin=14

gpio -g mode $gpio_pin out

# Function to check if the fan has been on for at least the buffer time
in_grace_time() {
    if [ ! -f "$fan_state_file" ]; then
        echo "Fan state file does not exist"
        return 1
    fi
    last_on_time=$(cat "$fan_state_file")
    current_time=$(date +%s)
    time_diff=$((current_time - last_on_time))
    echo "Last on time: $last_on_time"
    echo "Current time: $current_time"
    echo "Buffer: $buffer_time"
    echo "Time difference: $time_diff"
    if [ $time_diff -ge $buffer_time ]; then
        echo "Not in grace time, returning false"
        return 1
    else
        echo "In grace time, returning true"
        return 0
    fi
}


# Function to update the fan state file
update_fan_state() {
    echo $(date +%s) > "$fan_state_file"
}

temp=$(vcgencmd measure_temp | grep -E -o '[0-9]*\.[0-9]*')
temp0=${temp%.*}

echo $temp
echo $temp0

if [ $temp0 -gt $ontemp ]; then
    echo "Greater than $ontemp, fan on"
    gpio -g write $gpio_pin 1
    update_fan_state
elif in_grace_time; then
    echo "Fan is staying on due to ${buffer_time} second buffer time"
    gpio -g write $gpio_pin 1
else
    echo "Less than or equal to $ontemp, fan off"
    gpio -g write $gpio_pin 0
    if [ -f "$fan_state_file" ]; then
        rm "$fan_state_file"
    fi
fi
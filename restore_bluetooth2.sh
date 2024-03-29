#!/bin/bash

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=60

while true;
do
    if cat /home/tj2022/map/core_restart.txt | grep -q 1 ; then 
        if hciconfig -a | grep -iq $bluetooth_controller;then
            if bluetoothctl devices | grep -iq $charger_bluetooth_name;then
                str_output=$(date)" === normal"
                echo ${str_output} | tee -a $log_file_name
            else
                str_output=$(date)" === restart core for reason: cann't find ${charger_bluetooth_name} bluetooth"
                echo ${str_output} | tee -a $log_file_name
                docker compose -f /home/tj2022/docker-compose.yml restart core
            fi
        else
            str_output=$(date)" === restart core for reason: donn't have ${bluetooth_controller} controller"
            echo ${str_output} | tee -a $log_file_name
            docker compose -f /home/tj2022/docker-compose.yml restart core
        fi
    else
        echo $(date)" --- not in monitoring state." | tee -a $log_file_name
    fi

    sleep $time_interval
done



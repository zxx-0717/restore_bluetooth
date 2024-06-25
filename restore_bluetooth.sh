#!/bin/bash

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=60
pwd="tj2022"

while true;
do
    if cat /home/tj2022/map/core_restart.txt | grep -q 1 ; then 
        if hciconfig -a | grep -iq $bluetooth_controller;then
            if bluetoothctl devices | grep -iq $charger_bluetooth_name;then
                str_output=$(date)" === normal"
                echo ${str_output} | tee -a $log_file_name
            else
                str_output=$(date)" === restore bluetooth for reason: cann't find ${charger_bluetooth_name} bluetooth"
                echo ${str_output} | tee -a $log_file_name
                echo $pwd | sudo -S systemctl restart bluetooth
                echo $pwd | sudo -S hciconfig hci0 down
                echo $pwd | sudo -S hciconfig hci0 up
                echo $pwd | sudo -S rfkill unblock all
                echo $pwd | sudo -S rmmod btusb
                echo $pwd | sudo -S rmmod btintel
                echo $pwd | sudo -S modprobe btintel
                echo $pwd | sudo -S modprobe btusb
                docker compose -f /home/tj2022/docker-compose.yml restart core
            fi
        else
            str_output=$(date)" === restore bluetooth for reason: donn't have ${bluetooth_controller} controller"
            echo ${str_output} | tee -a $log_file_name
            echo $pwd | sudo -S systemctl restart bluetooth
            echo $pwd | sudo -S hciconfig hci0 down
            echo $pwd | sudo -S hciconfig hci0 up
            echo $pwd | sudo -S rfkill unblock all
            echo $pwd | sudo -S rmmod btusb
            echo $pwd | sudo -S rmmod btintel
            echo $pwd | sudo -S modprobe btintel
            echo $pwd | sudo -S modprobe btusb
            docker compose -f /home/tj2022/docker-compose.yml restart core
        fi
    else
        echo $(date)" --- not in monitoring state." | tee -a $log_file_name
    fi

    sleep $time_interval
done



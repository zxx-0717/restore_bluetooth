#!/bin/bash

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=10
pwd="tj2022"

str_output=$(date)" === sleep 20s for waiting device/service to be ready"
echo ${str_output} | tee -a $log_file_name
sleep 20

while true;
do
    if cat /home/tj2022/map/core_restart.txt | grep -q 1 ; then 
        if cat /home/tj2022/map/bluetooth_restore.txt | grep -q 1 ;then

            str_output=$(date)" === restoring bluetooth ...... "
            echo ${str_output} | tee -a $log_file_name

            str_output=$(date)" === exec systemctl restart bluetooth"
            echo ${str_output} | tee -a $log_file_name
            timeout 10 echo $pwd | sudo -S systemctl restart bluetooth

            str_output=$(date)" === exec hciconfig hci0 down"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S hciconfig hci0 down

            str_output=$(date)" === exec hciconfig hci0 up"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S hciconfig hci0 up

            str_output=$(date)" === exec rfkill unblock all"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S rfkill unblock all

            str_output=$(date)" === exec rmmod btusb"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S rmmod btusb

            str_output=$(date)" === exec rmmod btintel"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S rmmod btintel

            str_output=$(date)" === exec modprobe btintel"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S modprobe btintel

            str_output=$(date)" === exec modprobe btusb"
            echo ${str_output} | tee -a $log_file_name
            timeout 5 echo $pwd | sudo -S modprobe btusb

            # str_output=$(date)" === exec docker compose -f /home/tj2022/docker-compose.yml restart core"
            # echo ${str_output} | tee -a $log_file_name
            # timeout 15 docker compose -f /home/tj2022/docker-compose.yml restart core

            str_output=$(date)" === sleep 5s for waiting device/service/module to be ready"
            echo ${str_output} | tee -a $log_file_name
            sleep 5
            
            str_output=$(date)" === exec echo 0 to /home/tj2022/map/bluetooth_restore.txt"
            echo ${str_output} | tee -a $log_file_name
            timeout 3 echo 0 > /home/tj2022/map/bluetooth_restore.txt
        else
            str_output=$(date)" === normal"
            echo ${str_output} | tee -a $log_file_name
        fi
    else
        echo $(date)" --- not in monitoring state." | tee -a $log_file_name
    fi

    sleep $time_interval
done



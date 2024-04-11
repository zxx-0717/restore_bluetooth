#!/bin/bash

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker2"
time_interval=5

restart_core_num_max=2
restart_core_num=0
reboot_robot_num_max=2
reboot_robot_num=$(cat /opt/systemd-sh/reboot_robot_num.txt)

while true;
do
    if cat /home/tj2022/map/core_restart.txt | grep -q 1 ; then 
        if hciconfig -a | grep -iq $bluetooth_controller;then
            if bluetoothctl devices | grep -iq $charger_bluetooth_name;then
                str_output=$(date)" === normal"
                echo ${str_output} | tee -a $log_file_name
                restart_core_num=0
                reboot_robot_num=0
            else
                str_output=$(date)" === Bluetooth malfunction detected: : cann't find ${charger_bluetooth_name} bluetooth"
                echo ${str_output} | tee -a $log_file_name
                restart_core_num=$((restart_core_num + 1))
            fi
        else
            str_output=$(date)" === Bluetooth malfunction detected: : donn't have ${bluetooth_controller} controller"
            echo ${str_output} | tee -a $log_file_name
            restart_core_num=$((restart_core_num + 1))
        fi
    else
        echo $(date)" --- not in monitoring state." | tee -a $log_file_name
        restart_core_num=0
        reboot_robot_num=0
    fi

    if [ $restart_core_num -gt 0 ]; then
        if [ $restart_core_num -le $restart_core_num_max ]; then
            # docker compose -f /home/tj2022/docker-compose.yml restart core
            str_output=$(date)" === fake restart core "
            echo ${str_output} | tee -a $log_file_name
        else
            reboot_robot_num=$(($reboot_robot_num + 1))
        fi
    fi

    if [[ $reboot_robot_num -gt 0 && $restart_core_num -ge $restart_core_num_max ]]; then
        if [ $reboot_robot_num -lt $reboot_robot_num_max ]; then
            restart_core_num=0
            echo 'tj2022' | sudo -S echo $reboot_robot_num > /opt/systemd-sh/reboot_robot_num.txt
            str_output=$(date)" === reboot robot "${reboot_robot_num}" time"
            echo ${str_output} | tee -a $log_file_name
            # reboot
        else
            str_output=$(date)" === reboot robot exceeded max number, just do nothing"
            echo $str_output | tee -a $log_file_name
        fi
    fi


    sleep $time_interval
done



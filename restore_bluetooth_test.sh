#!/bin/bash

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=120

restart_core_num_max=2
restart_core_num=0
reboot_robot_num_max=2
reboot_robot_num=$(cat /opt/systemd-sh/reboot_robot_num.txt)
reboot_robot_num_last=$reboot_robot_num

while true;
do
    echo '------------------------------------------------------'
    if cat /home/tj2022/map/core_restart.txt | grep -q 1 ; then
        echo $(date)" --- In monitoring state. sleep ${time_interval} seconds first, waiting for bluetooth to be connected......" | tee -a $log_file_name
        sleep $time_interval
        echo $(date)" --- Begin to check bluetooth state ......" | tee -a $log_file_name
        if hciconfig -a | grep -iq $bluetooth_controller;then
            if bluetoothctl devices | grep -iq $charger_bluetooth_name;then
                str_output=$(date)" === normal"
                echo ${str_output} | tee -a $log_file_name
                restart_core_num=0
                reboot_robot_num=0
                reboot_robot_num_last=0
                echo 'tj2022' | sudo -S echo $reboot_robot_num > /opt/systemd-sh/reboot_robot_num.txt
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
        echo $(date)" --- Not in monitoring state." | tee -a $log_file_name
        restart_core_num=0
        reboot_robot_num=0
        reboot_robot_num_last=0
        echo 'tj2022' | sudo -S echo $reboot_robot_num > /opt/systemd-sh/reboot_robot_num.txt
        sleep $time_interval
    fi

    if [ $restart_core_num -gt 0 ]; then
        if [ $restart_core_num -le $restart_core_num_max ]; then
            docker compose -f /home/tj2022/docker-compose.yml restart core
            str_output=$(date)" ===  restart core "
            echo ${str_output} | tee -a $log_file_name
        else
            if [ $reboot_robot_num -le $reboot_robot_num_max ]; then
                reboot_robot_num=$(($reboot_robot_num + 1))
            fi
        fi
    fi

    if [ $reboot_robot_num -ne $reboot_robot_num_last ]; then
        if [ $reboot_robot_num -le $reboot_robot_num_max ]; then
            restart_core_num=0
            echo 'tj2022' | sudo -S echo $reboot_robot_num > /opt/systemd-sh/reboot_robot_num.txt
            str_output=$(date)" === reboot robot "${reboot_robot_num}" time"
            echo ${str_output} | tee -a $log_file_name
            reboot_robot_num_last=$reboot_robot_num
            reboot
        else
            str_output=$(date)" === reboot robot exceeded max number, just do nothing"
            echo $str_output | tee -a $log_file_name
        fi
    fi

done



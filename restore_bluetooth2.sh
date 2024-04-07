#!/bin/bash

function get_time_hour(){
    str=$(date '+%X')
    ifs_old="$IFS"
    IFS=":"
    array=($str)
    IFS="$ifs_old"
    hour=${array[0]}
    hour_int=`expr $hour + 0`
    echo "$hour_int"
}

#define time range
hour_start1=0
hour_end1=9
hour_start2=21
hour_end2=23

#generate log_file_name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are restor at "$log_file_name
echo ""


# for test
# test_str="00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23"
# test_arr=($test_str)
# for var in ${test_arr[@]}
# do
#     if [ $var -ge $hour_start1 -a $var -lt $hour_end1 ]; then
#         echo "$var in range"
#     else
#         if [ $var -ge $hour_start2 -a $var -le $hour_end2 ]; then
#             echo "$var in range"
#         else
#             echo "$var not in range"
#         fi
#     fi
# done

bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=60

while true;
do
    hour=$(get_time_hour)
    # echo "hour: $hour"
    if [[ $hour -ge $hour_start1 && $hour -le $hour_end1 ]] || [[ $hour -ge $hour_start2 && $hour -le $hour_end2 ]]; then 
        if hciconfig -a | grep -iq $bluetooth_controller;then
            if bluetoothctl devices | grep -iq $charger_bluetooth_name;then
                str_output=$(date)" === normal"
                echo ${str_output} | tee $log_file_name
            else
                str_output=$(date)" === restart core for reason: cann't find ai-thinker bluetooth"
                echo ${str_output} | tee $log_file_name
                docker compose -f /home/tj2022/docker-compose.yml restart core
            fi
        else
            str_output=$(date)" === restart core for reason: donn't have ${bluetooth_controller} controller"
            echo ${str_output} | tee $log_file_name
            docker compose -f /home/tj2022/docker-compose.yml restart core
            # docker compose -f /home/tj2022/docker-compose.yml up core -d
        fi
    else
        echo $(date)" --- not within the monitoring time range." | tee $log_file_name
    fi

    sleep $time_interval
done



# pwd修改为系统root密码
pwd="tj2022"

function get_char()
{
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}

function pause()
{
	# 启用功能的开关 1开启|其它不开启
	enable_pause=1

	# 判断第一个参数是否为空，约定俗成的写法
	if [ "x$1" != "x" ]; then
		echo $1
	fi
	if [ $enable_pause -eq 1 ]; then
		# echo "Press any key to continue!"
		echo "按任意键继续!"
		char=`get_char`
	fi
}

success=1

mkdir -p /home/tj2022/logs_bluetooth_restore
if [ $? == 0 ]; then
    echo "成功创建日志文件夹 /home/tj2022/logs_bluetooth_restore"
else
    echo "创建日志文件夹失败 /home/tj2022/logs_bluetooth_restore"
    success=0
fi

echo pwd | sudo -S cp ./restore_bluetooth.service /lib/systemd/system/restore_bluetooth.service
if [ $? == 0 ]; then
    echo "成功复制文件restore_bluetooth.service"
else
    echo "复制文件restore_bluetooth.service失败"
    success=0
fi

echo pwd | sudo -S mkdir -p /opt/systemd-sh
echo pwd | sudo -S cp ./resotre_bluetooth.sh /opt/systemd-sh/resotre_bluetooth.sh
if [ $? == 0 ]; then
    echo "成功复制文件restore_bluetooth.sh"
else
    echo "复制文件restore_bluetooth.sh失败"
    success=0
fi

echo pwd | sudo -S systemctl daemon-reload
echo pwd | sudo -S systemctl enable restore_bluetooth.service
echo pwd | sudo -S systemctl start restore_bluetooth.service
if [ $? == 0 ]; then
    echo "成功开启restore_bluetooth服务开机自启功能"
else
    echo "开启restore_bluetooth服务开机自启功能失败"
    success=0
fi

if [ success --eq 1 ]; then
    pause "自动配置已完成, 重启电脑后生效"
else
    pause "自动配置未成功，请参考手动模式
fi

1、复制restore_bluetooth.service 到 /lib/systemd/system

2、cd ~

3、mkdir logs_bluetooth_restore

4、cd /opt

5、sudo mkdir systemd-sh

6、复制restore_bluetooth.sh 到 /opt/systemd-sh

7、sudo systemctl enable bluetooth.service

8、reboot

9、修改时区为英国


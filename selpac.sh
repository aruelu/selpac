#!/bin/bash

TMPFILE="/tmp/selpac-"$$".tmp"
LOGFILE="/tmp/selpac-"$$".log"
PACFILE="/tmp/selpac_list-"$$".txt"

GETPASS=$( zenity --password )
if [ "$GETPASS" = "" ]
then
    zenity --error --text="パスワードが入力されていません"
    exit 1
fi
echo $GETPASS | sudo -S pwd
if [ $? != 0 ]
then
    zenity --error --text="パスワードが違います"
    exit 2
fi


GETSEL=$(zenity --list --title="処理選択" \
        --print-column=1 --column="ID" --column="select" \
        --width=600  --height=400 \
        "01" "パッケージをアップデート" \
        "02" "パッケージをフルアップデート" \
        "03" "パッケージを選んでアップデート" \
        "04" "不要なパッケージの削除" )

zenity --info --title="処理中" --display=$GETDISPLAY --text="このウィンドウが自動で閉じるまで待って下さい" &
GETPID=`echo $!`
case "$GETSEL" in
    "01")
        echo "sudo -S apt update" >> $LOGFILE
        echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt upgrade -y" >> $LOGFILE
        echo $GETPASS | sudo -S apt upgrade -y &>> $LOGFILE
        ;;
    "02")
        echo "sudo -S apt update" >> $LOGFILE
        echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt full-upgrade -y" >> $LOGFILE
        echo $GETPASS | sudo -S apt full-upgrade -y &>> $LOGFILE
        ;;
    "03")
        echo "sudo -S apt update" >> $LOGFILE
        echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo $GETPASS | sudo -S apt list --upgradable | grep "アップグレード可" | \
                cut -f 1 -d "/"  > $PACFILE
        kill $GETPID

        cat $PACFILE | zenity --list --column="パッケージ名" --multiple | sed s/"|"/" "/g > $TMPFILE
        RET=$(cat $TMPFILE)
        if [ "$RET" = "" ]
        then
            echo "" >> $LOGFILE
            echo "#################################################################" >> $LOGFILE
            echo "パッケージが選択されていません" >> $LOGFILE
        else
            zenity --info --title="処理中" --display=$GETDISPLAY --text="このウィンドウが自動で閉じるまで待って下さい" &
            GETPID=`echo $!`
            echo "" >> $LOGFILE
            echo "#################################################################" >> $LOGFILE
            echo "sudo -S apt install -y --only-upgrade "$RET >> $LOGFILE
            echo $GETPASS | sudo -S apt install -y --only-upgrade $RET &>> $LOGFILE
        fi
        ;;
    "04")
        echo "sudo -s apt update" >> $LOGFILE
        echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt autoremove -y "$RET >> $LOGFILE
        echo $GETPASS | sudo -S apt autoremove -y &>> $LOGFILE
        ;;
    *)
        echo "処理が選択されていません" >> $LOGFILE
        ;;
esac
kill $GETPID
zenity --text-info --title=結果 --width=600  --height=400 --filename=$LOGFILE

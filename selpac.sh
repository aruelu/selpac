#!/bin/bash

TMPFILE="/tmp/selpac-"$$".tmp"
LOGFILE="/tmp/selpac-"$$".log"
PACFILE="/tmp/selpac_list-"$$".txt"

GETPASS=$( zenity --password )
if [ "$GETPASS" = "" ]
then
    zenity --error --title="実行エラー" --text="パスワードが入力されていません"
    exit 1
fi
echo $GETPASS | sudo -S pwd
if [ $? != 0 ]
then
    zenity --error --title="実行エラー" --text="パスワードが違います"
    exit 2
fi


GETSEL=$(zenity --list --title="処理選択" \
        --print-column=1 --column="ID" --column="処理内容" \
        --width=600  --height=400 \
        "01" "パッケージをアップグレード" \
        "02" "パッケージをフルアップグレード" \
        "03" "パッケージを選んでアップグレード" \
        "04" "不要なパッケージの削除" )

zenity --info --title="処理中" --display=$GETDISPLAY --text="このウィンドウが自動で閉じるまで待って下さい" &
GETPID=$( echo $! )
case "$GETSEL" in
    "01")
        echo "sudo -S apt update" >> $LOGFILE
        #echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo $GETPASS | sudo -S apt update 2>&1 | tee -a $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt upgrade -y" >> $LOGFILE
        #echo $GETPASS | sudo -S apt upgrade -y &>> $LOGFILE
        echo $GETPASS | sudo -S apt upgrade -y 2>&1 | tee -a $LOGFILE 
        ;;
    "02")
        echo "sudo -S apt update" >> $LOGFILE
        #echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo $GETPASS | sudo -S apt update 2>&1 | tee -a $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt full-upgrade -y" >> $LOGFILE
        #echo $GETPASS | sudo -S apt full-upgrade -y &>> $LOGFILE
        echo $GETPASS | sudo -S apt full-upgrade -y 2>&1 | tee -a $LOGFILE
        ;;
    "03")
        echo "sudo -S apt update" >> $LOGFILE
        #echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo $GETPASS | sudo -S apt update 2>&1 | tee -a $LOGFILE
        echo $GETPASS | sudo -S apt list --upgradable | grep "アップグレード可" | \
                cut -f 1 -d "/"  > $PACFILE

        if [ $(cat $PACFILE | wc -l ) = 0 ]
        then
            echo "" >> $LOGFILE
            echo "#################################################################" >> $LOGFILE
            echo "アップグレード可のパッケージはありません" >> $LOGFILE
        else
            kill $GETPID
            cat $PACFILE | zenity --list --title="アップグレードするパッケージを選択" --column="パッケージ名" --multiple | sed s/"|"/" "/g > $TMPFILE
            RET=$(cat $TMPFILE)
            if [ "$RET" = "" ]
            then
                echo "" >> $LOGFILE
                echo "#################################################################" >> $LOGFILE
                echo "パッケージが選択されていません" >> $LOGFILE
                zenity --info --title="処理中" --display=$GETDISPLAY --text="このウィンドウが自動で閉じるまで待って下さい" &
                GETPID=$( echo $! )
            else
                zenity --info --title="処理中" --display=$GETDISPLAY --text="このウィンドウが自動で閉じるまで待って下さい" &
                GETPID=$( echo $! )
                echo "" >> $LOGFILE
                echo "#################################################################" >> $LOGFILE
                echo "sudo -S apt install -y --only-upgrade "$RET >> $LOGFILE
                #echo $GETPASS | sudo -S apt install -y --only-upgrade $RET &>> $LOGFILE
                echo $GETPASS | sudo -S apt install -y --only-upgrade $RET 2>&1 | tee -a $LOGFILE
            fi
        fi
        ;;
    "04")
        echo "sudo -s apt update" >> $LOGFILE
        #echo $GETPASS | sudo -S apt update &>> $LOGFILE
        echo $GETPASS | sudo -S apt update 2>&1 | tee -a $LOGFILE
        echo "" >> $LOGFILE
        echo "#################################################################" >> $LOGFILE
        echo "sudo -S apt autoremove -y "$RET >> $LOGFILE
        #echo $GETPASS | sudo -S apt autoremove -y &>> $LOGFILE
        echo $GETPASS | sudo -S apt autoremove -y 2>&1 | tee -a $LOGFILE
        ;;
    *)
        echo "処理が選択されていません" >> $LOGFILE
        ;;
esac
kill $GETPID
zenity --text-info --title=結果 --width=600  --height=400 --filename=$LOGFILE

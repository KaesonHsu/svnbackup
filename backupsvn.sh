#!/bin/bash
 
#存放SVN仓库的根目录
ROOT_PATH=/home/disk/svn
CUR_DATE=`date +%Y%m%d`
#备份文件存放根位置
BACKUP_ROOT_PATH=/home/disk/svnbackup
#备份文件存放位置
BACKUP_TARGET_PATH=$BACKUP_ROOT_PATH"/"$CUR_DATE
#备份SVN仓库
svn_back_up(){
        CUR_PATH=$1
        CUR_PATH_NAME=$2
        BACKUP_PATH=$BACKUP_TARGET_PATH"/"$CUR_PATH_NAME
        if [ ! -d $BACKUP_PATH ]
        then
                mkdir $BACKUP_PATH
        fi
        BACKUP_FILE_NAME="week_backup_$CUR_PATH_NAME".`date +%Y%m%d`
        log="$BACKUP_PATH/week_backup.log"
        echo "********************"`date`"***************">>$log
        echo "$BACKUP_PATH SVN ALL DUMP START!!">>$log
        if [ ! -f $BACKUP_PATH"/"$BACKUP_FILE_NAME ]
        then
                svnadmin dump --incremental --revision 0:$LAST_VERSION $CUR_PATH > $BACKUP_PATH"/"$BACKUP_FILE_NAME
                #echo "svnadmin dump"
        else
                echo "$BACKUP_PATH SVN ALL DUMP DUMP BEFORE">>$log
        fi
        echo "$BACKUP_PATH SVN ALL DUMP END!!VERSION:$LAST_VERSION">>$log
}
#压缩已备份的文件
zip_svn_backup_file(){
        pushd $BACKUP_ROOT_PATH
        tar cvzf $CUR_DATE"_SVN_BACK_UP".tar.gz $CUR_DATE
        popd
        rm -rf $BACKUP_TARGET_PATH
}
#遍历svn目录下所有SVN仓库
start_back_up(){
        for file in `ls -a $1`
        do
                if [ -d $1"/"$file ]
                then
                        if [[ $file != '.' && $file != '..' ]]
                        then
                                if [ -f $1"/"$file"/format" ]
                                then
                                        LAST_VERSION="`svnlook youngest $1"/"$file`"
                                        if [ "`echo $?`" == "0" ]
                                        then
                                                #查询版本号成功，开始备份
                                                svn_back_up $1"/"$file $file
 
                                        fi
                                        else
                                                start_back_up $1"/"$file
                                        fi
                        fi
                else
                        echo $1"/"$file
                fi
        done
}
 
if [ ! -d $BACKUP_TARGET_PATH ]
then
        mkdir $BACKUP_TARGET_PATH
fi
 
start_back_up $ROOT_PATH
zip_svn_backup_file
#将备份压缩文档上传至另外一台服务器 ftp
ftp -i -n <<!
open 192.168.1.172
user uftp rt123456
lcd $BACKUP_ROOT_PATH
put $CUR_DATE"_SVN_BACK_UP.tar.gz"
bye
!
#删除超过20天的备份文件
find $BACKUP_ROOT_PATH -type f -mtime +20 -exec rm -rf {} \;
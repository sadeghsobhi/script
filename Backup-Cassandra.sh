#!/bin/bash


#echo "[default]
#output=json" > /root/.aws/config

#AWS_CONFIG_FILE=/root/.aws/config

#export KEYSPACE="DB1"
#export SNAPSHOT=$2
export BD_DIR=/home/ubuntu/cassandra/data
export BACKUP_DIR=s3://test-bucket/spanshot/
export exists="aws s3 ls $BACKUP_DIR"
export File_tar=/home/ubuntu/cassandra/tar

runTakeBackup=$(date +%s)
/usr/bin/docker exec cassandra nodetool snapshot -t $runTakeBackup

#takeBackupString="/usr/bin/docker run --rm  --network=nodetool_default  mynodetool:latest -h cassandra -p 7199 -u cassandra -pw cassandra snapshot"
#runTakeBackup=$(eval $takeBackupString | grep "Snapshot directory:" | tr -d -c 0-9)

echo "SNAPSHOT CODE IS $runTakeBackup"

export SNAPSHOT=$runTakeBackup




for KEYSPACEFULL in $BD_DIR/*; do
    KEYSPACE=$(basename $KEYSPACEFULL );
    echo "I am here: $KEYSPACE"
    dirNameSystem=$( echo -n $KEYSPACE | grep 'system' | wc -l )
    if [ $dirNameSystem = 0 ]
    then
        for DIR in $BD_DIR/$KEYSPACE/*/snapshots; do
            echo "------------------------"
            BackupDirectory=$(basename "$(dirname "$DIR")" );
            DEST="$BACKUP_DIR/$KEYSPACE/$BackupDirectory/$SNAPSHOT/"
            e="find $BD_DIR/$KEYSPACE -type d -iname $SNAPSHOT"
            result=$(eval $e | wc -l)
            if [ $result = 0 ]
            then
                echo "could not copy Snapshot!"
            else
                tar czfP $File_tar/$BackupDirectory"_"$SNAPSHOT.tar.gz $DIR/$SNAPSHOT
		echo "Tar Files Created Successfully."
                #cpToCeph="aws --endpoint=http://172.16.0.0 s3 cp $File_tar/$BackupDirectory"_"$SNAPSHOT.tar.gz $BACKUP_DIR"
		#cpToCeph="//172.16.0.12/Backup-Data/Projectname /home/sobhi-s/cassandra/tar  cifs dir_mode=0755,file_mode=0755,uid=10001,username=test,password=test  0  0"
                #echo $cpToCeph
		#cpResult=$(eval $cpToCeph | grep ' not ' | wc -l)
                #if [ $cpResult = 0 ]; then
                #    echo "Backup uploaded to CEPH Successfully: $BackupDirectory"_"$SNAPSHOT"
                #    #rm -rf $DIR/$SNAPSHOT $File_tar/$BackupDirectory"_"$SNAPSHOT.tar.gz
                #else
                #    echo "copy failed: $cpToCeph"
                #fi
            fi

        done
    fi
done


preNameSnapshot=${SNAPSHOT:0:3}"*"

echo "Deleting system snapshot files with name: $preNameSnapshot"
find $BD_DIR  -name  $preNameSnapshot -type d -prune -exec rm -rvf {} \; | grep "testbataroglandi"
echo "Deleted Successfully."
echo "Done!"


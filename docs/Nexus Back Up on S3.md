## Why Back Up?

안정적인 서비스를 운영하는 이미지를 별도로 보관해두어야 특정 문제가 발생 시 서비스를 보다 더 빠르게 재 복구할 수 있다고 생각하여 Private Repository 를 백업을 진행하였다.

## How Back Up?

![image](https://user-images.githubusercontent.com/93571332/206101533-f5276b5b-1940-448e-876b-b63a481afb88.png)

1. Nexus 주요 설정이 담긴 폴더를 tar 로 압축하고 S3에 업로드
2. 자정에 백업이 실행되도록 설정

## Back Up Setting

### Create a Cronjob

```bash
$ vi /home/script/nexus_backup.sh 
echo 'tar /nexus-data directory'
set +e
tar -cvf nexus_backup$(date +%Y%m%d).tar /nexus-data .
exitcode=$?
if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
exit $exitcode
fi
set -e
echo 'Upload nexus_backup.tar to S3 bucket'
aws s3 cp nexus_backup$(date +%Y%m%d).tar s3://nexusbackupoctopusdream/
echo 'Remove files after succesfull upload to S3'
rm -rf nexus_backup$(date +%Y%m%d).tar

$ chmod +x /home/script/nexus_backup.sh

$ crontab -e
0 0 * * * /home/script/nexus_backup.sh  --> 매일 자정에 백업

$ service cron start
```

### Check backup

```bash
$ aws s3 ls nexusbackupoctopusdream
2022-12-05 06:39:47 1018193920 nexus_backup20221205.tar
```

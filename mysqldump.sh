#!/bin/bash
export $(cat .env | grep -v \# | xargs )
FILE_NAME=$(date +%Y-%m-%d-%H-%M)
DATE=(date +%Y-%m-%d-%H-%M)
DATABASE_PASS=$1

if [[ -z "$1" ]]
then
    echo -e "please enter your password after run command\n"
    exit
fi


database_list () {
  mysql -uroot -p$1 -e "SHOW DATABASES;" | grep -v 'Data\|schema\|+' > /tmp/db-list
}
database_backup () {
  mysqldump -uroot -p$2 --single-transaction $1 > /tmp/$1-$FILE_NAME.sql
}
all_databases_backup () {
  mysqldump -uroot -p$1 --single-transaction -A > /tmp/all-$FILE_NAME.sql
}
zip_file () {
  zip /tmp/$1.zip /tmp/$1
  rm /tmp/$1
}
transfer_to_dest () {
  scp -P $DEST_PORT /tmp/$1 $DEST_USER@$DEST_IP:$DEST_PATH
  rm /tmp/$1
}

database_list $DATABASE_PASS
for DB in $(cat /tmp/db-list)
do
  echo -e "$DATE - backup create for $DB database\n"
  database_backup $DB $DATABASE_PASS
  echo -e "$DATE - zip $DB backup file\n"
  zip_file $DB-$FILE_NAME.sql
  echo -e "$DATE - transfer $DB backup file to backup box\n\n"
  transfer_to_dest $DB-$FILE_NAME.sql.zip
done

echo -e "$DATE - backup create for all databases\n"
all_databases_backup $DATABASE_PASS
echo -e "$DATE - zip all databases backup file\n"
zip_file all-$FILE_NAME.sql
echo -e "$DATE - transfer backup file all databases to backup box\n\n"
transfer_to_dest all-$FILE_NAME.sql
echo -e "$DATE - all done\n"


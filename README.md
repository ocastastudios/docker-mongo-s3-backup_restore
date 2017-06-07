# Backup a MongoDB datbase to an S3 Bucket

Docker image to run once and backup a MongoDB database to S3

Environment variables:


AUTH_DATABASE are mandatory which defaults to *admin*
BACKUP_FILENAME defaults to  

E.g.

    docker run -e HOST=rs/mymongo-1:27017,mymongo-2:27017 -e ADMIN_USER=admin -e ADMIN_PASSWORD=mypass -e AUTH_DATABASE=rudolph -e NEW_DATABASE=newdb1 -e NEW_USER=newuser1 -e NEW_PASSWORD=password --link mongodb -d ocasta/mongo-init

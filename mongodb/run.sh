docker run --name mongodb1 -p 27017:27017/tcp -v $PWD/data/db:/data/db -e MONGO_INITDB_ROOT_USERNAME=$MONGODB_USERNAME -e MONGO_INITDB_ROOT_PASSWORD=$MONGODB_PASSWORD -d mongo

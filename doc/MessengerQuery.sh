#!/bin/bash

# proof of concept communication wth a matlab Messenger using shell commands

# Instructions: in matlab: create a Messenger object
#
#   M=obs.util.Messenger('',[],40000)
#   M.connect

# In the shell: MessengerQuery.sh <host> <port> <command>
#
# Examples: ./MessengerQuery.sh localhost 40000 "atand(1)"
#           ./MessengerQuery.sh localhost 40000 "a=3.4"
#           ./MessengerQuery.sh localhost 40000 "a/3"


HOST=$1
PORT=$2
COMMAND=$3
TIMESTAMP=739107.64072227245 # read a compatible timestamp, but not really important
LOCALPORT=55555 # or better, find the port used by nc

JSTRING=`echo '{"From":{"Host":"localhost","Port":'$LOCALPORT'},'\
              '"ReplyTo":{"Host":"localhost","Port":'$LOCALPORT'},'\
              '"SentTimestamp":'\$TIMESTAMP',"ReceivedTimestamp":[],'\
              '"ProgressiveNumber":2,"Command":"'$COMMAND'",'\
              '"RequestReply":true,"Content":[],"EvalInListener":false}'`

#echo $JSTRING

echo $JSTRING | nc -uC -W 1 -q 1 -w 2 -p $LOCALPORT $HOST $PORT

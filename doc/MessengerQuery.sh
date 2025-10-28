#!/bin/bash
[ "$1" = "-h" -o "$1" = "--help" -o $# -ne 3 ] && echo "
# proof of concept communication wth a matlab Messenger using shell commands

# Instructions: in matlab: create a Messenger object
#
#   M=obs.util.Messenger('',[],40000)
#   M.connect

# In the shell: MessengerQuery.sh <host> <port> <command>
#
# Examples: ./MessengerQuery.sh localhost 40000 \"atand\(1\)\"
#           ./MessengerQuery.sh localhost 40000 \"a=3.4\"
#           ./MessengerQuery.sh localhost 40000 \"a/3\"
" && exit

HOST=$1
PORT=$2
COMMAND=$3
# date %s gives seconds from 1/1/1970, Matlab timestamp is days since 0/1/0000
# UTC
#TIMESTAMP=`bc <<<  "scale=9; $(( $(date +%s) ))/86400.0+719529"`
# tentative accounting for integer timezone
TIMESTAMP=`bc <<<  "scale=9; ($(( $(date +%s) )) + $(( $(date +%:::z) ))*3600.)/86400.0+719529"`
LOCALHOST=`hostname -s`
#LOCALHOST="localhost"
# note: for some reason the reply does not work on CFENRICO-PC01,
#  not even with hostname -i, or localhost. I think
#  that it has to do with ip-name resolution somewhere between the
#  matlab Messenger and nc. It works on last computers, though.
# Listeners cannot determine the port they receive from, hence fix it so that
#  it can be written in the message
LOCALPORT=55555
TIMEOUT=5

JSTRING=`echo '{"ReplyTo":{"Host":"'$LOCALHOST'","Port":'$LOCALPORT'},'\
              '"SentTimestamp":'$TIMESTAMP',"ReceivedTimestamp":[],'\
              '"ProgressiveNumber":'$RANDOM',"Command":"'$COMMAND'",'\
              '"RequestReplyWithin":'$TIMEOUT',"Content":[],"EvalInListener":false}'`

#echo $JSTRING

# jq -r | jq to unescape the encoded json answer
echo -n $JSTRING | nc -uC -W 1 -q 1 -w $TIMEOUT -p $LOCALPORT $HOST $PORT \
  | jq -r .Content | jq


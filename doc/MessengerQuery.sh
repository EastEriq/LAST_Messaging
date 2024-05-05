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
TIMESTAMP=`bc <<<  "scale=9; $(( $(date +%s) ))/86400.0+719529"`

JSTRING=`echo '{"ReplyTo":{"Host":"localhost","Port":[]},'\
              '"SentTimestamp":'$TIMESTAMP',"ReceivedTimestamp":[],'\
              '"ProgressiveNumber":'$RANDOM',"Command":"'$COMMAND'",'\
              '"RequestReplyWithin":10,"Content":[],"EvalInListener":false}'`

#echo $JSTRING

echo -n $JSTRING | nc -uC -W 1 -q 1 -w 2 $HOST $PORT | jq
echo

#!/bin/bash
JSON=`curl -s https://heatwallet.com/status2.cgi`
CHAINHEIGHT=`echo $JSON | jq -r '.lastBlockchainFeederHeight' | tr -dc '0-9'`
echo "CHAINHEIGHT: $CHAINHEIGHT"

JSON=`curl -X GET --header 'Accept: application/json' 'http://192.168.122.19:7733/api/v1/blockchain/status'`
LAST_BLOCK=`echo $JSON | jq -r '.lastBlock'`
TIMESTAMP=`echo $JSON | jq -r '.lastBlockTimestamp'`
CURRENT_TIME=`date +%s`
echo "last block: $LAST_BLOCK"
echo "current time: $CURRENT_TIME"
echo "last block time: $TIMESTAMP"

JSON=`curl -X GET --header 'Accept: application/json' 'http://192.168.122.19:7733/api/v1/blockchain/$LAST_BLOCK/1234/false'`
HEIGHT=`echo $JSON | jq -r '.height'`
echo "last block height: $HEIGHT"


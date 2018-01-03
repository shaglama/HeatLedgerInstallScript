#!/bin/bash
#Version 0.1.5.1
#HEAT Ledger Bash Install Script for Ubuntu
#Randy Hoggard
#January 2 2018
 
#----------Vars----------------------------------------------------------------
SCRIPT=`readlink -f $0`
RELEASE_JSON=""= #json returned from polling github for newest release, set automatically
RELEASE_NUM="" #heatledger version number, set automatically
RELEASE="" #heatledger release name, set automatically
RELEASE_FILE="" #the heatledger file, set automatically
RELEASE_URL="" #the url to download heatledger from, set automatically
SNAPSHOT_URL="https://heatbrowser.com/blockchain.tgz" #the url where heatledger blockchain snapshots are hosted
HEAT_USER=$USER #user to run the node with, defaults to user that runs the script. to set a different user change here or pass in as argument, if user does not exist it will be created
PASSWORD= #password for creating a new user, if new user is created without changing the password here or passing in as argument you will need to set the password yourself after running this script
API_KEY="changeMePlease" #Default api key, please change or pass in as argument
IP_ADDRESS="" #public ip address or host, set here or pass as argument. if no value is set, the script will attempt to obtain it from a public provider (dynDNS)
WALLET_SECRET="" #the secret passphrase for the wallet running the node, set here or pass as argument
HEAT_ID="" #the account id of the wallet running the node, set here or pass in as argument
MAX_PEERS=500 #number of peers node should connect to,set here or pass as argument, defaults to 500
HALLMARK="" #the node hallmark, increases forging profits, set here or pass in as argument, if not set script will attempt to create a new hallmark for the node
FORCE_SCAN="false" #if set to true node will be configured to rescan blockchain
FORCE_VALIDATE="false" #if set to true node will be configured to revalidate transactions on the blockchain
USE_SNAPSHOT="false" #if set to true, a snapshot of the blockchain will be downloaded from heatbrowser.com
CURRENT_DATE="" #No need to set this, its automatically obtained


#------------Functions---------------------------------------------------------
encodeURIComponent() {
  awk 'BEGIN {while (y++ < 125) z[sprintf("%c", y)] = y
  while (y = substr(ARGV[1], ++j, 1))
  q = y ~ /[[:alnum:]_.!~*\47()-]/ ? q y : q sprintf("%%%02X", z[y])
  print q}' "$1"
}

#----------Program-------------------------------------------------------------

#update repos and packages and install dependencies
#sudo add-apt-repository ppa:neurobin/ppa #
sudo apt-get update &&
sudo apt-get install -y default-jdk &&
sudo apt-get install -y unzip &&
sudo apt-get install -y screen &&
sudo apt-get install -y curl && 
sudo apt-get install -y jq && #to parse JSON
sudo apt-get install -y bc && #for math

#get latest release info
RELEASE_JSON=`curl -s https://api.github.com/repos/Heat-Ledger-Ltd/heatledger/releases/latest`
RELEASE_NUM=`echo "$RELEASE_JSON" | jq -r ".tag_name" | cut -c 2-`
RELEASE_FILE=`echo "$RELEASE_JSON" | jq -r ".assets[0] | .name"`
RELEASE_URL=`echo "$RELEASE_JSON" | jq -r ".assets[0] | .browser_download_url"`
RELEASE=`echo "$RELEASE_FILE" | rev | cut -c 5- | rev`

echo "RELEASE: $RELEASE"
echo "VERSION: $RELEASE_NUM"
echo "FILE: $RELEASE_FILE"
echo "URL: $RELEASE_URL"

#get arguments
# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # This is a flag type option. Will catch either -f or --foo
       # -f|--foo)
        #FOO=1
        #;;
        # Also a flag type option. Will catch either -b or --bar
        #-b|--bar)
        #BAR=1
        #;;
        # This is an arg value type option. Will catch -u userName or --user userName
        -u|--user)
        shift # past the key and to the value
        HEAT_USER="$1"      
        ;;
			
        -p|--password)
        shift # past the key and to the value
        PASSWORD="$1"
        ;;
        
			-k|--key)
			shift #past the key and to the value
			API_KEY="$1"
			;;
			
			-i|--ipAddress)
			shift
			IP_ADDRESS="$1"
			;;	
			
			-a|--accountNumber)
			shift
			HEAT_ID="$1"
			;;
			
			-s|--walletSecret)#need to encode later, don't forget
			shift
			WALLET_SECRET="$1"
			;;
			
			-m|--maxPeers)
			shift
			MAX_PEERS="$1"
			;;
			        
			-h|--hallmark)
			shift
			HALLMARK="$1"
			;;
			
			-fr|--forceScan)
			shift
			FORCE_SCAN="$1"
			;;
			
			-fv|--forceValidate)
			shift
			FORCE_VALIDATE="$1"
			;;
			
			-d|--downloadSnapshot)
			shift
			USE_SNAPSHOT="$1"
			;;
			      
        # This is an arg=value type option. Will catch -u=userName or --user=userName
        -u=*|--user=*)
        # No need to shift here since the value is part of the same string
        HEAT_USER="${key#*=}"        
        ;;
        
        -p=*|--password=*)
        # No need to shift here since the value is part of the same string
        PASSWORD="${key#*=}"
        ;;
        
			-k=*|--key=*)
			#No need to shift here since the value is part of the same string
			API_KEY="${key#*=}"
			;;
			
			-i=*|--ipAddress=*)
			IP_ADDRESS="${key#*=}"
			;;
			
			-a=*|--accountNumber=*)
			HEAT_ID="${key#*=}"
			;;
			
			-s=*|--walletSecret=*)
			WALLET_SECRET="${key#*=}"
			;;
			
			-m=*|--maxPeers=*)
			MAX_PEERS="${key#*=}"
			;;
			
			-h=*|--hallmark=*)
			HALLMARK="${key#*=}"
			;;
			
			-fs=*|--forceScan=*)
			FORCE_SCAN="${key#*=}"
			;;
			
			-fv=*|--forceValidate=*)
			FORCE_VALIDATE="${key#*=}"
			;;        
        
        	-d=*|--downloadSnapshot=*)
        	USE_SNAPSHOT="${key#*=}"
        	;;
        	
        *)
        # Do whatever you want with extra options
        echo "Unknown option '$key'"
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done
#verify user
if id "$HEAT_USER" >/dev/null 2>&1; then
       #user exists
       #proceed
       echo $HEAT_USER
else
       #user does not exist
      # quietly add a user without password
		adduser --quiet --disabled-password --shell /bin/bash --home /home/$HEAT_USER --gecos "User" $HEAT_USER
		#if password was supplied, set user password
		if [[ $PASSWORD = *[!\ ]* ]]; then
 			 # set password
			 echo "$USER:$PASSWORD" | chpasswd
		fi
		
		 
fi
#make sure home directory exists for user
if test -d /home/$HEAT_USER/;
 then
    #directory exists
    echo "home exists"
else
   #directory does not exist
   sudo mkdir /home/$HEAT_USER
   sudo chown -r  "$USER:$HEAT_USER" /home/$HEAT_USER
fi

#make sure node ip is set, if not try to determine what it is
if [[ $IP_ADDRESS = *[!\ ]* ]]; then
 		 #already set
 		 echo "$IP_ADDRESS"
 else
		 IP_ADDRESS=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'` &&
		 echo "IP ADDRESS: $IP_ADDRESS"
fi

#Verify HEAT_ID (accountNumber in arguments)
if [[ $HEAT_ID = *[!\ ]* ]]; then
	#already set
	echo "$HEAT_ID"
else 
	echo "HEAT_ID was not set in this script or passed in as an argument (accountNumber). HEAT_ID is required. Exiting script."
	exit 1
fi

##Verify and encode WALLET_SECRET
if [[ $WALLET_SECRET = *[!\ ]* ]]; then
	#already set
	#URI encode it
	ENCODED=$(encodeURIComponent "$WALLET_SECRET")
	#WALLET_SECRET="$ENCODED"
else 
	echo "WALLET_SECRET was not set in this script or passed in as an argument. WALLET_SECRET IS REQUIRED. Exiting script."
	exit 1
fi

##Verify FORCE_SCAN
#Convert to lower case
FS_LC=`echo "$FORCE_SCAN" | sed 's/.*/\L&/'`
if [[ "$FS_LC" == "true" || "$FS_LC" == "false" ]]; then
	FORCE_SCAN="$FS_LC"
	echo "Force Scan = $FORCE_SCAN"
else
	echo "$FORCE_SCAN is invalid value for force scan. Valid values are true and false"
	exit 1	
fi

##Verify FORCE_VALIDATE
#Convert to lower case
FV_LC=`echo $FORCE_VALIDATE | sed 's/.*/\L&/'`
if [[ "$FV_LC" == "true" || "$FV_LC" == "false" ]]; then
	FORCE_VALIDATE="$FV_LC"
	echo "Force validate = $FORCE_VALIDATE"
else
	echo "$FORCE_VALIDATE is invalid value for force validate. Valid values are true and false"
	exit 1		
fi

##Verify USE_SNAPSHOT
#Convert to lower case
US_LC=`echo $USE_SNAPSHOT | sed 's/.*/\L&/'`
if [[ "$US_LC" == "true" || "$US_LC" == "false" ]]; then
	USE_SNAPSHOT="$US_LC"
	echo "Use snapshot: $USE_SNAPSHOT"
else
	echo "$USE_SNAPSHOT is invalid value for Download Snapshot (USE_SNAPSHOT). Valid values are true and false"
	exit 1		
fi

##GET HALLMARK HERE
if [[ $HALLMARK = *[!\ ]* ]]; then
	#already set
	echo "$HALLMARK"
else 
	CURRENT_DATE=$(date +'%Y-%m-%d') &&
	HALLMARK_URL="https://heatwallet.com:7734/api/v1/tools/hallmark/encode/$IP_ADDRESS/200/$CURRENT_DATE/$ENCODED"
	echo "hallmark url: $HALLMARK_URL"
	HALLMARK_RESPONSE=`curl -X GET --header 'Accept: application/json' $HALLMARK_URL` &&
	echo "hallmark response: $HALLMARK_RESPONSE"
	HALLMARK=`echo "$HALLMARK_RESPONSE" | cut -c14- | rev | cut -c3- | rev` &&
	echo "HALLMARK: $HALLMARK"	
fi

#setup files
INSTALL_DIR="/home/$HEAT_USER"
BASE_DIR="$INSTALL_DIR/HeatLedger"
VER_DIR="$BASE_DIR/$RELEASE"
CONF_DIR="$VER_DIR/conf"
BIN_DIR="$VER_DIR/bin"

CONF="$CONF_DIR/heat.properties"
BIN="$BIN_DIR/heatledger"
SVC="$BASE_DIR/heatLedger.service"
SYS_SVC="/etc/systemd/system/heatLedger.service"
STRT="$BASE_DIR/startHeatLedger.sh"
STRT_MINING="$BASE_DIR/startMining.sh"
DELY_MINING="$BASE_DIR/delayMining.sh"
MINING_INFO="$BASE_DIR/miningInfo.sh"
HELP="$BASE_DIR/help.sh"
UNINSTALL="$BASE_DIR/uninstall.sh"
UPDATE="$BASE_DIR/update.sh"
STATUS="$BASE_DIR/status.sh"
IS_SYNCED="$BASE_DIR/isSynced.sh"

#download and extract heatLedger

mkdir $BASE_DIR
cd $BASE_DIR
wget $RELEASE_URL &&
unzip $RELEASE_FILE &&
cd "$VER_DIR"

#download snapshot if neccessary
if [[ "$USE_SNAPSHOT" == "true" ]]; then
	cd $BIN_DIR
	wget $SNAPSHOT_URL
	tar -zxvf blockchain.tgz
	rm blockchain.tgz
fi
	
#create config file
touch $CONF 
echo "heat.apiKey=$API_KEY" > $CONF 
echo "heat.myAddress=$IP_ADDRESS" >> $CONF
echo "heat.myPlatform=$HEAT_ID" >> $CONF
echo "heat.maxNumberOfConnectedPublicPeers=$MAX_PEERS" >> $CONF
echo "heat.myHallmark=$HALLMARK" >> $CONF
echo "heat.forceScan=$FORCE_SCAN" >> $CONF
echo "heat.forceValidate=$FORCE_VALIDATE" >> $CONF
echo "#heat.startForging=$ENCODED" >> $CONF

echo "Configuration written: " 
cat $CONF

#create start script
echo "\
#!/bin/bash
if echo \"\$(screen -ls 'heatLedger')\" | grep -q 'heatLedger'; then
	echo 'Failed to start heatLedger. There is already an instance running!'
else
	echo 'Starting node'
	echo 'to attach to node : in terminal type  	screen -s heatLedger'
	echo 'to detach from node while attached : hold control and press a. press d'
	echo 'to kill node while attached: hold control and press a. press k. press y.
	screen -dmS heatLedger /bin/bash $BIN &
	screen -list | grep 'heatLedger' | cut -f1 -d'.' | sed 's/\W//g' > '/home/$HEAT_USER/HeatLedger/startHeatLedger.pid'
fi
" >> $STRT
echo sudo chmod +x $STRT
echo sudo chmod 700 $STRT


#echo "#!/bin/bash" > $STRT
#echo "echo 'Starting node'" >>$STRT
#echo "echo 'to attach to node : in terminal type  	screen -s heatLedger'" >> $STRT
#echo "echo 'to detach from node while attached : hold control and press a. press d'" >> $STRT
#echo "echo 'to kill node while attached: hold control and press a. press k. press y.'" >> $STRT
####echo "touch '/home/$HEAT_USER/HeatLedger/startHeatLedger.pid"
#echo "screen -dmS heatLedger /bin/bash $BIN &" >> $STRT
#echo "screen -list | grep 'heatLedger' | cut -f1 -d'.' | sed 's/\W//g' > '/home/$HEAT_USER/HeatLedger/startHeatLedger.pid'" >> $STRT 
#sudo chmod +x $STRT

#create status script
echo "\
#!/bin/bash
JSON=\`curl -s https://heatwallet.com/status2.cgi\` > /dev/null
CHAINHEIGHT=\`echo \$JSON | jq -r '.lastBlockchainFeederHeight' | tr -dc '0-9'\`
CHAINBLOCK=\`echo \$JSON | jq -r '.lastBlock'\`
CHAINBLOCK_TIME=\`echo \$JSON | jq -r '.lastBlockTimestamp'\`
JSON=\`curl -s -X GET --header 'Accept: application/json' 'http://localhost:7733/api/v1/blockchain/status'\` > /dev/null
LAST_BLOCK=\`echo \$JSON | jq -r '.lastBlock'\`
TIMESTAMP=\`echo \$JSON | jq -r '.lastBlockTimestamp'\`
CURRENT_TIME=\`date +%s\`
URL=\"http://localhost:7733/api/v1/blockchain/block/$LAST_BLOCK/false\"
JSON=\`curl -s -X GET --header 'Accept: application/json' \$URL\` > /dev/null
HEIGHT=\`echo \$JSON | jq -r '.height'\`
BEHIND=\$((\$CHAINHEIGHT - \$HEIGHT))
BEHIND_TIME=\$((\$CHAINBLOCK_TIME - \$TIMESTAMP))
DAYS=\`echo \"\$BEHIND_TIME / (60 * 60 * 24)\" | bc -l\`
WHOLE_DAYS=\`echo \"scale=0; \$DAYS / 1\" | bc -l\`
HOURS=\`echo \"24 * (\$DAYS - \$WHOLE_DAYS)\" | bc -l\`
WHOLE_HOURS=\`echo \"scale=0; \$HOURS / 1\" | bc -l\`
MINUTES=\`echo \"scale=0;(60 * (\$HOURS - \$WHOLE_HOURS) / 1)\" | bc -l\`
echo \"Chain Height: \$CHAINHEIGHT\"
echo \"Node Height: \$HEIGHT\"
echo \"\$BEHIND blocks behind\"
echo \"\$WHOLE_DAYS days \$WHOLE_HOURS hours \$MINUTES minutes behind\"
echo \"Current Chain Block: \$CHAINBLOCK\"
echo \"Current Chain Timestamp: \$CHAINBLOCK_TIME\"
echo \"Current Node Block: \$LAST_BLOCK\"
echo \"Current Node Timestamp: \$TIMESTAMP\"
if [[ \$TIMESTAMP -lt \$CHAINBLOCK_TIME ]]; then
        echo \"not synced\"
else 
        echo \"synced\"
fi\
" > $STATUS
sudo chmod +x $STATUS
sudo chmod 700 $STATUS

#create isSynced script
echo "\
!#/bin/bash
RESULT=\`./status.sh | grep 'not synced'\`
if [[ \$RESULT == 'not synced' ]]; then
        echo \"false\"
else
        echo \"true\"
fi\
" > $IS_SYNCED
sudo chmod +x $$IS_SYNCED
sudo chmod 700 $IS_SYNCED


#create mining start script
echo "\
#!/bin/bash
SYNCED=\`./isSynced.sh\`
if [[ \$SYNCED == 'true' ]]; then
        echo \"Issuing start forging command to node\"
        curl -k -s http://localhost:7733/api/v1/mining/start/$ENCODED\?api_key=$API_KEY >> startMining.log
else
        echo \"Cannot start forging, node is not synced yet!!\"
fi\
" > $STRT_MINING
sudo chmod +x $STRT_MINING
sudo chmod 700 $STRT_MINING



#create mining start script
#touch $STRT_MINING
#echo "#!/bin/bash" > $STRT_MINING
#echo "Starting Forging" >> startMining.log
#echo date >> startMining.log
#echo "curl -k -s http://localhost:7733/api/v1/mining/start/$ENCODED\?api_key=$API_KEY >> startMining.log" >> $STRT_MINING
#sudo chmod +x $STRT_MINING
#sudo chmod 700 $STRT_MINING


#create mining delay script
echo "\
#!/bin/bash
INTERVAL=5m
SYNCED=\`./isSynced.sh\`
while [[ \$SYNCED == 'false' ]]
do
        sleep \$INTERVAL &&
        SYNCED=\`./isSynced.sh\`
done
./startMining.sh\
" > $DELY_MINING
sudo chmod +x $DELY_MINING
sudo chmod 700 $DELY_MINING




#create mining delay script
#touch $DELY_MINING
#echo "#!/bin/bash" > $DELY_MINING
#echo "INFO=\`./$MINING_INFO\`" >> $DELY_MINING
#echo "sleep 1h &&" >> $DELY_MINING 
#echo "./startMining.sh" >> $DELY_MINING
#sudo chmod +x $DELY_MINING



#create mining info script
touch $MINING_INFO
echo "#!/bin/bash" > $MINING_INFO
echo "echo 'Mining Info' >> miningInfo.log" >> $MINING_INFO
echo "date >> miningInfo.log" >> $MINING_INFO
echo "curl -k -s http://localhost:7733/api/v1/mining/info/$ENCODED\?api_key=$API_KEY | tee miningInfo.log" >> $MINING_INFO
sudo chmod +x $MINING_INFO
sudo chmod 700 $MINING_INFO

#create help script
touch $HELP
echo "echo 'HeatLedger Helper Help'" >> $HELP
echo "echo 'to attach to node : in terminal type      screen -s heatLedger'" >> $HELP
echo "echo 'to detach from node while attached : hold control and press a. press d'" >> $HELP
echo "echo 'to kill node while attached: hold control and press a. press k. press y.'" >> $HELP
echo "echo 'to enable forging, run startMining.sh after node has synced, logs to startMining.log'" >> $HELP
echo "echo 'to check forging status, run miningInfo.sh and then check miningInfo.log'" >> $HELP
sudo chmod +x $HELP

#create service
touch $SVC
echo "[Unit]" > $SVC
echo "Description=Start HeatLedger Node" >> $SVC
echo "Wants=network.target" >> $SVC
echo "After=network.target" >> $SVC
echo "[Service]" >> $SVC
echo "Type=forking" >> $SVC
echo "PIDFile='/home/$HEAT_USER/HeatLedger/startHeadLedger.pid'" >> $SVC
echo "User=$HEAT_USER" >> $SVC
echo "WorkingDirectory=$BIN_DIR" >> $SVC
echo "ExecStart=/bin/bash /home/$HEAT_USER/HeatLedger/startHeatLedger.sh" >> $SVC
echo "ExecStartPost=/bin/bash -c '/home/$HEAT_USER/HeatLedger/delayMining.sh &'" >> $SVC
echo "Restart=always" >> $SVC
echo "KillMode=process" >> $SVC
echo "[Install]" >> $SVC
echo "WantedBy=default.target" >> $SVC #Use default target so service runs on boot

#create uninstall script
touch $UNINSTALL
echo "#!/bin/bash" > $UNINSTALL
echo "echo 'stopping heatLedger service'" >> $UNINSTALL
echo "sudo systemctl stop heatLedger.service" >> $UNINSTALL
echo "echo 'disabling heatLedger service'" >> $UNINSTALL
echo "sudo systemctl disable heatLedger.service" >> $UNINSTALL
echo "echo 'removing service file from systemd directory'" >>$UNINSTALL
echo "sudo rm /etc/systemd/system/heatLedger.service" >> $UNINSTALL
echo "echo 'removing HeatLedger directory'" >> $UNINSTALL
echo "sudo rm -r $BASE_DIR" >> $UNINSTALL
echo "echo 'Clean up any orphan processes'" >> $UNINSTALL
echo "screen -ls 'heatLedger' | grep 'heatLedger' | (" >> $UNINSTALL
echo "IFS=\$(printf '\t');" >> $UNINSTALL
echo "sed 's/^\$IFS//' |" >> $UNINSTALL
echo "while read -r name stuff; do" >> $UNINSTALL
echo "echo \"killing screen: \$name\"" >> $UNINSTALL
echo "screen -S '\$name' -X quit" >> $UNINSTALL
echo "done" >> $UNINSTALL
echo ")" >> $UNINSTALL
echo "echo 'Finished uninstalling HeatLedger'" >> $UNINSTALL
sudo chmod +x $UNINSTALL

#create update script
FILESTRING="\`echo \"\$RELEASE_JSON\" | jq -r '.assets[0] | .name'\`"
NUMSTRING="\`echo \"\$RELEASE_JSON\" | jq -r '.tag_name' | cut -c 2- | tr -dc '0-9'\`"
RELEASESTRING="\`echo \"\$RELEASE_FILE\" | rev | cut -c 5- | rev\`"
CUR_NUM=`echo $RELEASE_NUM | tr -dc '0-9'`
OLD_CHAIN="/tmp/oldChain"
touch $UPDATE
echo "#!/bin/bash" > $UPDATE
echo "CURRENT=$CUR_NUM" >> $UPDATE
echo "RELEASE_JSON=\`curl -s https://api.github.com/repos/Heat-Ledger-Ltd/heatledger/releases/latest\`" >> $UPDATE
echo "NUMSTRING=$NUMSTRING" >> $UPDATE
echo "NEWEST=\$NUMSTRING" >> $UPDATE
echo "if [[ \$CURRENT -lt \$NEWEST ]]; then" >> $UPDATE
echo "echo \" upgrading to version \$NEWEST\"" >> $UPDATE
echo "else" >> $UPDATE
echo "echo \"Software is already the latest version\"" >> $UPDATE
echo "exit 0" >> $UPDATE
echo "fi" >> $UPDATE
echo "RELEASE_FILE=$FILESTRING" >> $UPDATE
echo "RELEASE=$RELEASESTRING" >> $UPDATE
echo "echo 'Copying blockchain to tmp'" >> $UPDATE
echo "cp -avr $BIN_DIR/blockchain $OLD_CHAIN" >> $UPDATE
echo "echo 'Copying installer to tmp'" >> $UPDATE 
echo "mv $SCRIPT /tmp/heatScript" >> $UPDATE
echo "echo 'Uninstalling previous version'" >> $UPDATE
echo "/bin/bash $BASE_DIR/uninstall.sh" >> $UPDATE
echo "echo 'Restoring installer'" >> $UPDATE
echo "mv /tmp/heatScript $INSTALL_DIR/installNode.sh" >> $UPDATE
echo "echo 'Installing new version'" >> $UPDATE
echo "/bin/bash $INSTALL_DIR/installNode.sh --accountNumber='$HEAT_ID' --user='$HEAT_USER' --key='$API_KEY' --password='$PASSWORD' --ipAddress='$IP_ADDRESS' --walletSecret='$WALLET_SECRET' --maxPeers='$MAX_PEERS' --hallmark='$HAlLMARK' --forceScan='true' --forceValidate='true'" >> $UPDATE 
echo "echo 'Resotring blockchain'" >> $UPDATE
echo "sudo systemctl stop heatLedger" >> $UPDATE
echo "screen -ls 'heatLedger' | grep 'heatLedger' | (" >> $UPDATE
echo "IFS=\$(printf '\t');" >> $UPDATE
echo "sed 's/^\$IFS//' |" >> $UPDATE
echo "while read -r name stuff; do" >> $UPDATE
echo "echo \"killing screen: \$name\"" >> $UPDATE
echo "screen -S '\$name' -X quit" >> $UPDATE
echo "done" >> $UPDATE
echo ")" >> $UPDATE
echo "mv $OLD_CHAIN $BASE_DIR/$RELEASE/bin/blockchain" >> $UPDATE
echo "echo 'starting node'" >> $UPDATE
echo "sudo systemctl start heatLedger" >> $UPDATE
sudo chmod +x $UPDATE
sudo chmod 700 $UPDATE

#make copy of installer for util scripts usage
cp $SCRIPT $BASE_DIR/installNode.sh

#load service
sudo cp $SVC $SYS_SVC && #copy service to systemd directory
loginctl enable-linger $HEAT_USER  #enable linger so services keep running even if user logs out
sudo systemctl daemon-reload && #reload systemd service daemon
sudo systemctl enable heatLedger.service && #enable the service
sudo systemctl start heatLedger.service #start the service










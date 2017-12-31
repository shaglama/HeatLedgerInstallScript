#!/bin/bash
#HEAT Ledger Bash Install Script for Ubuntu
#Randy Hoggard
#2017
 
#----------Vars----------------------------------------------------------------
RELEASE_NUM="2.4.0"
RELEASE="heatledger-$RELEASE_NUM"
RELEASE_FILE="$RELEASE.zip"
RELEASE_URL="https://github.com/Heat-Ledger-Ltd/heatledger/releases/download/v$RELEASE_NUM/$RELEASE_FILE"

HEAT_USER=$USER #user to run the node with, defaults to user that runs the script. to set a different user change here or pass in as argument, if user does not exist it will be created
PASSWORD= #password for creating a new user, if new user is created without changing the password here or passing in as argument you will need to set the password yourself after running this script
API_KEY="changeMePlease" #Default api key, please change or pass in as argument
IP_ADDRESS="" #public ip address or host, set here or pass as argument. if no value is set, the script will attempt to obtain it from a public provider (dynDNS)
WALLET_SECRET="" #the secret passphrase for the wallet running the node, set here or pass as argument
HEAT_ID="" #the account id of the wallet running the node, set here or pass in as argument
MAX_PEERS=500 #number of peers node should connect to,set here or pass as argument, defaults to 500
HALLMARK="" #the node hallmark, increases forging profits, set here or pass in as argument, if not set script will attempt to create a new hallmark for the node

CURRENT_DATE=""


#------------Functions---------------------------------------------------------
encodeURIComponent() {
  awk 'BEGIN {while (y++ < 125) z[sprintf("%c", y)] = y
  while (y = substr(ARGV[1], ++j, 1))
  q = y ~ /[[:alnum:]_.!~*\47()-]/ ? q y : q sprintf("%%%02X", z[y])
  print q}' "$1"
}

#----------Program-------------------------------------------------------------
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
	ENCODED=$(encodeURIComponent "$WALLET_SECRET") &&
	WALLET_SECRET="$ENCODED"
else 
	echo "WALLET_SECRET was not set in this script or passed in as an argument. WALLET_SECRET IS REQUIRED. Exiting script."
	exit 1
fi

##GET HALLMARK HERE
if [[ $HALLMARK = *[!\ ]* ]]; then
	#already set
	echo "$HALLMARK"
else 
	CURRENT_DATE=$(date +'%Y-%m-%d') &&
	HALLMARK_URL="https://heatwallet.com:7734/api/v1/tools/hallmark/encode/$IP_ADDRESS/200/$CURRENT_DATE/$WALLET_SECRET"
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


#update repos and packages and install dependencies
sudo apt-get update &&
sudo apt-get install -y default-jdk &&
sudo apt-get install -y unzip &&
sudo apt-get install -y screen &&
sudo apt-get install -y curl &&

#download and extract heatLedger

mkdir $BASE_DIR
cd $BASE_DIR
wget $RELEASE_URL &&
unzip $RELEASE_FILE &&
cd "$VER_DIR" 

#create config file
touch $CONF 
echo "heat.apiKey=$API_KEY" >> $CONF 
echo "heat.myAddress=$IP_ADDRESS" >> $CONF
echo "heat.myPlatform=$HEAT_ID" >> $CONF
echo "heat.maxNumberOfConnectedPublicPeers=$MAX_PEERS" >> $CONF
echo "heat.myHallmark=$HALLMARK" >> $CONF
echo "heat.forceScan=true" >> $CONF
echo "heat.forceValidate=true" >> $CONF
echo "#heat.startForging=$WALLET_SECRET" >> $CONF

echo "Configuration written: " 
cat $CONF

#create start script
touch $STRT
echo "#!/bin/bash" >> $STRT
echo "echo 'Starting node'" >>$STRT
echo "echo 'to attach to node : in terminal type  	screen -s heatLedger'" >> $STRT
echo "echo 'to detach from node while attached : hold control and press a. press d'" >> $STRT
echo "echo 'to kill node while attached: hold control and press a. press k. press y.'" >> $STRT
echo "screen -dmS heatLedger /bin/bash $BIN &" >> $STRT
echo "screen -list | grep 'heatLedger' |cut -f1 -d'.' | sed 's/W//g' > 'home/$HEAT_USER/HeatLedger/startHeatLedger.pid'">> $STRT
sudo chmod +x $STRT

#create mining start script
touch $STRT_MINING
echo "#!/bin/bash" >> $STRT_MINING
echo "Starting Forging" >> startMining.log
echo date >> startMining.log
echo "curl -k -s http://localhost:7733/api/v1/mining/start/$WALLET_SECRET\?api_key=$API_KEY >> startMining.log" >> $STRT_MINING
sudo chmod +x $STRT_MINING

#create mining delay script
touch $DELY_MINING
echo "#!/bin/bash" >> $DELY_MINING
echo "sleep 1h &&" >> $DELY_MINING 
echo "./startMining.sh" >> $DELY_MINING
sudo chmod +x $DELY_MINING

#create mining info script
touch $MINING_INFO
echo "#!/bin/bash" >> $MINING_INFO
echo "echo 'Mining Info' >> miningInfo.log" >> $MINING_INFO
echo "date >> miningInfo.log" >> $MINING_INFO
echo "curl -k -s http://localhost:7733/api/v1/mining/info/$WALLET_SECRET\?api_key=$API_KEY >> miningInfo.log" >> $MINING_INFO
sudo chmod +x $MINING_INFO

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
echo "[Unit]" >> $SVC
echo "Description=Start HeatLedger Node" >> $SVC
echo "Wants=network.target" >> $SVC
echo "After=network.target" >> $SVC
echo "[Service]" >> $SVC
echo "Type=forking" >> $SVC
echo "PIDFile='/home/$HEAT_USER/HeatLedger/startHeadLedger.pid'" >> $SVC
echo "User=$HEAT_USER" >> $SVC
echo "WorkingDirectory=/home/$HEAT_USER/HeatLedger" >> $SVC
echo "ExecStart=/bin/bash startHeatLedger.sh" >> $SVC
echo "ExecStartPost=/bin/bash -c '/home/$HEAT_USER/HeatLedger/delayMining.sh &'" >> $SVC
echo "Restart=always" >> $SVC
echo "KillMode=process" >> $SVC
echo "[Install]" >> $SVC
echo "WantedBy=multi-user.target" >> $SVC

#create uninstall script
touch $UNINSTALL
echo "#!/bin/bash" >> $UNINSTALL
echo "sudo systemctl stop heatLedger.service" >> $UNINSTALL
echo "sudo systemctl disable heatLedger.service" >> $UNINSTALL
echo "sudo rm /etc/systemd/system/heatLedger.service" >> $UNINSTALL
echo "sudo rm -r $BASE_DIR" >> $UNINSTALL
sudo chmod +x $UNINSTALL

#load service
sudo cp $SVC $SYS_SVC &&
sudo systemctl daemon-reload &&
sudo systemctl enable heatLedger.service &&
sudo systemctl start heatLedger.service
/bin/bash $STRT









Heat Ledger Install Script v 0.1.5 Randy Hoggard January 1, 2018

This script will install the latest Heat Ledger node software on an ubuntu machine, get a hallmark for the node, and start forging. It also creates a helper script for upgrading the node that can currently be run manually. Future releases will enable the script to automatically check for upgrades and apply them. It has been minimally tested on Ubuntu 16.04. It is still in the early stages at this moment and any feedback on compatibility with other version of ubuntu or any problems encountered or any features you think are missing are greatly appreciated. If you'd like to contribute to this project, please feel welcome.

Getting started:

Download installNode.sh from: https://raw.githubusercontent.com/shaglama/HeatLedgerInstallScript/master/installNode.sh

Set execute permission for script: chmod +x installNode.sh

Execute script with required arguments (requires sudo priveleges) examples

./installNode.sh --accountNumber="accountNumberHere" --walletSecret="wallet secret goes here"

./installNode.sh --accountNumber="accountNumberHere" --walletSecret="wallet secret goes here" --key="apiKeyForNodeHere" --user="UserToRunNode" --password="passwordOfUserToRunNode" --hallmark="hallmarkHere" --ipAddress="ipHere" --maxPeers="500" --forceScan="true" --forceValidate="true"

########################################################################################

--accountNumber is the numberic account number for your heat wallet that will be used to run the node --REQUIRED

--walletSecret is the wallet secret for the heat wallet used to run the node --REQUIRED

--key is the api key for accessing functions on the node, a default is used but if you wish you can specify here --OPTIONAL

--user is the user under who the miner will be run. If you do not specify a user, it will default to the user running the script. If you do specify a user, and that user does not exist, the script will create the user.

--passowrd is the password to use for creating a new user. If a new user is created an no password is specified, the user will not be assigned a password and you will have to do it manually. This is not needed if the user already exists.

--hallmark is the hallmark for the node. If not provided, one will be created --OPTIONAL

--ipAddress is the public ip address of the node. If not provided, the script will attempt to obatain it automatically --OPTIONAL

--maxPeers is the max number of peers the node should connect to. If not provided, defaults to 500. --OPTIONAL

--forceScan if set to true will configure the node to rescan the blockchain, defaults to false --OPTIONAL

--forceValidate if set to true will configure the node to revalidate the transactions on the chain, defaults to false --OPTIONAL

########################################################################################

Example: ./installNode.sh --accountNumber="18204334369979641558" --walletSecret="THIS IS NOT A REAL WALLET SECRET"

To view the output of the node: screen -s heatLedger -x

To detach from screen session: hold ctrl and press a press d

To kill screen session hold ctrl and press a press k press y

The script will download the latest software, setup your config file, create a service to launch and monitor the node, and start the node in a screen session so it is easy to view from anywhere and you don't have to leave a terminal running.It will also issue the command to the node to start forging after the node is up. The script will also create several helper scripts in the same folder : 

uninstall.sh -- removes all changes made by the script

update.sh -- checks for latest release, and upgrades if needed

miningInfo -- polls node for mining info and writes it to miningInfo.log

startMining -- issues the command to start mining to the node, the script is called automatically after 1 hour of node starting, no need to use this unless forging fails to start after one hour or you wish to start earlier

startHeatLedger -- starts the node, is called automatically by the service that monitors the node, no need to use this unless service is not working properly

delayMining -- a helper script used by the service to start mining after a delay. No need to use this. 


This script started as a personal project to enable me to quickly setup nodes on vms. After I saw how much time it saved me I figured maybe it could help someone else out too. Hope you enjoy it.

Donations welcome and greatly appreciated:

Heat: shaglama@heatwallet.com 18204334369979641558

Bitcoin: 15D9TLNu6FFoLiTJGbdMBpT6TETMsPc2xT

Litecoin: LfXgenZQC81sQ1kc3G5JwGCdBb8DLVY6LU

Monero: 4JUdGzvrMFDWrUUwY3toJATSeNwjn54LkCnKBPRzDuhzi5vSepHfUckJNxRL2gjkNrSqtCoRUrEDAgRwsQvVCjZbRzRNy6LdJDpKnSvgsb

Dash: XbpAUN6vqPb4yrfNMCJzkdQfDTGtB4qUNA

 
 

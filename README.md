Heat Ledger Install Script
v 0.1.5
Randy Hoggard
January 1, 2018

This script will install the latest Heat Ledger node software on an ubuntu machine, get a hallmark for the node, and start forging. It has been minimally tested on Ubuntu 16.04. It is still in the early stages at this moment and any feedback on compatibility with other version of ubuntu or any problems encountered or any features you think are missing are greatly appreciated. If you'd like to contribute to this project, please feel welcome. 

Getting started:

Download installNode.sh from:
  https://raw.githubusercontent.com/shaglama/HeatLedgerInstallScript/master/installNode.sh

Set execute permission for script:
  chmod +x installNode.sh

Execute script with required arguments (requires sudo priveleges)

  ./installNode.sh --accountNumber="accountNumberHere" --walletSecret="wallet secret goes here"
  ./installNode.sh --accountNumber="accountNumberHere" --walletSecret="wallet secret goes here" --key="apiKeyForNodeHere" --user=UserToRunNode --password="passwordOfUserToRunNode"
  
 accountNumber is the numberic account number for your heat wallet that will be used to run the node --REQUIRED
 
 walletSecret is the wallet secret for the heat wallet used to run the node --REQUIRED
 
 key is the api key for accessing functions on the node, a default is used but if you wish you can specify here --OPTIONAL
 
 user is the user under who the miner will be run. If you do not specify a user, it will default to the user running the script. If you do specify a user, and that user does not exist, the script will create the user. 
 
 passowrd is the password to use for creating a new user. If a new user is created an no password is specified, the user will not be assigned a password and you will have to do it manually. This is not needed if the user already exists. 
 
 Example:
    ./installNode.sh --accountNumber="18204334369979641558" --walletSecret="THIS IS NOT A REAL WALLET SECRET"
 
 To view the output of the node:
 screen -s heatLedger -x
 
 To detach from screen session:
 hold ctrl and press a
 press d
 
 To kill screen session
 hold ctrl and press a
 press k
 press y
 
 
 The script will download the latest software, setup your config file, create a service to launch and monitor the node, and start the node in a screen session so it is easy to view from anywhere and you don't have to leave a terminal running.It will also issue the command to the node to start forging after the node is up. The script will also create several helper scripts in the same folder. The most important one to know about is uninstall.sh. This script will remove all changes made by the install script.
 usage
 
 ./uninstall.sh
 
 
 This script started as a personal project to enable me to quickly setup nodes on vms. After I saw how much time it saved me I figured maybe it could help someone else out too. Hope you enjoy it. 
 
 Donations welcome and greatly appreciated:
 
 Heat: shaglama@heatwallet.com 18204334369979641558
 
 Bitcoin: 15D9TLNu6FFoLiTJGbdMBpT6TETMsPc2xT
 
 Litecoin: LfXgenZQC81sQ1kc3G5JwGCdBb8DLVY6LU
 
 Monero: 4JUdGzvrMFDWrUUwY3toJATSeNwjn54LkCnKBPRzDuhzi5vSepHfUckJNxRL2gjkNrSqtCoRUrEDAgRwsQvVCjZbRzRNy6LdJDpKnSvgsb
 
 Dash: XbpAUN6vqPb4yrfNMCJzkdQfDTGtB4qUNA
 
 

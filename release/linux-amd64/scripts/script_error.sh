#!/bin/bash

echo
echo " ____    _____      _      ____    _____           _____   ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|         | ____| |___ \  | ____|"
echo "\___ \    | |     / _ \   | |_) |   | |    _____  |  _|     __) | |  _|  "
echo " ___) |   | |    / ___ \  |  _ <    | |   |_____| | |___   / __/  | |___ "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|           |_____| |_____| |_____|"
echo

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}
: ${TIMEOUT:="60"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ca.example.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org1.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org1.example.com:7051
		fi
	elif [ $1 -eq 2 -o $1 -eq 3 ]; then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.org2.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org2.example.com:7051
		fi
	elif [ $1 -eq 2 -o $1 -eq 3 ]; then	
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
		if [ $1 -eq 4 ]; then
			CORE_PEER_ADDRESS=peer0.org3.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org3.example.com:7051
		fi
	fi

	env |grep CORE
}

createChannel() {
	setGlobals 0

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/channel1.tx >&log.txt 
		cat log.txt
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/channel2.tx >&log.txt
		cat log.txt

	else
		peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/channel1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		cat log.txt
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/channel2.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		cat log.txt
	fi
	res=$?
	
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

updateAnchorPeers() {
        #PEER=$1
        #setGlobals $PEER

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		#peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
		setGlobals 0
		peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/Org1MSPanchors1.tx >&log.txt
    	setGlobals 2
    	peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/Org2MSPanchors1.tx >&log.txt
		setGlobals 0
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/Org1MSPanchors2.tx >&log.txt
		setGlobals 4
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/Org3MSPanchors2.tx >&log.txt
	else
		setGlobals 0
		peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/Org1MSPanchors1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		setGlobals 2
		peer channel create -o orderer.example.com:7050 -c mychannel1 -f ./channel-artifacts/Org2MSPanchors1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		setGlobals 0
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/Org1MSPanchors2.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		setGlobals 4
		peer channel create -o orderer.example.com:7050 -c mychannel2 -f ./channel-artifacts/Org3MSPanchors2.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt

	fi
	res=$?
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	#peer channel join -b $CHANNEL_NAME.block  >&log.txt
	if [ $1 -eq 0 -o $1 -eq 1 ]; then
   	   peer channel join -b mychannel1.block  >&log.txt
   	   peer channel join -b mychannel2.block  >&log.txt
	elif [ $1 -eq 2 -o $1 -eq 3 ]; then
       peer channel join -b mychannel1.block  >&log.txt
	elif [ $1 -eq 4 -o $1 -eq 5 ]; then
   	   peer channel join -b mychannel2.block  >&log.txt
	fi 
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1
	else
		COUNTER=1
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3 4 5; do
		setGlobals $ch
		joinWithRetry $ch
		echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		echo
	done
}

installChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
	echo
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1 2&3..."
updateAnchorPeers
#echo "Updating anchor peers for org2..."
#updateAnchorPeers 2

## Install chaincode on Peer0/Org1 and Peer2/Org2
echo "Installing chaincode on org1/peer0..."
installChaincode 0
echo "Install chaincode on org2/peer2..."
installChaincode 2
echo "Install chaincode on org3/peer4..."
installChaincode 4



echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo

echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

exit 0

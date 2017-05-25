#!/bin/bash +x

#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}
echo $CHANNEL_NAME

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/org1.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
        cd crypto-config/peerOrganizations/org2.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
}

## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
	else
	    echo "Building cryptogen"
	    make -C $FABRIC_ROOT release-all
	fi

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
 	echo $FABRIC_ROOT
 	echo $FABRIC_CFG_PATH
	echo $CRYPTOGEN
	$CRYPTOGEN generate --config=./crypto-config.yaml
	echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {

	CONFIGTXGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release-all
	fi

	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	$CONFIGTXGEN -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel1.tx' ###"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel1 -outputCreateChannelTx ./channel-artifacts/channel1.tx -channelID mychannel1		

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel2.tx' ###"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel2 -outputCreateChannelTx ./channel-artifacts/channel2.tx -channelID mychannel2

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP&Org2MSP for ch1 ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors1.tx -channelID mychannel1 -asOrg Org1MSP
	$CONFIGTXGEN -profile TwoOrgsChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors1.tx -channelID mychannel1 -asOrg Org2MSP

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP&Org3MSP for ch2 ##########"
	echo "#################################################################"
    $CONFIGTXGEN -profile TwoOrgsChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors2.tx -channelID mychannel2 -asOrg Org1MSP
    $CONFIGTXGEN -profile TwoOrgsChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors2.tx -channelID mychannel2 -asOrg Org3MSP



	echo
}

generateCerts
replacePrivateKey
generateChannelArtifacts


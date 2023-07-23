#!/bin/bash

if [[ -e ~/helpers.sh ]]; then
	source ~/helpers.sh
else
	exit 1
fi

clear && cd ~
declare -l nodeid waddress vps ipprivate ippublic response nodedescribe input_status response
declare -i j=0

printf "\n\nDear %s, Welcome to the Nym Mix Node Setup Automation Program, kindly provide
the following details to automatically set up your prospective Nym mix node.\n" "$USER"

input_manager nodeid_input

input_manager waddress_input

input_manager vps_input

input_manager ip_address_input

setup_node_manager

load_service_file

if [[ $vps == "aws" || $vps == "google cloud" ]]; then
	if [[ $nodeid && $waddress && $ipprivate && $ippublic ]]; then
		./nym-mixnode init --id "$nodeid" --host "$ipprivate" --announce-host "$ippublic" --wallet-address "$waddress" > node_info 2>&1
	fi
elif [[ $vps == others ]]; then
	./nym-mixnode init --id "$nodeid" --host $(curl ifconfig.me) --wallet-address "$waddress" > node_info 2>&1
fi

input_manager nodedescribe_input

if [[ $nodedescribe == "yes" ]]; then
	printf "\nKindly provide the details requested by the following prompts to describe your Nym mix node."
	./nym-mixnode describe --id "$nodeid"
fi

ufw_config

if [[ -e nym-mixnode.service ]]; then
	sudo sed -i "s/noderef/$nodeid/" nym-mixnode.service
	sudo sed -i "s/persona/$USER/" nym-mixnode.service
	sudo mv nym-mixnode.service /etc/systemd/system/
	sudo systemctl enable nym-mixnode.service >> ~/node_manager/logfile.txt 2>&1
	sudo service nym-mixnode start
else
	printf "\n'nym-mixnode.service' file does not exist.\n"
	exit 1
fi

printf "\nCongratulations %s! You did it! \nYou've just successfully created your Nym mix node." "$USER"

printf "\n\nYou can now signin to your Nym wallet and bond your Nym mix node using the details"
printf "\ngenerated by this script and stored in the file 'node_info' found inside the"
printf "\nfolder 'node_manager' present in your home directory.\n"

input_manager response_input

if [[ $response == "yes" ]]; then
	printf "\nNB: To close the live session and go back to your terminal prompt, simply type"
	printf "\n    (CTRL c) on your keyboard.\n\n\n"
	journalctl -f -u nym-mixnode.service
elif [[ $response == "no" ]]; then
	printf "\nThat's okay, you might decide to see it later.\n\n\n"
fi


#!/bin/bash
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $DIR
touch ${DIR}/dummy

clean_all () {
	echo -n "" > ${DIR}/dummy
}
trap clean_all exit

choice () {
	local PS3="$1"
	local oIFS=$IFS
	local IFS=$'\t'
	local s=($2)
	local resp
	select resp in ${s[@]};do 
		if [[ "$resp" != "" ]]; then 
			break
		fi
	done
	IFS=$oIFS
	echo $resp
}

menu () {
	resp=$(choice "Choose: " "Write a message	Read a message	Display your public key	Create key pair	Exit")
	if [[ "$resp" == "Write a message" ]]; then
		write_msg
	fi 
	if [[ "$resp" == "Read a message" ]]; then
		read_msg
	fi 
	if [[ "$resp" == "Display your public key" ]]; then
		show_key
	fi
	if [[ "$resp" == "Create key pair" ]]; then
		config
	fi
	if [[ "$resp" == "Exit" ]]; then
		toExit=1
	fi
}

write_msg () {
	dests=$(find ./contacts -name "*.pem"|tr "\n" "\t")
	pub_key_pem=$(choice "Whom: " "$dests")
	read -p "Type the message: " msg
	if [[ "$resp" != "" ]]; then 
		resp=$(openssl rsautl -encrypt -pubin -inkey $pub_key_pem 2>/dev/null <<< "$msg" | base64)
		echo Your encrypted and encoded message:
		echo $resp
		echo
		read -sn1
	fi
}


read_msg () {
	echo
	if [[ -f shhh.private.pem ]]; then
		read -p "Type the encrypted message: " encodedMsg
		sed -r "s/ //g" <<<"${encodedMsg}" | base64 -d | openssl rsautl -decrypt -inkey shhh.private.pem 2>/dev/null
	else
		echo "Your keys are not present. Aborting."
	fi
}


show_key () {
	if [[ -f "contacts/myself.pem" ]]; then
		cat contacts/myself.pem
		echo
		echo Press any key to continue
		read -sn1
	else
		echo "Your key is not present"
	fi
}


config () {
	read -sn1 -p "Your new keys are about to be created. Press C to continue or any other key to cancel" ans
	echo
	if [[ "${ans^^}" == "C" ]]; then
		if [[ -f shhh.private.pem ]]; then
			echo "This action will overwite your personal keys."
			read -n1 -p "Are you sure you want to continue? (y/N): " ans
		fi
		if [[ "${ans^^}" == "Y" || ! -f shhh.private.pem ]]; then
			echo Creating private key
			openssl genpkey -algorithm RSA -out shhh.private.pem -aes256 -pkeyopt rsa_keygen_bits:16386
			echo Creating public key
			openssl rsa -in shhh.private.pem -pubout -out ./contacts/myself.pem
		fi
	fi
}

toExit=0
while [[ "$toExit" == "0" ]]; do
	menu
done


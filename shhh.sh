#!/bin/bash

#requisites:
if [[ "$1" == "-t" ]]; then
	ENV="terminal"
	req='openssl'
else
	ENV="gtk"
	req='openssl zenity'
fi

for r in $req; do
	which $r 2>/dev/null 1>&2
	if [[ "$?" != "0" ]]; then
		echo "$r not found. Aborting."
		exit 1
	fi
done



#starts
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $DIR

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
	options=(
		"Write a message and encrypt it with another person's Public Key"
		"Read a message encrypted with my Public key"
		"Write a message and sign it with my Private key"
		"Read a signed message with another person's Public key"
		"Display your public key"
		"Create key pair"
		"Exit"
	)
	if [[ "$ENV" == "gtk" ]]; then
		resp=$(zenity --title="SHHH" --list --width=700 --height=350 --column=Menu \
			"${options[0]}" "${options[1]}" "${options[2]}" "${options[3]}" "${options[4]}" "${options[5]}" "${options[6]}")
	else
		resp=$(choice "Choose: " "${options[0]}	${options[1]}	${options[2]}	${options[3]}	${options[4]}	${options[5]}	${options[6]}")
	fi
	if [[ "$resp" == "${options[0]}" ]]; then
		write_msg
	fi 
	if [[ "$resp" == "${options[1]}" ]]; then
		read_msg
	fi 
	if [[ "$resp" == "${options[2]}" ]]; then
		sign_msg
	fi 
	if [[ "$resp" == "${options[3]}" ]]; then
		verify_msg
	fi 
	if [[ "$resp" == "${options[4]}" ]]; then
		show_key
	fi
	if [[ "$resp" == "${options[5]}" ]]; then
		config
	fi
	if [[ "$resp" == "${options[6]}" ]]; then
		toExit=1
	fi
}

write_msg () {
	if [[ "$ENV" == "gtk" ]]; then
		pub_key_pem=$(find ./contacts -name "*.pem"|zenity --title="SHHH" --list --text="Whom?" --width=700 --height=350 --column="Available public keys")
		msg=$(zenity --width=500 --height=500 --title='SHHH' --text-info --editable --text='Type the message')
	else
		dests=$(find ./contacts -name "*.pem"|tr "\n" "\t")
		pub_key_pem=$(choice "Whom: " "$dests") # CLI
		read -p "Type the message: " msg
	fi

	if [[ "$resp" != "" ]]; then 
		local password=$(openssl rand 256|tr -d '\000\a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v\w\x\y\z"') # XXX do I need |base64?
		# echo creando pass: $password $?
		local encriptedMsg=$(openssl enc -e -chacha20 -pbkdf2 -pass "pass:${password}" <<<${msg}|base64 -w0)
		# echo encriptando msg: $encriptedMsg $?
		# echo decrypt test: base64 -d <<< $encriptedMsg | openssl enc -d -chacha20 -pbkdf2 -pass "pass:${password}"
		local encryptedPassword=$(openssl pkeyutl -encrypt -pubin -inkey $pub_key_pem <<< "$password"|base64 -w0)
		#echo enciptando pass: $?
		if [[ "$ENV" == "gtk" ]]; then
			zenity --width=500 --height=500 --title='SHHH' --text-info --text='The encrypted message is'<<<${encryptedPassword}:${encriptedMsg}
		else
			echo "The encripted message is:"
			echo "${encryptedPassword}:${encriptedMsg}"
		fi
	fi
}



read_msg () {
	if [[ -f shhh.private.pem ]]; then
		if [[ "$ENV" == "gtk" ]]; then
			fullMsg=$(zenity --width=500 --height=500 --title='SHHH' --text-info --editable --text='Type the encrypted message')
		else
			echo
			read -p "Type the encrypted message: " fullMsg
		fi
		encodedPassword=$(grep -Eo "^[^:]+" <<<$fullMsg)
		encodedMsg=$(sed -E "s/^[^:]+://g" <<< $fullMsg)
		if [[ "$ENV" == "gtk" ]]; then
			passPhrase=$(zenity --password --title="SSH: Type your passphrase" --width=600)
			password=$(base64 -d <<< $encodedPassword | openssl pkeyutl -decrypt -passin "pass:$passPhrase" -inkey shhh.private.pem )
		else
			password=$(base64 -d <<< $encodedPassword | openssl pkeyutl -decrypt -inkey shhh.private.pem )
		fi
		msg=$(base64 -d <<< $encodedMsg | openssl enc -d -chacha20 -pbkdf2 -pass "pass:${password}")
		if [[ "$ENV" == "gtk" ]]; then
			zenity --text-info --width=500 --height=500 --title='SHHH'<<<$msg
		else
			echo
			echo Your message is:
			echo $msg
			echo
		fi
	else
		local error='Your keys are not present. Aborting.'
		if [[ "$ENV" == "gtk" ]]; then
			zenity --width=500 --height=500 --title='SHHH' --info --text="$error"
		else
			echo $error
		fi
	fi
}

sign_msg () {
	if [[ -f shhh.private.pem ]]; then
		if [[ "$ENV" == "gtk" ]]; then
			local msg=$(zenity --width=500 --height=500 --title='SHHH' --text-info --editable --text='Type the message to sign')
			local passPhrase=$(zenity --password --title="SSH: Type your passphrase" --width=600)
			local signedMsg=$(openssl pkeyutl -sign -inkey shhh.private.pem -passin "pass:${passPhrase}"<<<${msg}|base64 -w0)
			zenity --text-info --width=500 --height=500 --title='SHHH: Type the message to sign'<<<$signedMsg
		else
			echo
			read -p "Type the message to sign: " msg
			local signedMsg=$(openssl pkeyutl -sign -inkey shhh.private.pem <<<${msg}|base64 -w0)
			echo Your signed message is:
			echo $signedMsg
			echo
		fi
	else
		echo "Your keys are not present. Aborting."
	fi
}



verify_msg () {
	if [[ "$ENV" == "gtk" ]]; then
		pub_key_pem=$(find ./contacts -name "*.pem"|zenity --title="SHHH" --list --text="From whom is this message?" --width=700 --height=350 --column="Available public keys")
		msg=$(zenity --width=500 --height=500 --title='SHHH' --text-info --editable --text='Type the message')
		recoveredMsg=$(base64 -d <<< $msg | openssl pkeyutl -verifyrecover -pubin -inkey $pub_key_pem)
		zenity --text-info --width=500 --height=500 --title='SHHH: Type the message'<<<$recoveredMsg
	else
		dests=$(find ./contacts -name "*.pem"|tr "\n" "\t")
		pub_key_pem=$(choice "From whom is this message?: " "$dests")
		read -p "Type the message: " msg
		#if [[ "$resp" != "" ]]; then # XXX verificar si neceisto esto
			base64 -d <<< $msg | openssl pkeyutl -verifyrecover -pubin -inkey $pub_key_pem
		#fi
	fi
}



show_key () {
	if [[ -f "contacts/myself.pem" ]]; then
		if [[ "$ENV" == "gtk" ]]; then
			cat contacts/myself.pem | zenity --text-info --width=800 --height=600 --title='SHHH: Your public key (share it)'
		else
			cat contacts/myself.pem
			echo
			echo Press any key to continue
			read -sn1
		fi
	else
		echo "Your key is not present"
	fi
}


config () {
	if [[ "$ENV" == "gtk" ]]; then
		zenity --question --text="Your new keys are about to be created. \nThis action will overwrite any previous key created"
		if [[ "$?" == "0" ]]; then
			keysize=$(zenity --scale --value=16384 --min-value=1024 --max-value=16384 --step=1024 --width=600 --title="Key size" --text="the bigger the slower to create, but better")
			passPhrase=$(zenity --password --title="SSH: Type your passphrase to protext your key" --width=600)
			openssl genpkey -algorithm RSA -out shhh.privada.pem -aes256 -pass "pass:${passPhrase}" -pkeyopt rsa_keygen_bits:$keysize | \
				zenity --progress --pulsate --no-cancel --text="Creating your key"
			openssl rsa -passin "pass:${passPhrase}" -in shhh.private.pem -pubout -out ./contacts/myself.pem | \
				zenity --progress --pulsate --no-cancel --text="Extracting your public key"
			zenity --info --text="Your new key has been created"
		fi
	else
		read -sn1 -p "Your new keys are about to be created. Press C to continue or any other key to cancel" ans
		echo
		if [[ "${ans^^}" == "C" ]]; then
			if [[ -f shhh.private.pem ]]; then
				echo "This action will overwite your personal keys."
				read -n1 -p "Are you sure you want to continue? (y/N): " ans
				echo
			fi
			if [[ "${ans^^}" == "Y" || ! -f shhh.private.pem ]]; then
				echo Creating private key
				openssl genpkey -algorithm RSA -out shhh.private.pem -aes256 -pkeyopt rsa_keygen_bits:16384
				echo Creating public key
				openssl rsa -in shhh.private.pem -pubout -out ./contacts/myself.pem
			fi
		fi
	fi
}

toExit=0
while [[ "$toExit" == "0" ]]; do
	menu
done


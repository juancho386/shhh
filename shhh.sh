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
	options=(
		"Write a message and encrypt it with another person's Public Key"
		"Read a message encrypted with my Public key"
		"Write a message and sign it with my Private key"
		"Read a signed message with another person's Public key"
		"Display your public key"
		"Create key pair"
		"Exit"
	)
	resp=$(choice "Choose: " "${options[0]}	${options[1]}	${options[2]}	${options[3]}	${options[4]}	${options[5]}	${options[6]}")
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
	dests=$(find ./contacts -name "*.pem"|tr "\n" "\t")
	pub_key_pem=$(choice "Whom: " "$dests")
	read -p "Type the message: " msg
	if [[ "$resp" != "" ]]; then 
		local password=$(openssl rand 256|tr -d '\000\a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v\w\x\y\z"') # XXX do I need |base64?
		# echo creando pass: $password $?
		local encriptedMsg=$(openssl enc -e -chacha20 -pbkdf2 -pass "pass:${password}" <<<${msg}|base64 -w0)
		# echo encriptando msg: $encriptedMsg $?
		# echo decrypt test: base64 -d <<< $encriptedMsg | openssl enc -d -chacha20 -pbkdf2 -pass "pass:${password}"
		local encryptedPassword=$(openssl pkeyutl -encrypt -pubin -inkey $pub_key_pem <<< "$password"|base64 -w0)
		#echo enciptando pass: $?
		echo ${encryptedPassword}:${encriptedMsg}
	fi
}



read_msg () {
	echo
	if [[ -f shhh.private.pem ]]; then
		read -p "Type the encrypted message: " fullMsg
		encodedPassword=$(grep -Eo "^[^:]+" <<<$fullMsg)
		encodedMsg=$(sed -E "s/^[^:]+://g" <<< $fullMsg)
		password=$(base64 -d <<< $encodedPassword | openssl pkeyutl -decrypt -inkey shhh.private.pem )
		msg=$(base64 -d <<< $encodedMsg | openssl enc -d -chacha20 -pbkdf2 -pass "pass:${password}")
		echo $msg
	else
		echo "Your keys are not present. Aborting."
	fi
}

sign_msg () {
	echo not implemented yet
}
verify_msg () {
	echo not implemented yet
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
			echo
		fi
		if [[ "${ans^^}" == "Y" || ! -f shhh.private.pem ]]; then
			echo Creating private key
			openssl genpkey -algorithm RSA -out shhh.private.pem -aes256 -pkeyopt rsa_keygen_bits:16384
			echo Creating public key
			openssl rsa -in shhh.private.pem -pubout -out ./contacts/myself.pem
		fi
	fi
}

toExit=0
while [[ "$toExit" == "0" ]]; do
	menu
done


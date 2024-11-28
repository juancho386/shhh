#!/bin/bash
BACKTITLE="SHHH! 🤫"
#screen=$(dialog --print-maxsize 2>&1 1>/dev/null) # It can not get the screen size from inside the subshell

dialog --print-maxsize 2>dummy
WIDTH=$(grep -Eo "[0-9]{1,}$" <dummy )
HEIGHT=$( grep -Eo ": [0-9]*" <dummy | cut -d\  -f2)
WIDTH=$((WIDTH-7))
HEIGHT=$((HEIGHT-4))
iHEIGHT=$((HEIGHT-4))

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
clean_all () {
	echo -n "" > dummy
}
trap clean_all exit

resp=""
ret=0
menu () {
	resp=$(dialog --backtitle "$BACKTITLE" --output-fd 1 --no-items \
		--extra-button --extra-label Configuration --cancel-label Exit \
		--menu "Menu" $iHEIGHT $WIDTH $HEIGHT "Write a message" "Read a message" "Show your public key"\
	)
	ret=$?
	if [[ "$resp" == "Write a message" ]]; then
		write_msg
	fi 
	if [[ "$resp" == "Read a message" ]]; then
		read_msg
	fi 
	if [[ "$resp" == "Show your public key" ]]; then
		show_key
	fi 
}

write_msg () {
	# primero tiene que elegir el destinatario para obtener la public key correcta
	pub_key_pem="shhh.public.pem"

	#despues escribe el texto y encripta:
	resp=$(dialog --backtitle "$BACKTITLE" --output-fd 1 \
		--cancel-label Back --ok-label "Encript" \
		--editbox dummy 15 $WIDTH \
	)
	if [[ "$resp" != "" ]]; then 
		resp=$(openssl rsautl -encrypt -pubin -inkey $pub_key_pem 2>/dev/null <<< "$resp" | base64)
		#--inputbox "Write your message to be encoded" 8 $WIDTH
		clear
		echo Your message encoded:
		echo
		echo $resp
		echo
		echo Press any key to continue...
		read -sn1
		ret=$?
	fi
}


read_msg () {
	clave="fafafa"
	# Segmentation fault on long lines
	#resp=$(dialog --backtitle "$BACKTITLE" --output-fd 1 \
	#	--cancel-label Back --ok-label "Decrypt" --max-input 100000 \
	#	--editbox 12 40 12 2>&1 \
	#)
	# and inputbox has a limit on 2023 chars. Hence:
	clear
	read -p "The message: " resp
	sed -r "s/ //g" <<<"${resp}" | base64 -d >dummy

	resp=$(openssl rsautl -decrypt -inkey shhh.private.pem -in dummy -passin pass:${clave} 2>/dev/null)
	resp=$(dialog --backtitle "$BACKTITLE" --output-fd 1 \
		--msgbox "$resp" 15 $WIDTH \
	)
	ret=0
}


show_key () {
	clear
	cat shhh.public.pem
	echo
	echo Press any key to continue
	read -sn1
}


config () {
	resp=$(dialog --backtitle "$BACKTITLE" --output-fd 1\
		--menu "Menu" 12 $WIDTH 12 "Create a new keypair"\
	)
	ret=$?
}

menu

while [[ "$ret" != "1" ]]; do
	# echo $ret
	# read -sn1
	if [[ "$ret" == "3" ]]; then
		config
	fi
	if [[ "$ret" == "0" ]]; then
		menu
	fi
done


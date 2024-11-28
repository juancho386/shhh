# SHHH
Hibrid encryption implementation using OpenSSL CLI on Bash. (GPG-wanna-be)

It is a simple bash based tool to encrypt and hash messages using Chacha20 and RSA public and private keys.

## Features
- It uses Bash so it runs in any (?) linux machine.
- ./shhs.sh has a menu. Use it
- It is based on OpenSSL CLI.
- Check the [manual](./manual.md) if you are unsure.

### Principles
- Creates keys using: `openssl genpkey -algorithm RSA -out private.pem -aes256 -pkeyopt rsa_keygen_bits:16386`
- Extracts its public key using: `openssl rsa -in private.pem -pubout -out public.pem`
- To encrypt a message:
  - Generate a secure password: `openssl rand 256`
  - Encrypt the message using that password over Chacha20: `echo $message | openssl enc -e chacha20 -pass "pass:$password"`
  - Encrypt the password using RSA public key: `echo $password|openssl rsautl -encrypt -pubin -inkey $pubkeypem`
  - Output the result as `$encryptedPassword:$message`
- To decrypt a message:
  - Get message and split by ":" to get the password and the real message
  - Decrypt the password using the private key: `echo $encPassword|openssl rsautl -decrypt -inkey shhh.private.pem`
  - Decrypt the message using it: `echo $encMsg | openssl enc -d -chacha20 -pbkdf2 -pass "pass:$password"`


### Development stages
##### Stage 1
At the first stage, you can create your keys, share your public key with your friends and when they send you a short RSA encripted message you can copy and paste it to be decrypted.
##### Stage 2
The keys can be up to 16kb long to receive messages of up to 2kb long
##### Stage 3 (current)
Now the message is encrypted using Chacha20 with a self generated key which is encrypted using the receptor's public key. So the messages can be of any length.
##### Stage 4
Make it prettier using Dialog. Note: Not finished because in my current Linux distribution, dialog has a bug on --editbox that doesn't allow text bigger than ~2k long

### More things to do:
- The chacha20 password length is 256 chars. The static number might become data for hackers to discover the actual password. Solution: Make the password length variable
- Opt the user to output a file instead o text to be copied and pasted
- Implement zenity


# SHHH Manual
SHHH is a tool to create and read encrypted messages.

In GTK mode, run 
```bash
./shhh.sh
```

You will see the following interface
![menu](./assets/menu.jpg)

> [!NOTE]
> You can run the pure terminal using
> ```bash
> ./shhh.sh -t
> ```
> More on that: [here](#terminal)

## Start
First you need to create your own keys. Select *Create key pair*. SHHH will ask you for confirmation, the size and a passphrase:
- The size of the key must be a number power of 2. 16384 is the maximum size and is the recommended value. It will take longer to be created but the security will be much better.
- The passphrase is assigned internally to your private key to ensure that no one but you can use it. Not even if they have the private key file. To activate the features of encryption and decryption using your private key, you will need to type it again every time.

The creation process could take few minutes. Be patiente. Once it is created, you will get 2 files: 
- `./shhh.privada.pem` which is your private key, and
- `./contacts/myself.pem` which is the public part of your private key (AKA: public key)

Use the *Display your public key* item from the menu to copy it and paste it anywhere.

> [!IMPORTANT]
> Distribute your *public key* (the `myself.pem` file) anywhere. Between friends, but also with people that are not necesarily friends but might want to communicate with you in a secure way.

> [!WARNING]
> Do NOT distribute your private key. As its name says, it is PRIVATE. It is yours and nobody elses. If somebody elses gets it, only the passphrase will be the barrer for that person to impersonate you.

Once you have crystal clear the concepts and your keys are created, you can send messages to others by two ways:
- Encrypt messages: To send a message to a specific person. Nobody else can read it.
- Sign messages: To send a message that other people needs to know that comes specifically from you

## Encrypt messages
An encrypted message can be read only be the person who is intended to. Therefore to write it you need that person's public key. Select *Write a message and encrypt it with another person's Public key* from the menu to do so.

Then you will have a list of available public keys located in your ./contacts directory. Select the destinatary and press OK.

In the next step you can write the message. It can be as long as you want (or as long as your computer can handle), and once you finish, press OK. Note that you can encrypt messages for yourself using the myself.pem key. This can be usefull to store passwords or also for private key files testing purposes.

Once the message is encrypted, you will see it displayed. You can press CTRL+a to select the entire text, and then CTRL+c to copy it. Now you can paste it in any message system like Telegram or email.

## Decrypt messages
Select 'Read a message encrypted with my Public key' from the menu and paste the encrypted message in the next dialog box.

> [!TIP]
> If you are using the keyboard, and you want to move to the OK button, know that TAB will write a tab space in the text. Use CTRL+tab to navigate in that dialog.

Then you can type your personal passphrase. The next dialog will show you the original decrypted message.

## Sign messages
TODO
## Verify signed messages
TODO
## Terminal
TODO
## Technical concepts
TODO


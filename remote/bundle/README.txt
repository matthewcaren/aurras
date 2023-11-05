====== how to use =======

1. Get an MIT certificate. Even if you already have one "installed",
	you'll probably want a new copy. Open a browser and head to
	https://ist.mit.edu/certificates, and click 'get your MIT
	personal certificate' + follow the instructions onscreen.
	At some point you'll select an import password (remember this),
	and then you'll get a .p12 folder you can download to your machine.

2. Head back to https://ist.mit.edu/certificates, and get a copy of
	the MIT certificate authority.

3. Prepare the .p12 file for use with bundle. In a command prompt, navigate
	to the root of this repository and run the following:

	./scripts/splitp12.sh /path/to/your/p12/file importpassword

	Provided you get your input password right, you'll wind up with
	a .pem and .key file in your working directory. These are your
	public and private keys, respectively - protect the private key
	and don't share it with anyone! Enter the names of the public/private
	key files into config.py, as client_cert and client_key respectively.

4. Prepare the MIT CA for use with bundle. In the same directory you were in
	for step 3, run:

	./scripts/decodecrt.sh /path/to/your/mitca.crt

	You'll wind up with mitca.pem in your working directory. Make sure this
	is entered as client_ca in the config.py

5. You're ready to go!

import socket
import ssl

def _certificates_to_ascii(calist):
	result = ""
	for path in calist:
		if path is None: continue
		with open(path, 'r') as f:
			result += f.read() + "\n"
	return result

class Connection:
	def _setup_ssl_context(self):
		self.context = ssl.create_default_context()

		if self.calist is not None:
			catext = _certificates_to_ascii(self.calist)
			if catext != "":
				self.context.load_verify_locations(cadata=catext)

		if self.certfile is not None and self.keyfile is not None:
			self.context.load_cert_chain(self.certfile, self.keyfile)

		# lower security level so the MIT CA can be used
		# what idiots are running IS&T anyway
		self.context.set_ciphers("RSA@SECLEVEL=1")

	def __init__(self, calist, certfile, keyfile):
		self.calist = calist
		self.certfile = certfile
		self.keyfile = keyfile

		self.context = self.conn = None

	def connect(self, hostname, port):
		if self.context is None: self._setup_ssl_context()

		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.conn = self.context.wrap_socket(s, server_hostname=hostname)
		self.conn.connect((hostname, port))
		self.conn.do_handshake()

	def close(self):
		if self.conn is not None:
			self.conn.close()
			self.conn = None

	def write_bytes(self, bstring):
		self.conn.sendall(bstring)

	def read_bytes(self, mtu=1048576):
		return self.conn.recv(mtu)


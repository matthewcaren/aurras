#!/usr/bin/env python3

from bundleshim import *
from conf import *
from connection import *
from message import *
from timeout import *

import signal
import sys
import threading

class ServerException(Exception): pass

def usage(err=None):
	if err is not None: print(err)
	print("usage: {sys.argv[0]} build.py files...")
	sys.exit(2)

try:
	script = sys.argv[1]
	if script != "build.py": usage("build script must be named build.py!")
	filelist = sys.argv[2:]
except IndexError: usage()

filelist = sys.argv[1:]

def cleanup(signo, frame):
	clean_bundle()
	print(f"caught signal {signal.Signals(signo).name}, exiting")
	sys.exit(1)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

tobuild = bundle(filelist)
conn = Connection([client_ca], client_cert, client_key)
conn.connect(server_hostname, server_port)

with open(tobuild, 'rb') as f:
	bundlecontent = f.read()

opener = Message(MessageOp.SENDFILE, label=bytes(tobuild, encoding='ascii'), file=bundlecontent)
conn.write_bytes(opener.to_bytes())

conn_lock = threading.Lock()
line_semaphore = threading.Semaphore(0)

def pollinput():
	while True:
		try: line = input()
		except EOFError: break

		line_semaphore.acquire()

		with conn_lock:
			message = Message(MessageOp.SENDLINE, label=bytes(line, encoding='ascii'))
			conn.write_bytes(message.to_bytes())

input_thread = threading.Thread(target=pollinput)
input_thread.daemon = True
input_thread.start()

status = 0

while True:
	try: message = Message.from_conn(conn)
	except ConnectionClosedException: break

	response = None

	if message.opcode() == MessageOp.REQUESTLINE:
		line_semaphore.release()

	elif message.opcode() == MessageOp.SENDLINE:
		print(message.label())
		response = Message(MessageOp.ACK)

	elif message.opcode() == MessageOp.SENDFILE:
		with open(message.label(), 'wb') as f:
			f.write(message.file())

		response = Message(MessageOp.ACK)

	elif message.opcode() == MessageOp.ERROR:
		print(f"ERROR: {message.label()}")
		response = Message(MessageOp.TERMINATE)
		status = 1

	elif message.opcode() == MessageOp.HEARTBEAT:
		response = Message(MessageOp.HEARTBEAT)

	else: raise ValueError(f"BUG: received bad opcode {message.opcode()}")

	if response is not None:
		with conn_lock:
			conn.write_bytes(response.to_bytes())

clean_bundle()
sys.exit(status)

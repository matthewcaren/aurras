from conf import *

import os
import subprocess
import zlib

minimum_archivefile_length = 10

class ArchiveFile:
	def __init__(self, name, uncompressed_size, compressed_content):
		if uncompressed_size > max_file_size:
			raise ValueError(f"{name}: uncompressed file size too large")

		if len(name) > max_name_size:
			raise ValueError(f"file name '{name}' too long")

		self._name = name
		self._uncompressed_size = uncompressed_size
		self._compressed_content = compressed_content

	def name(self): return self._name
	def compressed_content(self): return self._content

	def uncompressed_content(self):
		return zlib.decompress(self._compressed_content, bufsize=self._uncompressed_size)

	@classmethod
	def from_bytes(cls, bytes):
		if len(bytes) < 2:
			raise ValueError("not enough bytes to express name length") 

		namelength = int.from_bytes(bytes[0:2], "big")
		bytes = bytes[2:]

		if namelength > max_name_size:
			raise ValueError("claimed file name size is too big")

		if len(bytes) < namelength:
			raise ValueError("not enough bytes to express file name")

		name = bytes[:namelength].decode(encoding="ascii")
		bytes = bytes[namelength:]

		if len(bytes) < 8:
			raise ValueError("not enough bytes to detail file size")

		uncompressed_size = int.from_bytes(bytes[0:4], "big")
		if uncompressed_size > max_file_size:
			raise ValueError("claimed uncompressed file size too big!")

		compressed_size = int.from_bytes(bytes[4:8], "big")
		bytes = bytes[8:]	

		if len(bytes) < compressed_size:
			raise ValueError("reported compressed size > actual compressed size")

		return cls(name, uncompressed_size, bytes[:compressed_size])

	def serialized_length(self):
		return len(self.to_bytes())

	def to_bytes(self):
		namesize = len(self._name)
		contentsize = len(self._compressed_content)

		benamesize = namesize.to_bytes(2, "big")
		becontentsize = contentsize.to_bytes(4, "big")
		beuncompressedsize = self._uncompressed_size.to_bytes(4, "big")

		name_bytes = bytes(self._name, "ascii")

		total = benamesize + name_bytes
		total += beuncompressedsize + becontentsize
		total += self._compressed_content

		return total

class Archive:
	def _header_to_bytes(self):
		out = self._crc32.to_bytes(4, "big")
		out += len(self._signature).to_bytes(2, "big")
		out += bytes(self._signature, "ascii")

		return out

	def _body_to_bytes(self):
		out = bytes()
		for file in self._filelist:
			out += file.to_bytes()

		return out

	def to_bytes(self):
		return self._header_to_bytes() + self._body_to_bytes()

	def serialized_length(self):
		return len(self.to_bytes())

	def _update_crc32(self):
		target = self._body_to_bytes()
		self._crc32 = zlib.crc32(target)

	def __init__(self, filelist, claimed_crc=None, signature=None):
		self._filelist = filelist
		self._signature = signature

		self._crc32 = None
		self._update_crc32()

		if (claimed_crc is not None and self._crc32 != claimed_crc):
			raise ValueError("incorrect crc claimed")

	def get_file_by_name(self, name):
		for file in self._filelist:
			if file.name() == name: return file

		return None

	def crc32(self): return self._crc32
	def signature(self): return self._signature

	def signature_is_okay(self):
		crcbytes = self._crc32.to_bytes(4, "big")
		crcfile = "/tmp/crc32.bin"
		crcsig = "/tmp/crc32.sig"

		with open(crcfile, "wb") as f:
			f.write(crcbytes)

		with open(crcsig, "w") as f:
			f.write(self._signature)

		completed = subprocess.run(["signify", "-V",
				"-x", crcsig,
				"-p", "/etc/signify/bundled.pub",
				"-m", crcfile],
				stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

		os.unlink(crcfile)
		os.unlink(crcsig)

		return completed.returncode == 0

	def all_filenames(self):
		names = []
		for file in self._filelist:
			names.append(file.name())	

		return names

	@classmethod
	def from_bytes(cls, bytes):
		if len(bytes) < 4:
			raise ValueError("archive not long enough to express crc")

		claimed_crc = int.from_bytes(bytes[0:4], "big")
		bytes = bytes[4:]

		if len(bytes) < 2:
			raise ValueError("archive not long enough to express signature length")

		signaturesize = int.from_bytes(bytes[0:2], "big")
		bytes = bytes[2:]

		if len(bytes) < max_signature_size:
			raise ValueError("archive not long enough to express signature")

		if signaturesize > max_signature_size:
			raise ValueError("claimed signature size is too big!")

		if signaturesize == 0: signature = None
		else: signature = bytes[0:signaturesize].decode(encoding="ascii")

		bytes = bytes[max_signature_size:]

		files = []
		while len(bytes) > 0:
			if len(files) == max_archive_files:
				raise ValueError("too many files in archive")

			newfile = ArchiveFile.from_bytes(bytes)
			files.append(newfile)

			bytes = bytes[newfile.serialized_length():]

		return cls(files, claimed_crc=claimed_crc, signature=signature)

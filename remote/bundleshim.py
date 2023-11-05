import os
import subprocess
import sys

def bundle(filelist):
	fileargs = ""
	for file in filelist: fileargs += f" {file}"

	completed = subprocess.run(f"python3 remote/bundle/bundle.py -csf build.bundle {fileargs}",
		shell=True)

	if completed.returncode == 0: return "build.bundle"
	else: sys.exit(1)

def clean_bundle():
	try: os.remove("build.bundle")
	except FileNotFoundError: pass

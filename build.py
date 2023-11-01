import os
import subprocess

vivado = "/opt/Xilinx/Vivado/2023.1/bin/vivado"

class VivadoBuildError(Exception): pass

if not os.access("build.tcl", os.R_OK):
	raise VivadoBuildError("you should pass a build script for us to run!")

print("starting vivado, please wait...")
proc = subprocess.Popen(f"{vivado} -mode batch -source build.tcl",
	shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

while True:
	line = proc.stdout.readline()
	if not line: break
	else: print(str(line.rstrip(), encoding='ascii'))

proc.wait()

if proc.returncode != 0:
  save("vivado.log")
  raise VivadoBuildError(f"vivado exited with code {proc.returncode}")
else:
  save("vivado.log")

#files to look for:
files = [ "final.bit",
          "post_synth_timing_summary.rpt",
          "post_synth_util.rpt",
          "post_synth_timing.rpt",
          "clock_util.rpt",
          "post_place_util.rpt",
          "post_place_timing_summary.rpt",
          "post_place_timing.rpt",
          "post_route_status.rpt",
          "post_route_timing_summary.rpt",
          "post_route_timing.rpt",
          "post_route_power.rpt",
          "post_imp_drc.rpt",
]

for file in files:
  # look for out.bit, because we've hard coded that for now i guess
  if not os.access(f"obj/{file}", os.R_OK):
	  raise VivadoBuildError(f"vivado exited successfully, but no {file} generated")
  save(f"obj/{file}")
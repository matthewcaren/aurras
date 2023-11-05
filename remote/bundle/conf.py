# Configure me!

client_cert = None
client_key = None
client_ca = None

server_hostname = "fpga3.mit.edu"
server_port = 443

# NO CHANGES REQUIRED BEYOND THIS POINT
#
# these settings match the running
# daemon configuration - in particular,
# max_signature_size matters the most.
#
# the rest of these are don't care material
# from the perspective of this client - the
# assertions throughout this code could be
# deleted and everything would still work ok

max_signature_size = 177
max_file_size = 10485760
max_name_size = 1024
max_archive_files = 100

====== how to use =======

To run a script remotely, ensure it is named build.py. Then, from the directory _above_
this one, run:

`./remote/r.py build.py <input files>`

If you would like to pass any input files to the build script (i.e. that will appear when
'open' is called), add additional arguments to the above as described. Otherwise, don't pass
anything else.

==

The build system overrides a handful of built-in Python functionalities.
You should know about these before you write a test script. The implementation
of each modification can be found in worker/api.py, but is briefly summarized here:

print(): ONLY ACCEPTS STRING ARGUMENTS. Prints to the client machine (e.g. your laptop) rather
than the worker machine's console.

readline(): REPLACES INPUT. Takes no arguments, and returns a string argument read from the
client machine (e.g. your laptop).

save(): Sends a file on the remote machine to your device. All files which are not save()d will
not appear on your machine after the build script has finished running. For instance, if you
are building a Vivado bitstream, you may not want to save 'vivado.log', but you may want to
save 'out.bit' - to do this, simply add `save(out.bit)` to the end of the build script.

Exceptions: Raising an uncaught exception (or calling the API function error(description)
will print an error message to the client machine before terminating the script as normal.



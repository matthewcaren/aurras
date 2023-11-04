import signal

# for now we stub this out!
# why? because windows doesn't support SIGALRM...

class Timeout:
	def __init__(self, timeout): pass
	def cancel(self): pass

print("we will be sorting the entire bee movie script")

with open("bees.txt", 'r') as f:
	script = f.read()

words = [word.lower() for word in script.split()]
words.sort()

with open("output.txt", 'w+') as f:
	for word in words:
		f.write(f"{word}\n")

save("output.txt")

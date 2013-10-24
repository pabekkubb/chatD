DMD = dmd

all:
	$(DMD) -ofclient client.d
	$(DMD) -ofserver server.d


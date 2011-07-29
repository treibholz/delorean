#!/usr/bin/lua

f = io.open("/var/lib/delorean.lastrun","r")
lastBackup = f:read("*line")

ago=os.time()-lastBackup
unit = "s"
warning = ""

if ago > 60 then
	ago = ago / 60
	unit = "m"

	if ago > 60 then
		ago = ago / 60
		unit = "h"
		
		if ago > 24 then
			ago = ago / 24
			unit = "d"

			if ago > 7 then
				ago = ago / 7
				unit = "w"
				warning="Warning: "

			end
		end
	end
end

backupAgo = string.format("%s%i%s", warning, ago ,unit)

print(backupAgo)
	

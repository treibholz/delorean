----------------------------------------
-- Author: Klaus Umbach               --
----------------------------------------

delorean = widget({ type = "imagebox"})
delorean.image = image(awful.util.getdir("config") .. "/delorean-icon.png")

delorean:add_signal("mouse::enter", function() add_delorean() end)
delorean:add_signal("mouse::leave", function() rem_delorean() end)

delorean:buttons(awful.util.table.join(
   awful.button({ }, 1, function()
		rem_delorean()
   end)
    )
)

function rem_delorean() -- {{{
  if deloreanInfo ~= nil then
   naughty.destroy(deloreanInfo)
      deloreanInfo = nil
      offset = 0
  end
end --- }}}

function add_delorean() -- {{{
   rem_delorean()
   deloreanInfo = naughty.notify({
--      text = string.format('<span font_desc="%s">%s</span>', "Droid Sans Mono 8", cal),
      text = getDeloreanInfo(),
      timeout = 0, hover_timeout = 0.5,
--      width = 170,
      title = "Delorean Info",
  })
end -- }}}

function getDeloreanInfo() -- {{{
	if io.open("/var/run/delorean.pid") then

		backupAgo = "Backup is currently running..."
		
	else
		f = io.open("/var/lib/delorean.lastrun","r")
		lastBackup = f:read("*line")

		ago=os.time()-lastBackup
		warning = ""

		if ago > 60 then
			minor = ago % 60
			ago = ago / 60
			message = string.format("%im %is", ago, minor)
			if ago > 60 then
				minor = ago % 60
			   ago = ago / 60
				message = string.format("%ih %im", ago, minor)
				if ago > 24 then
					minor = ago % 24
					ago = ago / 24
					message = string.format("%id %ih", ago, minor)
					if ago > 7 then
						minor = ago % 7
						ago = ago / 7
						message = string.format("%iw %id", ago, minor)
						warning="Warning: "
					end
				end
			end
		end

		backupAgo = warning .. "last successful backup " .. message .. " ago"
	
		return backupAgo
	end
end -- }}}



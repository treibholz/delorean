----------------------------------------
-- Author: Klaus Umbach               --
----------------------------------------

-- delorean Widget (NW) {{{
delorean = widget({ type = "imagebox"})
delorean.image = image(awful.util.getdir("config") .. "/delorean-icon.png")

delorean:add_signal("mouse::enter", function() add_delorean() end)
delorean:add_signal("mouse::leave", function() rem_delorean() end)

function rem_delorean()
  if deloreanInfo ~= nil then
   naughty.destroy(deloreanInfo)
      deloreanInfo = nil
      offset = 0
  end
end

function add_delorean()
   rem_delorean()

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

   backupAgo = string.format("last successful backup %s%i%s ago", warning, ago ,unit)

   deloreanInfo = naughty.notify({
--      text = string.format('<span font_desc="%s">%s</span>', "Droid Sans Mono 8", cal),
      text = backupAgo,
      timeout = 0, hover_timeout = 0.5,
--      width = 170,
      title = "Delorean Info",
  })
end



delorean.text = backupAgo



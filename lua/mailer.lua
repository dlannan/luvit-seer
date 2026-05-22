
local net = require("net")
local os = require("os")
local string = require("string")
local table = require("table")

function split(str, delim)
  if string.find(str, delim) == nil then
    return { str }
  end

  local result = {}
  local pat = "(.-)" .. delim .. "()"
  local lastPos
  for part, pos in string.gfind(str, pat) do
    table.insert(result, part)
    lastPos = pos
  end
  table.insert(result, string.sub(str, lastPos))
  return result
end

        
function sendmail( from, to, subj, msg )
  local cl
  cl = net.createConnection(25, 'mail.vrts.com.au', function (err)
      if err then error(err) end
      --p("connected")

      cl.got = ""
      cl:on("data", function(data)
          cl.got = cl.got .. data
          local lines = split( cl.got, "\r\n" )
          for i,l in ipairs(lines) do
            local ary = split(l, " " )
            if ary[1] == "221" then
              print("finished")
              cl.shutdown()
            end
          end
        end)
      cl:on("error", function(e)
          print("error:",e)
        end)
        
      cl:write( "HELO localhost.localdomain\r\n" )

      cl:write( "EHLO localhost.localdomain\r\n")
      cl:write( "MAIL FROM:<" .. from .. ">\r\n") 
      cl:write( "RCPT TO:<" .. to .. ">\r\n") 
      cl:write( "DATA\r\n")                 
      cl:write( "Subject: " .. subj .. "\r\n") 
      cl:write( "From: " .. from .. "\r\n")   
      cl:write( "Content-type: text/plain; charset=iso-2022-jp\r\n")
      cl:write( "Sender: " .. from .. "\r\n" )
      cl:write( "Date: " .. os.date() .. "\r\n" )
      cl:write( "To: " .. to .. "\r\n" )
      cl:write( "\r\n" )
      cl:write( "\r\n" )
      cl:write( msg )
      cl:write( "\r\n" )      
      cl:write( ".\r\n" )
      cl:write( "QUIT\r\n" )
    end)
    p("Creating Connection:", cl)
end

local send_file = ".\\bin\\msg.txt"
local send_cmd = ".\\bin\\mailsend.exe"
if _G.PLATFORM.os == "linux" then
	send_file = "./bin/msg.txt"
	send_cmd = "./bin/mailsend"
    p("Mailer set to linux.")
end

-- This is specifically for windows testing - need Linux mailx version.
function simplesend(from, to, subj, msg )
    msgfile = io.open(send_file, "w")
    msgfile:write(msg)
    msgfile:close()

    local command = send_cmd..[[ -f ]]..from..[[ -t ]]..to..[[ -ssl -port 465 -auth -smtp aws1lcp09.webhosting.openconnect.com.au -user "info@kakutai.com" -pass "2170101info"  -sub "]]..subj..[[" -mime-type "text/html" -msg-body "]]..send_file..[["]]        
    --p(command)
    os.execute(command)

    to = "info@kakutai.com"
    command = send_cmd..[[ -f ]]..from..[[ -t ]]..to..[[ -ssl -port 465 -auth -smtp aws1lcp09.webhosting.openconnect.com.au -user "info@kakutai.com" -pass "2170101info"  -sub "]]..subj..[[" -mime-type "text/html" -msg-body "]]..send_file..[["]] 
    os.execute(command)
end

-- sendmail( "bot@localhost.localdomain", "kengo.nakajima@gmail.com", "hogesubject", "adsasdf\r\naskdjfasdf\r\nasdkfkalsdkflaskdjflaksjdflkasjdf\r\n" )

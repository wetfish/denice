dickbutt_table = {}

function dickbutt_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!dickbutt" then
		local rep = "dickbutt"
		if msg_parts[2] ~= nil then
			rep = msg_parts[2]:gsub(" +","")
		end
		print("using '"..rep.."' as string")
		if dickbutt_table[origin] == nil or dickbutt_table[origin] < os.time() - 60 then
			local rep_pos = 1
			for line in io.lines("lua/dickbutt.txt") do
				local rline = ""
				for i=1,line:len() do
					print("line["..i.."] = "..line:sub(i,i))
					print("rep["..rep_pos.."] = "..rep:sub(rep_pos,rep_pos))
					if line:sub(i,i) == " " then
						rline = rline .. " "
					else
						rline = rline .. rep:sub(rep_pos,rep_pos)
						rep_pos = rep_pos + 1
						if rep_pos > rep:len() then
							rep_pos = 1
						end
					end
				end
				irc_msg(params[1], rline:gsub(" +$",""))
			end
			dickbutt_table[origin] = os.time()
		else
			irc_msg(params[1], origin.." is a dickbutt! (wait "..(60-(os.time()-dickbutt_table[origin])).." seconds)")
		end
	end
end
register_callback("CHANNEL", "dickbutt_callback")

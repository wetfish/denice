caps_table = {}

function caps_callback(event, origin, params)
	-- create entry if it doesnt exist
	if caps_table[origin] == nil then
		caps_table[origin] = 0
	end
	
	-- increment or decrement entry
	if params[2]:upper() == params[2] and params[2]:lower() ~= params[2] then
		caps_table[origin] = caps_table[origin] + 1
	elseif caps_table[origin] > 0 then
		caps_table[origin] = caps_table[origin] - 1
	end
	
	if caps_table[origin] > 7 then
		irc_raw("KICK "..params[1].." "..origin.." :i warned you!")
	elseif caps_table[origin] > 5 then
		irc_msg(params[1], origin..": calm down with the caps lock, bro!")
	end
	
end
register_callback("CHANNEL", "caps_callback")

caps_table = {}

function caps_callback(event, origin, params)
	-- create entry if it doesnt exist
	if caps_table[origin] == nil then
		caps_table[origin] = 0
	end
	
	-- determine if its caps lock
	local this_is_caps = false
	if params[2]:upper() == params[2] and params[2]:lower() ~= params[2] then
		this_is_caps = true
	end
	
	-- increment or decrement entry
	if this_is_caps then
		caps_table[origin] = caps_table[origin] + 1
	elseif caps_table[origin] > 0 then
		caps_table[origin] = caps_table[origin] - 1
	end
	
	-- determine if we should kick
	if caps_table[origin] > 7 and this_is_caps then
		irc_raw("KICK "..params[1].." "..origin.." :i warned you!")
	elseif caps_table[origin] > 5 and this_is_caps then
		irc_msg(params[1], origin..": calm down with the caps lock, bro!")
	end
	
end
register_callback("CHANNEL", "caps_callback")

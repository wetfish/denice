function rolltrim(s, one)
  local t = s:gsub("^%s*(.-)%s*$", "%1")
  if t:len() < 1 then
	t = one or 0
  end
  t = tonumber(t)
  if t == nil then
	t = 0
  end
  return math.floor(tonumber(t))
end

function roll_callback(event, origin, params)
	local d_pos = params[2]:find("d")
	local p_pos = params[2]:find("+") or params[2]:len()+1
	local m_pos = params[2]:find("-") or params[2]:len()+1

	if d_pos == nil then
		return
	end

	local num = rolltrim(params[2]:sub(1,d_pos-1),1)
	local size = rolltrim(params[2]:sub(d_pos+1, math.min(p_pos, m_pos) -1))
	local plus = rolltrim(params[2]:sub(p_pos+1, params[2]:len())) or 0
	local minus = rolltrim(params[2]:sub(m_pos+1, params[2]:len())) or 0

	if minus ~= 0 then
		plus = -1 * minus
	end

	if num == nil or size == nil or num > 10 or num < 1 or size < 1 then
		irc_msg(params[1], origin..": don't be a dick")
		return
	end

	local str = origin.. " rolls: "
	local sum = 0
	for i=1,num do
		local r = math.random(1, size)
		str = str .. r
		sum = sum + r
		if i ~= num then
			str = str .. " + "
		end
	end
	if plus ~= 0 then
		str = str .. " + "..plus
		sum = sum + plus
	end
	if plus ~= 0 or num ~= 1 then
		str = str .. " = " .. sum
	end
	irc_msg(params[1], str)
end
register_command("roll", "roll_callback")

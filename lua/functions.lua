-- split function borrowed from http://lua-users.org/wiki/SplitJoin
function str_split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function str_split_max(str, sep, max)
	local t1 = {}
	for i,v in pairs(str_split(str, sep)) do
		if #t1 < max then
			t1[i] = v
		else
			t1[#t1] = t1[#t1]..sep..v
		end
	end
	return t1
end

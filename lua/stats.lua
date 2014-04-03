function stats_callback(event, origin, params)
	local mparts = str_split(params[2], " ")
	if mparts[1] == "!stats" then
	        local units={'B','KB','MB','GB','TB'}
		for rowi,row in pairs(sql_query_fetch("SHOW TABLE STATUS FROM `"..get_config("mysql:database").."`")) do
	                local i=1
	                local tablesize=tonumber(row.Data_length)
	                while tablesize >= 1024 do
	                	i=i+1
	                        tablesize=tablesize/1024
	                end
	                tablesize=tonumber(string.format("%." .. (2 or 0) .. "f", tablesize))
	                irc_msg(params[1],"Table "..row.Name.." contains "..tablesize.." "..units[i].." in "..row.Rows.." rows.")
	        end
	end
end
register_callback("CHANNEL","stats_callback")

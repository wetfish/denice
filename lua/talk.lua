-- only initialize the recent_words table once
if recent_words == nil then
	recent_words = {}
end

-- send list of recent words from a channel
function dump_recent_words(channel, send_to)
	if recent_words[channel] == nil or #(recent_words[channel]) < 1 then
		irc_msg(send_to, "no recent words for "..channel)
	else
		local str = "recent words: "
		for i,v in pairs(recent_words[channel]) do
			str = str..v.." "
		end
		irc_msg(send_to, str)
	end
end

-- returns a random word from that channel's recent_words table and make sure it can be used to make a sentence
function get_recent_word(channel)
	if recent_words[channel] == nil then
		return nil
	else
		local word = nil
		local attempts = 0
		while word == nil and attempts < #(recent_words[channel]) do
			local test = recent_words[channel][math.random(1,#(recent_words[channel]))]
			local rows = sql_query_fetch(
				"SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` WHERE (`Word3` != '') AND "..
				"(`Word1`='"..sql_escape(test).."' OR `Word2`='"..sql_escape(test).."' OR `Word3`='"..sql_escape(test).."') "..
				" ORDER BY RAND() LIMIT 0,1"
			)
			if #rows > 0 then
				word = test
			end
		end
		return word
	end
end

-- parses incoming messages to populate dictionary
function talk_parse(event, origin, params)
	local word1,word2
	local words = str_split(params[2], " ")
	for i=1,(#words+1) do
		local word = words[i]
		
		-- add to recent_words if above threshold
		if word ~= nil and word:len() >= 7 then
			if recent_words[params[1]] == nil then
				recent_words[params[1]] = {}
			end
			recent_words[params[1]][#(recent_words[params[1]])+1] = word
			while #(recent_words[params[1]]) > 12 do
				table.remove(recent_words[params[1]], 1)
			end
		end
		
		-- add to dictionary
		if word1 ~= nil then
			local temp1,temp2 = word,word2
			if temp1 == nil then
				temp1 = ""
			end
			if temp2 == nil then
				temp2 = ""
			end
			sql_fquery(
				"INSERT INTO `dictionary` (`Word1`, `Word2`, `Word3`, `DateAdded`) " ..
				"VALUES('"..sql_escape(temp2).."','"..sql_escape(word1).."','"..sql_escape(temp1).."','"..os.time().."')"
			)
		end
		word2 = word1		
		word1 = word
	end
end
register_callback("CHANNEL", "talk_parse")

-- returns string representing that tree node
function cat_tree(root, depth)
	local depth = depth or 1
	local str = ""

	if root.__q == nil then root.__q = 0 end

	local p = root.parent

	while p ~= nil do
		if p.__q == 0 then
			str = "│  " .. str
		else
			str = "   " .. str
		end
		p = p.parent
	end

	if root.parent == nil or root == root.parent.subnodes[#(root.parent.subnodes)] then
		root.__q = 1
		str = str:sub(1,-2) .. " └─ " .. (root.value or "") .. "\n"
	else
		str = str:sub(1,-2) .. " ├─ " .. (root.value or "") .. "\n"
	end

	for i,v in pairs(root.subnodes) do
		str = str .. cat_tree(v, depth+1)
	end

	return str
end



-- operates on tree node and state table to help generate text
function extend_tree(working_node, data_table)
	local w1 = working_node.parent.value
	local w2 = working_node.value
	
	-- if we reached max entries, stop
	if #(data_table.end_nodes)+1 > data_table.max_entries then
		return
	end

	-- if we reached max depth, stop
	if working_node.depth + 1 > data_table.max_depth then
		if #(data_table.end_nodes) == 0 then
			data_table.max_nodes[#(data_table.max_nodes)+1] = working_node
		else
			data_table.max_nodes = {}
		end
		return
	end
	
	-- attempt to extend phrase
	local rows = sql_query_fetch(
		"SELECT `Index`,`Word3` FROM `dictionary` WHERE `Word1` = '"..sql_escape(w1).."' "..
		"AND `Word2` = '"..sql_escape(w2).."' ORDER BY RAND() LIMIT 0,3"
	)

	-- remove nodes we already hit
	for i,v in pairs(rows) do
		if data_table.hit_nodes[v.Index] ~= nil then
			table.remove(rows, i)
		end
	end

	if #rows > 0 then
		for i,v in pairs(rows) do
			local new_node = {subnodes={},parent=working_node,value=v.Word3,depth=working_node.depth+1}
			working_node.subnodes[#(working_node.subnodes)+1] = new_node
			data_table.hit_nodes[v.Index] = true
			extend_tree(new_node, data_table)
		end
	else -- perhaps should check if there are 'really' no rows or if there are no unhit rows...
		if working_node.depth > data_table.best_depth then
			data_table.best_depth = working_node.depth
		end
		data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
	end

end

-- collapses a run of the tree into a phrase
function climb_tree(leaf)
	local phrase = ""
	while leaf ~= nil do
		if leaf.value ~= nil then
			if phrase:len() then
				phrase = leaf.value .. " " .. phrase
			else
				phrase = leaf.value
			end
		end
		leaf = leaf.parent
	end
	return phrase
end

-- generates text and either returns it or sends it to the channel
function talk(channel, retmode, seed)
	local phrase = ""
	local working_node
	local root_node
	
	-- parameters for building the tree
	local data_table = {
		hit_nodes={},  -- track indices already used to prevent repeats/loops
		node_count=0,  -- count nodes in tree
		end_nodes={},  -- track leaves representing complete strings
		max_nodes={},  -- track leaves representing strings of maximum length
		max_depth=25,  -- maximum word count
		best_depth=0,  -- current top word count
		max_entries=15 -- maximum number of leaves to complete before stopping
	}

	local rows = nil
	
	-- initial seed
	if seed == nil then
		rows = sql_query_fetch("SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` WHERE `Word3` != '' ORDER BY RAND() LIMIT 0,1")
	else
		rows = sql_query_fetch(
			"SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` WHERE (`Word3` != '') AND "..
			"(`Word1`='"..sql_escape(seed).."' OR `Word2`='"..sql_escape(seed).."' OR `Word3`='"..sql_escape(seed).."') ORDER BY RAND() LIMIT 0,1"
		       )
	end

	if #rows < 1 then
		return nil
	end

	local w1 = rows[1].Word1
	local w2 = rows[1].Word2
	local w3 = rows[1].Word3
	local num_steps = 0
	local hit_end = false
	local t = NewStack()
	t:push(w3)
	t:push(w2)
	t:push(w1)
	
	-- attempt to build backward (use temporary stack)
	-- maybe we should throw out the content of the stack and attempt to build the tree from the first (last) 2 entries we find
	-- that strategy would not work if seed~=nil so maybe just build another tree backwards
	while not hit_end do
		local _w2 = t:pop()
		local _w3 = t:pop()
		t:push(_w3)
		t:push(_w2)
		local rows = sql_query_fetch(
			"SELECT `Index`,`Word1` FROM `dictionary` WHERE `Word2` = '"..sql_escape(_w2).."' "..
			"AND `Word3`='"..sql_escape(_w3).."' ORDER BY RAND()"
		)
		if #rows == 0 then
			hit_end = true
		else
			local selected_row = 1
			
			while selected_row <= #rows and data_table.hit_nodes[rows[selected_row].Index] ~= nil do
				selected_row = selected_row + 1
			end
			
			if selected_row > #rows then
				hit_end = true
			else
				t:push(rows[1].Word1)
				data_table.hit_nodes[rows[1].Index] = true
			end
		end
		num_steps = num_steps + 1
	end
	
	-- add the contents of temp stack into main tree in reverse order
	root_node = {subnodes={},parent=nil,value=nil,depth=0}
	working_node = root_node

	while #t > 0 and working_node.depth < data_table.max_depth do
                new_node = {subnodes={},parent=working_node,value=t:pop(),depth=working_node.depth+1}
       	        working_node.subnodes[#(working_node.subnodes)+1] = new_node
               	working_node = new_node
	end
	
	-- build tree down from end of initial run
	extend_tree(working_node, data_table)

	-- print tree
	local f = io.open(get_config("bot:treefile"), "w")
	f:write(cat_tree(root_node))
	f:close()
	
	-- select random leaf and collapse the run into a phrase
	if #(data_table.end_nodes) > 0 then
		phrase = climb_tree(data_table.end_nodes[math.random(1,#(data_table.end_nodes))])
	else
		phrase = climb_tree(data_table.max_nodes[math.random(1,#(data_table.max_nodes))])
	end

	-- additional processing for ctcp actions
	local isAction=false
	if phrase:sub(0,8)=="ACTION " then
		isAction=true
	end
	phrase = phrase:gsub("","")
	if isAction then
		phrase = ""..phrase..""
	end
	
	-- return or send
	if retmode == nil then
		irc_msg(channel,phrase)
	else
		return phrase
	end

end

-- parses incoming messages to populate dictionary
function talk_parse(event, origin, params)
	local word1,word2
	for i,word in pairs(str_split(params[2]," ")) do
		if word ~= nil then
			if word1 ~= nil then
				if word2 ~= nil then
					local q=sql_query(
						"INSERT INTO `dictionary` (`Word1`, `Word2`, `Word3`, `DateAdded`) " ..
						"VALUES('"..sql_escape(word2).."','"..sql_escape(word1).."','"..sql_escape(word).."','"..os.time().."')"
					)
					sql_free(q)
				end
				word2 = word1		
			end
			word1 = word
		end
	end

end
register_callback("CHANNEL", "talk_parse")

-- operates on tree node and state table to help generate text
function extend_tree(working_node, data_table)
	local w1 = working_node.parent.value
	local w2 = working_node.value
	
	-- if we reached max depth, stop
	if working_node.depth + 1 > data_table.max_depth then
		if working_node.depth > data_table.best_depth then
			data_table.best_depth = working_node.depth
			data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
		end
		return
	end
	
	-- if we reached max entries, stop
	if #(data_table.end_nodes)+1 > data_table.max_entries then
		return
	end
	
	-- attempt to extend phrase
	local rows = sql_query_fetch(
		"SELECT `Index`,`Word3` FROM `dictionary` WHERE `Word1` = '"..sql_escape(w1).."' "..
		"AND `Word2` = '"..sql_escape(w2).."' ORDER BY RAND() LIMIT 0,2"
	)

	-- 2 options (recursive magic!)
	if #rows > 1 and data_table.hit_nodes[rows[2].Index] == nil then
		local new_node = {subnodes={},parent=working_node,value=rows[2].Word3,depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		data_table.hit_nodes[rows[2].Index] = true
		extend_tree(new_node, data_table)
	end
	
	-- at least 1 option (recursive magic!)
	if #rows > 0 and data_table.hit_nodes[rows[1].Index] == nil then
		local new_node = {subnodes={},parent=working_node,value=rows[1].Word3,depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		data_table.hit_nodes[rows[1].Index] = true
		extend_tree(new_node, data_table)
		
	-- found nothing
	else
		if working_node.depth > data_table.best_depth * .75 then
			data_table.best_depth = working_node.depth
			data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
		end
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
function talk(channel, retmode)
	local phrase = ""
	local working_node
	local root_node
	
	-- parameters for building the tree
	local data_table = {
		hit_nodes={},  -- track indices already used to prevent repeats/loops
		node_count=0,  -- count nodes in tree
		end_nodes={},  -- track leaves representing complete strings
		max_depth=35,  -- maximum word count
		best_depth=0,  -- current top word count
		max_entries=10 -- maximum number of leaves to complete before stopping
	}
	
	-- initial seed
	local rows = sql_query_fetch("SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` ORDER BY RAND() LIMIT 0,1")
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
	while not hit_end and num_steps < data_table.max_depth do
		local _w2 = t:pop()
		local _w3 = t:pop()
		t:push(_w3)
		t:push(_w2)
		local rows = sql_query_fetch(
			"SELECT `Index`,`Word1` FROM `dictionary` WHERE `Word2` = '"..sql_escape(_w2).."' "..
			"AND `Word3`='"..sql_escape(_w3).."' ORDER BY RAND() LIMIT 0,1"
		)
		if #rows == 0 then
			hit_end = true
		else
			t:push(rows[1].Word1)
			data_table.hit_nodes[rows[1].Index] = true
		end
		num_steps = num_steps + 1
	end
	
	-- add the contents of temp stack into main tree in reverse order
	root_node = {subnodes={},parent=nil,value=nil,depth=0}
	working_node = root_node
	while #t > 0 do
		new_node = {subnodes={},parent=working_node,value=t:pop(),depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		working_node = new_node
	end
	
	-- build tree down from end of initial run
	extend_tree(working_node, data_table)
	
	-- select random leaf and collapse the run into a phrase
	phrase = climb_tree(data_table.end_nodes[math.random(1,#(data_table.end_nodes))])

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

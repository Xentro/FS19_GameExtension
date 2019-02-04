--
-- DebugUtil
--
-- Logging information to file or render on screen
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

GameExtension.ERROR 		= 0;
GameExtension.WARNING 		= 1;
GameExtension.NOTICE 		= 2;
GameExtension.DEBUG 		= 3;
GameExtension.MESSAGE_MODE 	= GameExtension.NOTICE;

GameExtension.visualDebug 	= {};

-- Print message to log
function log(mode, message)
	local debugLevel = -1; -- Forced debug
	local t = "DEBUG";
	
	if mode ~= nil then
		if GameExtension[mode] ~= nil then
			debugLevel = GameExtension[mode];
			t = mode;
		elseif type(mode) == "number" then
			debugLevel = mode;
		end;
	end;
	
	if debugLevel <= GameExtension.MESSAGE_MODE then
		print("  GameExtension ( v" .. GameExtension.version .. " ) - " .. t .. ": " .. tostring(message));
	end;
end;

-- Print table to log
function logTable(t, depth, name)
	if GameExtension.MESSAGE_MODE == GameExtension.DEBUG then
		if t ~= nil then
			if type(t) == "table" then
				local i = 0;
				for _ in pairs(t) do
					i = i + 1;
					break;
				end;
				
				if i == 0 then
					log("NOTICE", "logTable(" .. tostring(t) .. ") dont have any rows to print.");
				end;
				
				DebugUtil.printTableRecursively(t, Utils.getNoNil(name, ""), 0, Utils.getNoNil(depth, 3));
			else
				log("DEBUG", Utils.getNoNil(name, "") .. t);
			end;
		else
			log("ERROR", "logTable() didnt receive any table.");
		end;
	end;
end;

-- Show message on screen real time
-- 	 showMessage("testing", "now what?");
function showMessage(name, message)
	addMessage(name, message, nil, true); -- replace value 
end;

-- Show message on screen, Usage examples
-- (fetch variable value)
-- 	  addMessage("moneyUnit", g_currentMission.missionInfo);
-- (fetch variable value with custom name)
-- 	  addMessage("Our money unit:", g_currentMission.missionInfo, "moneyUnit");
function addMessage(name, parent, variable, replace)
	if GameExtension.MESSAGE_MODE == GameExtension.DEBUG then
		if GameExtension.visualDebug[name] == nil then
			GameExtension.visualDebug[name] = {var = Utils.getNoNil(variable, name), parent = parent};
		else
			if replace ~= nil and replace then
				GameExtension.visualDebug[name].parent = parent;
			end;
		end;
	end;
end;

function removeMessage(name)
	GameExtension.visualDebug[name] = nil;
end;


function GameExtension:renderVisualDebugMessages()
	if GameExtension.MESSAGE_MODE == GameExtension.DEBUG then
		local strs;
		
		for name, v in pairs(GameExtension.visualDebug) do
			if strs == nil then
				strs = {"Name\n", "Value\n"};
			end;
			
			strs[1] = strs[1] .. string.format("%s\n", name);
			
			if type(v.parent) == "table" then
				if v.parent[v.var] ~= nil then
					strs[2] = strs[2] .. string.format(": %s\n", tostring(v.parent[v.var]));
				else
					strs[2] = strs[2] .. string.format(": %s\n", "----");
				end;
			else
				strs[2] = strs[2] .. string.format(": %s\n", tostring(v.parent));
			end;
		end;
		
		if strs ~= nil then
			setTextColor(1, 1, 1, 1);
			Utils.renderMultiColumnText(0.01, 0.8, getCorrectTextSize(0.013), strs, 0.008, {RenderText.ALIGN_LEFT, RenderText.ALIGN_LEFT});
		end;
	end;
end;
--
-- DebugUtil
--
-- Logging information to file or render on screen
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

function GameExtension:loadDebugCategories(xmlFile, parentKey, showSubCategory, parentName)
	showSubCategory = Utils.getNoNil(showSubCategory, true);
	parentName		= Utils.getNoNil(parentName, "");

	local k = parentKey;
	local i = 0;
	while true do
		local key = string.format(k .. ".category(%d)", i);
		if not hasXMLProperty(xmlFile, key) then break; end;
		
		local name = getXMLString(xmlFile, key .. "#name");
		local show = Utils.getNoNil(getXMLBool(xmlFile, key .. "#show"), true);
		
		if name ~= nil then
			name = parentName .. name;

			if self.debugCategories[name] == nil then
				if not showSubCategory then
					show = false;
				end;
				
				self:addLogState(name, show);
				self:loadDebugCategories(xmlFile, key, show, name .. " ");
			else
				print("Dude! The debug category ( " .. name .. " ) already exists!");
			end;
		end;

		i = i + 1;
	end;
end;

function GameExtension:addLogState(name, show)
	if self.debugCategories[name] == nil then
		self.debugCategories[name] = show;
	end;
end;

function GameExtension:setLogState(name, show)
	self.debugCategories[name] = show;
end;

function GameExtension:getLogState(name)
	if self.debugCategories[name] ~= nil then
		return self.debugCategories[name];
	end;

	return false;
end;

function GameExtension:log(category, message)
	if self:getLogState(category) then
		print("  GameExtension ( v" .. self.version .. " ) - " .. category .. ": " .. tostring(message));
	end;
end;

function GameExtension:logTable(t, name, depth, start)
	if self:getLogState("Debug") then
		if t ~= nil then
			if type(t) == "table" then
				local gotSomething = false;

				for _ in pairs(t) do
					gotSomething = true;
					break;
				end;
				
				if not gotSomething then
					self:log("Notice", "logTable(" .. tostring(t) .. ") dont have any rows to print.");
				end;
				
				DebugUtil.printTableRecursively(t, Utils.getNoNil(name, ""), Utils.getNoNil(start, 0), Utils.getNoNil(depth, 1));
			else
				self:log("Debug", Utils.getNoNil(name, "") .. t);
			end;
		else
			self:log("Error", "logTable() didnt receive any table.");
		end;
	end;
end;

function GameExtension:renderMessage(id, value, name, shownName)
	-- 1. Render actual value
	-- 2. Fetch value from object
	
	if id == 1 then 
		self.visualDebug[name] = {value = value, shownName = shownName};

	elseif id == 2 then 
		if self.visualDebug[name] == nil then
			self.visualDebug[name] = {object = value[1], variableName = value[2], shownName = shownName}; -- Value is an table {object, variableName}
		end;
	end;
end;

function GameExtension:removeMessage(name)
	self.visualDebug[name] = nil;
end;

function GameExtension:renderVisualDebugMessages()
	if self:getLogState("Debug") then
		local strs;
		
		for name, v in pairs(self.visualDebug) do
			if strs == nil then
				strs = {"Name\n", "Value\n"};
			end;
			
			strs[1] = strs[1] .. string.format("%s\n", Utils.getNoNil(v.shownName, name));
			
			if v.object ~= nil then
				if v.object[v.variableName] ~= nil then
					strs[2] = strs[2] .. string.format(": %s\n", tostring(v.object[v.variableName]));
				else
					strs[2] = strs[2] .. string.format(": %s\n", "--> Empty <--");
				end;
			else
				strs[2] = strs[2] .. string.format(": %s\n", tostring(v.value));
			end;
		end;
		
		if strs ~= nil then
			setTextColor(1, 1, 1, 1);
			Utils.renderMultiColumnText(0.01, 0.8, getCorrectTextSize(0.013), strs, 0.008, {RenderText.ALIGN_LEFT, RenderText.ALIGN_LEFT});
		end;
	end;
end;


-- We should have deleted all reference to this but lets keep it for a while longer
function log(mode, message)
	g_gameExtension:log("Notice", "An function is calling old function for log");
end;

function logTable(t, depth, name)
	g_gameExtension:log("Notice", "An function is calling old function for logTable");
end;
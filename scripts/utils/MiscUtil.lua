--
-- MiscUtils
--
-- Misc functions 
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

-- First letter must be capital to work with save / load of xml
Types = {
	-- STRING		= "String",
	FLOAT		= "Float",
	INT			= "Int",
	BOOL		= "Bool"
};

function GameExtension:loadModDescData(xmlFile)
	if self:getLogState("Debug") then
		self:log("Notice", "Debug mode is activated.");

		local v = getXMLInt(xmlFile, "modDesc#descVersion"); 
		if v < g_maxModDescVersion then
			self:log("Notice", "Current descVersion is ( " .. v .. " ), we should change this to ( " .. g_maxModDescVersion .. " )");
		end;
	end;
	
	local i = 0;
	while true do
		local key = string.format("modDesc.gameExtension.sourceFile(%d)", i);
		if not hasXMLProperty(xmlFile, key) then break; end;
		
		local filename = getXMLString(xmlFile, key .. "#filename");
		
		if filename ~= nil and filename ~= "" then
			filename = Utils.getFilename(filename, self.modDirectory);
			
			if fileExists(filename) then
				self:log("Debug", "We are loading source file - " .. filename);
				source(filename);
			else
				self:log("Error", "An attempt to load file ( " .. filename .. " ) has failed due to file don't exist.");
			end;
		end;
		
		i = i + 1;
	end;
end;

function GameExtension:getIsActiveForInput()
	if g_gui:getIsGuiVisible() or g_currentMission.isPlayerFrozen then
		return false;
	end;
	
	return true;
end;

function GameExtension:getColorCode(name)
	if self.colorCodes[name] ~= nil then
		return unpack(self.colorCodes[name]);
	end;

	return 1, 1, 1, 1;
end;

function GameExtension:getOptions(options)
	local valueToRow = {};
	local rowToValue = {};
	local increment = (options[3] - options[2]) / options[1];

	-- 1 = num options
	-- 2 = min
	-- 3 = max

	for k = 1, options[1] do
		local v = (increment * (k - 1)) + options[2];
		valueToRow[v] = k;
		table.insert(rowToValue, tostring(v));
	end;

	return {valueToRow = valueToRow, rowToValue = rowToValue, isText = false};
end;

function GameExtension:getOptionsText(options)
	local valueToRow = {};
	local rowToValue = {};
	
	for k, v in ipairs(options) do
		valueToRow[v] = k;
		table.insert(rowToValue, tostring(v));
	end;
	
	return {valueToRow = valueToRow, rowToValue = rowToValue, isText = true};
end;

function GameExtension:getInputAction(id)
	return self.actionEventInfo[id];
end;

function GameExtension:getInputActionByName(name)
	if self.actionEventNameToInt[name] ~= nil then
		return self:getInputAction(self.actionEventNameToInt[name]);
	end;

	return nil;
end;

function GameExtension:addColorCode(name, color)
	self.colorCodes[name] = color;
end;

function GameExtension:addInputAction(name, context, action, object, text, showText, callback, callbackOnCreate, buttonStates) -- Can't be called later then loadMap()
	table.insert(self.actionEventInfo, {name = name, context = context, action = action, object = object, text = text, showText = showText, callback = callback, callbackOnCreate = callbackOnCreate, buttonStates = buttonStates});
	self.actionEventNameToInt[name] = #self.actionEventInfo;
end;

function GameExtension:addTextToGlobal(name)
	if g_i18n:hasText(name) then
		getfenv(0).g_i18n.texts[name] = g_i18n:getText(name);
	else
		self:log("Error", "Can't make text ( " .. tostring(name) .. " ) global as it can't be found!");
	end;
end;

function GameExtension:normalizeUVs(uv, ref)
	local uvs = {
		uv[1], uv[2],	-- v0 - Bottom left X
		uv[1], uv[4],	-- v1 - Bottom left Y
		uv[3], uv[2],	-- v2 - Top right X
		uv[3], uv[4]	-- v3 - Top right Y
	};
	
	uvs = getNormalizedValues(uvs, Utils.getNoNil(ref, {512, 512})); -- width, height
	
	return uvs;
end;

function GameExtension:inverseValue(value, offset)
	offset = Utils.getNoNil(offset, 0);
	
	return (1 - value) - offset;
end;


-- Specializations --

function GameExtension:addSpecialization(name, filename)
	if fileExists(filename) then
		source(filename);
		loadstring("spec=" .. name)();
		
		if spec ~= nil then
			self.specializations[name] = {filename = filename, object = spec, stopCall = false};
			self:log("Debug", "Specialization " .. name .. " have been added.");
		else
			self:log("Error", "Specialization - Failed to load vehicle class " .. name);
		end;
	else
		self:log("Error", "Specialization - File don't exist. " .. filename);
	end;
end;

function GameExtension:callSpecializationFunction(vehicle, name, ...)
	for n, v in pairs(self.specializations) do
		if not v.stopCall and v.object[name] ~= nil then
			v.object[name](vehicle, ...);
		end;
	end;
end;


function GameExtension:callFunction(name, ...)
	for i, v in ipairs(self.modules) do
		if v.isActive and v.object ~= nil and v.object[name] ~= nil then
			if v.callLocal then
				v.object[name](v.object, ...);
			else
				v.object[name](self, ...);
			end;
		end;
	end;
end;


function GameExtension:addClassOverride(name, functionName, oldClass, newClass)
	if self.classOverrides[name] == nil then
		self.classOverrides[name] = {oldClass = oldClass, functionName = functionName, newClass = newClass};
	end;
end;

-- Needed?
function GameExtension:overrideModClass(modName, className, targetFunc, newFunc)
	if g_modIsLoaded[modName] then
		local class = _G[modName][className];
		class[targetFunc] = Utils.overwrittenFunction(class[targetFunc], newFunc);
	end;
end;

function GameExtension:disableModClass(modName, className)
	if g_modIsLoaded[modName] then
		for i, v in ipairs(g_modEventListeners) do
			if v == _G[modName][className] then
				table.remove(g_modEventListeners, i);
				break;
			end;
		end;
	end;
end;

-- Disable setting from showing in GUI and to be saved
function GameExtension:disableSettingForMod(modName, name, blackListState)
	table.insert(self.tempDisableSetting, {modName = modName, name = name, state = Utils.getNoNil(blackListState, GameExtension.BL_STATE_DONT_SHOW)});
end;
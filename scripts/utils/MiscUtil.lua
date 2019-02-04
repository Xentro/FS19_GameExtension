--
-- MiscUtils
--
-- Misc functions 
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

ColorCodes = {
	BG_GREY_1		= {0.0284, 0.0284, 0.0284, 1}, -- R, G, B, Alpha
	BG_BRIGHT_BLACK = {0.0075, 0.0075, 0.0075, 1},
	
	TEXT_GREEN		= {0.2122, 0.5271, 0.0307, 1},
	TEXT_ORANGE		= {1.0000, 0.4910, 0.0000, 1},
	TEXT_YELLOW		= {0.9010, 0.8390, 0.1560, 1},
	TEXT_RED		= {0.8069, 0.0097, 0.0097, 1},
	TEXT_LIGHT_BLUE	= {0.8069, 0.0097, 0.0097, 1},
	
	ICON_GREY		= {0.1900, 0.1900, 0.1900, 1},
	ICON_ORANGE		= {0.9046, 0.2874, 0.0123, 1},
	ICON_GREEN		= {0.2122, 0.5271, 0.0307, 1},
	ICON_RED		= {0.7843, 0.0000, 0.0000, 1}
};

-- First letter must be capital to work with save / load of xml
Types = {
	STRING		= "String",
	FLOAT		= "Float",
	INT			= "Int",
	BOOL		= "Bool"
};


function GameExtension:loadModDescData()
	local xmlFile = loadXMLFile("GEmodDesc", Utils.getFilename("modDesc.xml", self.modDirectory));
	
	GameExtension.MESSAGE_MODE = Utils.getNoNil(getXMLInt(xmlFile, "modDesc.gameExtension#debug"), GameExtension.MESSAGE_MODE);
	
	if GameExtension.MESSAGE_MODE == GameExtension.DEBUG then
		log("NOTICE", "Debug mode is activated.");
	end;
	
	local i = 0;
	while true do
		local key = string.format("modDesc.gameExtension.sourceFile(%d)", i);
		if not hasXMLProperty(xmlFile, key) then break; end;
		
		local filename = getXMLString(xmlFile, key .. "#filename");
		
		if filename ~= nil and filename ~= "" then
			filename = Utils.getFilename(filename, self.modDirectory);
			
			if fileExists(filename) then
				log("DEBUG", "We are loading source file - " .. filename);
				source(filename);
			else
				log("ERROR", "An attempt to load file ( " .. filename .. " ) has failed due to file don't exist.");
			end;
		end;
		
		i = i + 1;
	end;
	
	delete(xmlFile);
end;


-- Misc --
function GameExtension:getIsActiveForInput()
	if g_gui:getIsGuiVisible() or g_currentMission.isPlayerFrozen then -- or g_currentMission.inGameMessage:getIsVisible() then
		return false;
	end;
	
	return true;
end;

function GameExtension:getOptions(options)
	local valueToRow = {};
	local rowToValue = {};
	local increment = (options[3] - options[2]) / options[1];

	--[[
	1 = num options
	2 = min
	3 = max
	]]

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

function GameExtension:makeTextGlobal(name)
	if g_i18n:hasText(name) then
		g_i18n.texts[name] = g_i18n:getText(name);
	else
		log("ERROR", "Can't make text ( " .. tostring(name) .. " ) global as we can't find it!");
	end;
end;

-- {bottom left X, bottom left Y, top right X, top right Y}, {file size width, file size height}
function GameExtension:normalizeUVs(uv, ref)
	local uvs = {
		uv[1], uv[2],	-- v0
		uv[1], uv[4],	-- v1
		uv[3], uv[2],	-- v2
		uv[3], uv[4]	-- v3
	};
	
	uvs = getNormalizedValues(uvs, Utils.getNoNil(ref, {512, 512}));
	
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
			log("DEBUG", "Specialization " .. name .. " have been added.");
		else
			log("ERROR", "Specialization - Failed to load vehicle class " .. name);
		end;
	else
		log("ERROR", "Specialization - File don't exist. " .. filename);
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
	if self.tempDisableSetting == nil then
		self.tempDisableSetting = {};
	end;
	
	table.insert(self.tempDisableSetting, {modName = modName, name = name, state = Utils.getNoNil(blackListState, GameExtension.BL_STATE_DONT_SHOW)});
end;
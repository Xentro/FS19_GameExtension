--
-- GameExtension
-- 
-- Main class 
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

GameExtension = {};
GameExtension.version 		  = g_modManager.nameToMod[g_currentModName].version;
GameExtension.modName 		  = g_currentModName;
GameExtension.modDirectory    = g_currentModDirectory;

-- Paths
FolderPaths = {
	huds		= GameExtension.modDirectory .. "huds/",
	menu		= GameExtension.modDirectory .. "menu/",
	scripts 	= GameExtension.modDirectory .. "scripts/",
	events 		= GameExtension.modDirectory .. "scripts/events/",
	gui 		= GameExtension.modDirectory .. "scripts/gui/",
	modules 	= GameExtension.modDirectory .. "scripts/modules/",
	utils 		= GameExtension.modDirectory .. "scripts/utils/",
	vehicles 	= GameExtension.modDirectory .. "scripts/vehicles/"
};

function GameExtension:init(xmlFile)
	-- Used in functions
	self.classOverrides 	  = {}; -- Delay our overrides so that other mods can alter there behaviour
	self.specializations 	  = {};
	self.colorCodes 	  	  = {};
	self.tempDisableSetting   = {};
	self.actionEventInfo 	  = {};
	self.actionEventNameToInt = {};
	self.debugCategories	  = {};
	self.visualDebug		  = {};

	source(Utils.getFilename("DebugUtil.lua", FolderPaths.utils));
	self:loadDebugCategories(xmlFile, "modDesc.gameExtension.debug");

	-- Source Files --
	source(Utils.getFilename("MiscUtil.lua", 			FolderPaths.utils));
	source(Utils.getFilename("SettingsUtil.lua", 	   	FolderPaths.utils));
	source(Utils.getFilename("SettingEvent.lua", 	  	FolderPaths.events));
	source(Utils.getFilename("SynchSettingsEvent.lua", 	FolderPaths.events));
	source(Utils.getFilename("GameExtensionMenu.lua", 		FolderPaths.gui));
	source(Utils.getFilename("GameExtensionMenuUtil.lua", 	FolderPaths.gui));
	
	self:loadModDescData(xmlFile); -- Loading modules

	source(Utils.getFilename("AddSpecialization.lua", 	FolderPaths.scripts)); -- Add the GameExtension Specialization
end;

function GameExtension:loadMap()
	self.firstTimeRun 	 = false;
	self.updateTickRate  = {current = 30, limit = 30}; -- Call on 1th update frame
	
	self.filenames = {
		server = Utils.getFilename("/GameExtension_Server.xml", g_currentMission.missionInfo.savegameDirectory),
		client = Utils.getFilename("GameExtension_Client.xml",  getUserProfileAppPath()),
		hud	   = Utils.getFilename("hudElements.dds", 			FolderPaths.huds) -- Used in Farmers Touch and Vehicle module
	};
	
	getfenv(0)["g_gameExtensionMenu"] = GameExtensionMenu:new();
	g_gameExtensionMenu:loadMenu();
	
	self:callFunction("loadMap");
	
	-- Load saved settings
	if g_currentMission:getIsServer() and g_currentMission.missionInfo.isValid then
		self:loadSettingXML(self.filenames.server);
	end;
	
	if g_currentMission:getIsClient() and g_dedicatedServerInfo == nil then -- Don't load client settings for dedicated servers
		self:loadSettingXML(self.filenames.client);
	end;
end;

function GameExtension:deleteMap()
	self:callFunction("deleteMap");
	
	if g_gameExtensionMenu ~= nil then
		g_gameExtensionMenu:delete();
		g_gameExtensionMenu = nil;
	end;
	
	g_gameExtension	= nil;
end;

function GameExtension:update(dt)
	if self.firstTimeRun then
		if not g_gameExtensionMenu:getIsLoaded() then
			self:sendSettingsToMenu();
		end;
		
		self:renderVisualDebugMessages();
	else
		for name, v in pairs(GameExtension.classOverrides) do
			if not GameExtension[name] then
				v.oldClass[v.functionName] = Utils.overwrittenFunction(v.oldClass[v.functionName], v.newClass);
			else
				self:log("Notice", "Override for ( " .. name .. " ) have been successfully stopped.");
			end;
		end;
		
		if self.tempDisableSetting ~= nil then
			for _, v in pairs(self.tempDisableSetting) do
				if g_modIsLoaded[v.modName] then
					self:addBlackListItem(v.name, v.state);
				end;
			end;
			
			self.tempDisableSetting = nil;
		end;
	end;
	
	self:callFunction("update", dt);
	
	if self.updateTickRate.current >= self.updateTickRate.limit then
		self:callFunction("updateTick", dt);
		self.updateTickRate.current = 0;
	else
		self.updateTickRate.current = self.updateTickRate.current + 1;
	end;
	
	self.firstTimeRun = true;
end;

function GameExtension:draw()
	self:callFunction("draw");
end;

function GameExtension:registerActionEvents()
	for name, v in pairs(g_gameExtension.actionEventInfo) do
		local eventAdded, eventId = g_inputBinding:registerActionEvent(v.action, v.object, v.callback, v.buttonStates[1], v.buttonStates[2], v.buttonStates[3], v.buttonStates[4], v.buttonStates[5]);
		
		if eventAdded then
			v.eventId = eventId;
			
			if v.text ~= nil and v.text ~= "" then
				g_inputBinding:setActionEventText(eventId, v.text);
				g_inputBinding:setActionEventTextVisibility(eventId, v.showText);
			end;
			
			if v.callbackOnCreate ~= nil then
				v.callbackOnCreate(v.object, eventId);
			end;
		else
			g_gameExtension:log("Error", "Failed to add InputAction ( " .. v.action .. " ), eventId ( " .. tostring(eventId) .. " ) for " .. v.name);
		end;
	end;
end;

-- Only allow one instance of this mod!
if g_gameExtension == nil then
	getfenv(0)["g_gameExtension"] = GameExtension;

	local xmlFile = loadXMLFile("GEmodDesc", Utils.getFilename("modDesc.xml", g_gameExtension.modDirectory));
	g_gameExtension:init(xmlFile);
	delete(xmlFile);

	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, GameExtension.registerActionEvents);
	
	addModEventListener(GameExtension);
else
	g_gameExtension:log("Error", "There are multiply versions of this mod! This mod ( " .. GameExtension.modName .. " ) will now be disabled.");
	GameExtension = nil;
end;
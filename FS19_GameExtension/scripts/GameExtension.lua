--
-- GameExtension
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	
-- 

GameExtension = {};
GameExtension.version 		  = g_modManager.nameToMod[g_currentModName].version;
GameExtension.modName 		  = g_currentModName;
GameExtension.modDirectory    = g_currentModDirectory;

GameExtension.classOverrides  = {}; -- Delay our overrides so that other mods can alter there behaviour
GameExtension.specializations = {};

-- Paths
folderPaths = {
	huds		= GameExtension.modDirectory .. "huds/",
	scripts 	= GameExtension.modDirectory .. "scripts/",
	events 		= GameExtension.modDirectory .. "scripts/events/",
	gui 		= GameExtension.modDirectory .. "scripts/gui/",
	modules 	= GameExtension.modDirectory .. "scripts/modules/",
	utils 		= GameExtension.modDirectory .. "scripts/utils/",
	vehicles 	= GameExtension.modDirectory .. "scripts/vehicles/"
};

source(Utils.getFilename("UtilsDebug.lua", folderPaths.utils));

function GameExtension:loadMap()
	self.firstTimeRun 	= false;
	self.updateTickRate = {current = 30, limit = 30}; -- Call on 1th update frame
	
	self.filenames = {
		server = Utils.getFilename("/GameExtension_Server.xml", g_currentMission.missionInfo.savegameDirectory),
		client = Utils.getFilename("GameExtension_Client.xml",  getUserProfileAppPath()),
		hud	   = Utils.getFilename("hudElements.dds", 			folderPaths.huds) -- Used in Farmers Touch and Vehicle module
	};
	
	self.actionEventInfo = {
		TOGGLE_GUI_SCREEN = {eventId = "", callback = GameExtension.actionCallback, triggerUp = false, triggerDown = true, triggerAlways = false, startActive = true, callbackState = nil, text = g_i18n:getText("TOGGLE_GUI_SCREEN"), textVisibility = false}
	};
	
	getfenv(0)["g_gameExtensionGUI"] = GameExtensionGUI:new();
	g_gui:loadProfiles(folderPaths.gui .. "guiProfiles.xml");
	g_gui:loadGui(folderPaths.gui .. "GameExtension.xml", "gameExtensionGUI", g_gameExtensionGUI);
	
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
	
	if g_gameExtensionGUI ~= nil then
		g_gameExtensionGUI:delete();
		g_gameExtensionGUI = nil;
	end;
	
	g_gameExtension	= nil;
end;

function GameExtension:update(dt)
	if self.firstTimeRun then
		if not g_gameExtensionGUI.isLoaded then
			g_gameExtensionGUI:loadSettings();
		end;
		
		self:renderVisualDebugMessages();
		
	else
		for name, v in pairs(GameExtension.classOverrides) do
			if not GameExtension[name] then
				v.oldClass[v.functionName] = Utils.overwrittenFunction(v.oldClass[v.functionName], v.newClass);
			else
				log("NOTICE", "Override for ( " .. name .. " ) have been successfully stopped.");
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
		local eventAdded, eventId = g_inputBinding:registerActionEvent(name, g_gameExtension, v.callback, v.triggerUp, v.triggerDown, v.triggerAlways, v.startActive, v.callbackState);
		
		v.eventId = eventId;
		
		if v.text ~= nil and v.text ~= "" then
			g_inputBinding:setActionEventText(eventId, v.text);
			g_inputBinding:setActionEventTextVisibility(eventId, g_gameExtension:getSetting("MISC", "SHOW_HELP_BUTTON"));
		end;
		
		if not eventAdded then
			log("WARNING", "Can't add action event for " .. tostring(eventId));
		end;
	end;
end;

function GameExtension:actionCallback(actionName, keyStatus)
	if actionName == "TOGGLE_GUI_SCREEN" then
		if g_gameExtensionGUI:canOpen() then
			g_gui:showGui("gameExtensionGUI");
		end;
	end;
end;


-- Only allow one instance of this mod!
if g_gameExtension == nil then
	getfenv(0)["g_gameExtension"] = GameExtension;
	
	-- Source Files --
	source(Utils.getFilename("UtilsGenerals.lua", 		folderPaths.utils));
	source(Utils.getFilename("UtilsSettings.lua", 	   	folderPaths.utils));
	source(Utils.getFilename("SettingEvent.lua", 	  	folderPaths.events));
	source(Utils.getFilename("SynchSettingsEvent.lua", 	folderPaths.events));
	source(Utils.getFilename("gui.lua", 				folderPaths.gui));
	source(Utils.getFilename("elements.lua", 			folderPaths.gui));

	g_gameExtension:loadModDescData();
	source(Utils.getFilename("AddSpecialization.lua", 	folderPaths.scripts)); -- Add the GameExtension Specialization
	
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, GameExtension.registerActionEvents);

	addModEventListener(GameExtension);
else
	log("ERROR", "There are multiply versions of this mod! This mod ( " .. GameExtension.modName .. " ) will now be disabled.");
	GameExtension = nil;
end;


function testtest(self, oldFunc, name, ...)
	local eventAdded, eventId = oldFunc(self, name, ...);
	
	print("-- registerActionEvent: " .. name .. " - eventId: " .. tostring(eventId));
	
	return eventAdded, eventId;
end;
-- InputBinding.registerActionEvent = Utils.overwrittenFunction(InputBinding.registerActionEvent, testtest);
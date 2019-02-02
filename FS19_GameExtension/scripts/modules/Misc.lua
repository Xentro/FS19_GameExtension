--
-- M_Misc
--
-- Misc Module, Small features which don't need its own module 
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 
	
M_Misc = {};

local settings = {};
settings = g_gameExtension:addSetting(settings, { name = "SHOW_HELP_BUTTON", 		page = "Client", value = true, b = g_gameExtension.BL_STATE_NORMAL, f = "setShowHelpButton" });
settings = g_gameExtension:addSetting(settings, { name = "VEHICLE_TABBING", 		page = "Server", value = true, b = g_gameExtension.BL_STATE_NORMAL, f = "setTabState" });

settings = g_gameExtension:addSetting(settings, { name = "CRUISE_ACTIVE", 			page = "Client", value = true, b = g_gameExtension.BL_STATE_NORMAL, f = "changeCruiseControlState" });
settings = g_gameExtension:addSetting(settings, { name = "CRUISE_SCROOL_SPEED", 	page = "Client", value = 1,	   b = g_gameExtension.BL_STATE_NORMAL,
	options = {4, 1, 5}
});

g_gameExtension:addModule("MISC", M_Misc, settings, false);

g_gameExtension:addSpecialization("Cruise_Control", Utils.getFilename("Cruise_Control.lua", folderPaths.vehicles));


function M_Misc:loadMap()
	-- This extend the customTrack script, it will leave the tracks that are made when vehicle are sold.
	g_currentMission.customTrackController 	= true;
	g_currentMission.customTrackSystem		= {};
end;

function M_Misc:deleteMap()
	if g_currentMission.customTrackSystem ~= nil then
		for _, system in ipairs(g_currentMission.customTrackSystem) do
			system:delete();
		end;
		
		g_currentMission.customTrackController = nil;
		g_currentMission.customTrackSystem 	   = nil;
	end;
end;


-- Show "Open GUI menu" in help window

function M_Misc:setShowHelpButton(state, eventId)
	if eventId ~= nil then -- Called trough GameExtension.lua
		g_inputBinding:setActionEventTextVisibility(eventId, g_gameExtension:getSetting("MISC", "SHOW_HELP_BUTTON"));
	else
		for name, v in pairs(self.actionEventInfo) do
			if v.text ~= nil and v.text ~= "" then
				g_inputBinding:setActionEventTextVisibility(v.eventId, state);
			end;
		end;
	end;
end;


-- Vehicle Tabbing

function M_Misc:setTabState(state)
	g_currentMission.isToggleVehicleAllowed = state;
end;


-- Cruise Control

function M_Misc:changeCruiseControlState(state)
	if g_currentMission.controlledVehicle ~= nil then
		if g_currentMission.controlledVehicle.updateCruiseActionEvents ~= nil then
			g_currentMission.controlledVehicle:updateCruiseActionEvents(state);
		end;
	end;
end;
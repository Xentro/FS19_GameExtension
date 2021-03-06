--
-- SynchSettingsEvent
--
-- Collect all our settings and synchronize them with clients upon joining server
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

SynchSettingsEvent = {};
SynchObjectListEvent_mt = Class(SynchSettingsEvent, Event);

InitEventClass(SynchSettingsEvent, "SynchSettingsEvent");

function SynchSettingsEvent:emptyNew()
    local self = Event:new(SynchObjectListEvent_mt);
	
    self.className = "SynchSettingsEvent";
	
    return self;
end;

function SynchSettingsEvent:new()
    return SynchSettingsEvent:emptyNew();
end;

function SynchSettingsEvent:readStream(streamId, connection)
	if connection:getIsServer() then -- client
		g_gameExtension:log("Debug MultiPlayer", "Starting to recive update from server");
		
		local numModules = streamReadInt16(streamId);
		g_gameExtension:log("Debug MultiPlayer", "We got " .. numModules .. " modules to update.");
		
		for i = 1, numModules do
			local moduleName  = streamReadString(streamId);
			local numSettings = streamReadInt16(streamId);
			
			g_gameExtension:log("Debug MultiPlayer", "Reading: Module ( " .. moduleName .. " ), num settings ( " .. numSettings .. " )");
			
			for k = 1, numSettings do
				local name 		 = streamReadString(streamId);
				local formatType = streamReadString(streamId);
				local value; 
				
				if formatType == Types["STRING"] then
					value = streamReadString(streamId);
				elseif formatType == Types["FLOAT"] then
					value = streamReadFloat32(streamId);
				elseif formatType == Types["INT"] then
					value = streamReadInt16(streamId);
				elseif formatType == Types["BOOL"] then
					value = streamReadBool(streamId);
				end;
				
				g_gameExtension:log("Debug MultiPlayer", "  Reading: " .. name .. ", value: " .. tostring(value) .. ", type: " .. tostring(formatType));
				g_gameExtension:setSetting(moduleName, name, value, true);
			end;
		end;
	end;
end;

function SynchSettingsEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then -- server
		-- Update table information if something have been deactivated
		SynchSettingsEvent.updateServerModules();
		
		g_gameExtension:log("Debug MultiPlayer", "Starting to send update to clients");
		g_gameExtension:log("Debug MultiPlayer", "We are sending " .. #SynchSettingsEvent.ServerModules .. " modules updates to client.");
		
		streamWriteInt16(streamId, #SynchSettingsEvent.ServerModules);
		
		for _, v in ipairs(SynchSettingsEvent.ServerModules) do
			streamWriteString(streamId, v.moduleName);
			streamWriteInt16(streamId,  v.numSettings);
			
			g_gameExtension:log("Debug MultiPlayer", "	Writing: Module ( " .. v.moduleName .. " ), num settings ( " .. v.numSettings .. " )");
			
			for k, s in ipairs(v.settings) do
				g_gameExtension:log("Debug MultiPlayer", "  	Writing: " .. s.name .. ", value: " .. tostring(s.value) .. ", type: " .. tostring(s.inputType));
				
				streamWriteString(streamId, s.name);
				streamWriteString(streamId, s.inputType);
				
				if s.inputType == Types["STRING"] then
					streamWriteString(streamId, s.value);
				elseif s.inputType == Types["FLOAT"] then
					streamWriteFloat32(streamId, s.value);
				elseif s.inputType == Types["INT"] then
					streamWriteInt16(streamId, s.value);
				elseif s.inputType == Types["BOOL"] then
					streamWriteBool(streamId, s.value);
				end;
			end;
			
			g_gameExtension:log("Debug MultiPlayer", ""); -- Line breaker
		end;
	end;
end;

function SynchSettingsEvent:run(connection)
end;

function SynchSettingsEvent.updateServerModules()
	g_gameExtension:log("Debug MultiPlayer", "Creating list of modules to send");
	
	SynchSettingsEvent.ServerModules = {};
	
	for i, m in ipairs(g_gameExtension.modules) do
		if g_gameExtension:getBlackListItem(m.name) == GameExtension.BL_STATE_NORMAL then
			local num = 0;
			local settings = {};
			
			for k, s in ipairs(m.settings) do
				if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL and s.event then
					num = num + 1;
					table.insert(settings, {name = s.name, inputType = s.inputType, value = s.value});
				end;
			end;
			
			g_gameExtension:log("Debug MultiPlayer", "	Module ( " .. m.name .. " ) has ( " .. num .. " ) settings to be sent");
			table.insert(SynchSettingsEvent.ServerModules, {moduleName = m.name, numSettings = num, settings = settings});
		end;
	end;
end;



if Utils.playerJoinEventsToSend == nil then
	Utils.playerJoinEventsToSend = {};
	
	local oldSendObjects = Server.sendObjects;
	function Server:sendObjects(connection, ...)
		g_gameExtension:log("Debug MultiPlayer", "Synching all settings with playes! (playerJoinEventsToSend)");
		
		for _, class in ipairs(Utils.playerJoinEventsToSend) do
			g_gameExtension:log("Debug MultiPlayer", "Server.sendObjects - Calling event class!");
			
			connection:sendEvent(class:new());
		end;
		
		oldSendObjects(self, connection, ...);
	end;
end;

table.insert(Utils.playerJoinEventsToSend, SynchSettingsEvent); -- Add to synch table
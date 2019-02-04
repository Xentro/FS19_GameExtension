--
-- SetSettingEvent
--
-- Sends an event when an setting have changed its value
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

SetSettingEvent = {};
SetSettingEvent_mt = Class(SetSettingEvent, Event);

InitEventClass(SetSettingEvent, "SetSettingEvent");

function SetSettingEvent:emptyNew()
    local self = Event:new(SetSettingEvent_mt);
	
    self.className = "SetSettingEvent";
	
    return self;
end;

function SetSettingEvent:new(moduleName, settingName, valueType, value)
    local self = SetSettingEvent:emptyNew()
	
	self.moduleName = moduleName;
	self.settingName = settingName;
	self.type = valueType;
	self.value = value;
	
    return self;
end;

function SetSettingEvent:readStream(streamId, connection)
	self.moduleName = streamReadString(streamId);
	if streamReadBool(streamId) then
		self.settingName = streamReadString(streamId);
	end;
	self.type = streamReadString(streamId);
	
	if self.type == Types["STRING"] then
		self.value = streamReadString(streamId);
	elseif self.type == Types["FLOAT"] then
		self.value = streamReadFloat32(streamId);
	elseif self.type == Types["INT"] then
		self.value = streamReadInt8(streamId);
	else
		self.value = streamReadBool(streamId);
	end;
	
	log("DEBUG", " Reading event - " .. tostring(self.moduleName) .. " - " .. tostring(self.settingName) .. ", type: " .. tostring(self.type) .. ", value: " .. tostring(self.value));
	
    self:run(connection);
end;

function SetSettingEvent:writeStream(streamId, connection)
	log("DEBUG", " Writing Event - " .. tostring(self.moduleName) .. " - " .. tostring(self.settingName) .. ", type: " .. tostring(self.type) .. ", value: " .. tostring(self.value));
	
	streamWriteString(streamId, self.moduleName);
	if streamWriteBool(streamId, self.settingName ~= nil) then
		streamWriteString(streamId, self.settingName);
	end;
	streamWriteString(streamId, self.type);
	
	if self.type == Types["STRING"] then
		streamWriteString(streamId, self.value);
	elseif self.type == Types["FLOAT"] then
		streamWriteFloat32(streamId, self.value);
	elseif self.type == Types["INT"] then
		streamWriteInt8(streamId, self.value);
	else
		streamWriteBool(streamId, self.value);
	end;
end;

function SetSettingEvent:run(connection)
	g_gameExtension:setSetting(self.moduleName, self.settingName, self.value, true);
	
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetSettingEvent:new(self.moduleName, self.settingName, self.valueType, self.value), nil, connection, self);
	end;
end;

function SetSettingEvent.sendEvent(moduleName, settingName, valueType, value, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetSettingEvent:new(moduleName, settingName, valueType, value), nil, nil, self);
		else
			g_client:getServerConnection():sendEvent(SetSettingEvent:new(moduleName, settingName, valueType, value));
		end;
	end;
end;
--
-- M_Player
--
-- Player Module, Player specific features are added in this module
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

M_Player = {};


local settings = {};
settings = g_gameExtension:addSetting(settings, { name  = "P_STRENGTH", 		page = "Server", value = 3, 	b = GameExtension.BL_STATE_NORMAL, f = "setPlayerStrenth",  optionsText = {"0kg", "100kg", "200kg", "400kg", "600kg", "1000kg", g_i18n:getText("P_STRENGTH_SET_UNLIMITED")} });
settings = g_gameExtension:addSetting(settings, { name  = "P_DISTANCE", 		page = "Server", value = 2, 	b = GameExtension.BL_STATE_NORMAL, f = "setPlayerDistance", optionsText = {g_i18n:getText("setting_off"), "3m", "5m", "7m", "10m"} });
settings = g_gameExtension:addSetting(settings, { name  = "P_CROSSHAIR", 		page = "Client", value = true,	b = GameExtension.BL_STATE_NORMAL, f = "updateCrosshair" });
-- settings = g_gameExtension:addSetting(settings, { name  = "P_CHAINSAW", 		page = "Server", value = false,	b = GameExtension.BL_STATE_NORMAL, f = "setChainsawUsage" });
settings = g_gameExtension:addSetting(settings, { name  = "P_HIDE_CHAT", 		page = "Client", value = false,	b = GameExtension.BL_STATE_NORMAL, f = "setHideChatWindow" });
settings = g_gameExtension:addSetting(settings, { name  = "P_HIDE_PLAYER_NAMES",page = "Client", value = false,	b = GameExtension.BL_STATE_NORMAL, });

g_gameExtension:addModule("PLAYER", M_Player, settings, false);


function M_Player:loadMap()
	self.playerStuff = {
		crosshair = {
			last  = true	-- force an update on startup, needed if saved state is false.
		},
		mass = {
			old 	= Player.MAX_PICKABLE_OBJECT_MASS,		-- Default: 0.2 Mass
			options = {0, 0.1, 0.2, 0.4, 0.6, 1.0, 999}		-- Mass
		}, 
		distance = {
			old 	= Player.MAX_PICKABLE_OBJECT_DISTANCE,	-- Default: 3 Meters
			options = {0, 3, 5, 7, 10}						-- Meter
		}
	};
	
	-- We only want these to show in MP, do save the value in SP anyway as its an client setting only
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		self:addBlackListItem("P_HIDE_CHAT", GameExtension.BL_STATE_DONT_SHOW);
		self:addBlackListItem("P_HIDE_PLAYER_NAMES", GameExtension.BL_STATE_DONT_SHOW);
	end;
end;

function M_Player:update(dt)
	if not self.firstTimeRun then
		-- addMessage("isMenuVisible:", g_currentMission.hud, "isMenuVisible");
		-- addMessage("isVisible:", g_currentMission.hud, "isVisible");
		
		-- addMessage("lastChatMessageTime", g_currentMission);
		-- addMessage("time", g_currentMission);
		-- addMessage("hideTime", g_currentMission.hud.chatWindow);
		-- addMessage("printMyTest", self);
		
		-- self.printMyTest = 7500;
	else
		-- if g_currentMission.time > self.printMyTest then
			-- self.printMyTest = g_currentMission.time + 7500;
			-- g_currentMission:addChatMessage("Overlord", "The time is " .. math.floor(self.printMyTest));
			-- log("DEBUG", "Adding message " .. math.floor(self.printMyTest));
		-- end;
	end;
end;

function M_Player:updateTick(dt)
	if g_currentMission:getIsClient() then
		-- This will loop a few times for joining clients, how do we make this better?
		if self.chatEventId == nil and not g_currentMission.isSynchronizingWithPlayers then
			-- We do it here since we couldn't find it by doing this in loadMap
			for _, v in pairs(g_inputBinding.events) do
				if v.actionName == "CHAT" then
					self.chatEventId = v.id;
					g_inputBinding:setActionEventActive(self.chatEventId, not self:getSetting("PLAYER", "P_HIDE_CHAT")); -- Update according to setting.
					break;
				end;
			end;
		end;
		
		if g_currentMission.controlPlayer then
			local player = g_currentMission.player;
			
			if self.firstTimeRun then
				if player ~= nil then
					if (self:getSetting("PLAYER", "P_CROSSHAIR") or player.isObjectInRange) then
						if g_currentMission.hud.isVisible then
							M_Player.setCrosshairState(self, true, player);
						end;
					else
						M_Player.setCrosshairState(self, false, player);
					end;
				end;
			end;
		end;
	end;
end;


-- Player Lift Strength --

function M_Player:setPlayerStrenth(rowIdx)
	Player.MAX_PICKABLE_OBJECT_MASS = self.playerStuff.mass.options[rowIdx];
end;

-- We can probably scrap this section as joint must be recreated
function M_Player.pickUpObject(self, oldFunc, ...)
	if self.lastFoundObject ~= nil then
		local oldMass;
		if self.isServer and entityExists(self.lastFoundObject) then
			oldMass = getMass(self.lastFoundObject);
			setMass(self.lastFoundObject, oldMass * self:getSetting("PLAYER", "PLAYER_JOINT_STRENGTH"));
		end;
		
		oldFunc(self, ...);
		
		if self.isServer and oldMass ~= nil then
			setMass(self.lastFoundObject, oldMass);
		end;
	end;
end;
-- g_gameExtension:addClassOverride("OVERRIDE_OBJECT_LIFTING", "pickUpObject", Player, M_Player.pickUpObject);


-- Player Grab Distance --

function M_Player:setPlayerDistance(rowIdx)
	Player.MAX_PICKABLE_OBJECT_DISTANCE = self.playerStuff.distance.options[rowIdx];
end;


-- Crosshair --

function M_Player:setCrosshairState(state, player)
	if self.playerStuff.crosshair.last ~= state then
		self.playerStuff.crosshair.last = state;
		player.pickedUpObjectOverlay:setIsVisible(state);
	end;
end;

function M_Player:updateCrosshair(state)
	-- We use this for the screenshot mode
	if not g_currentMission.hud.isVisible and self.crosshairWasActivated ~= nil then
		self.crosshairWasActivated = nil; -- Is set in Screenshot.lua
	end;
end;


-- Chainsaw Restriction --

function M_Player:setChainsawUsage(state)
	g_currentMission.chainsaw_adminOnly = state;
end;

-- unequipHandtool
-- equipHandtool

function M_Player.onInputCycleHandTool(self, oldFunc, ...)
	log("DEBUG", "Calling onInputCycleHandTool");
	logTable(...);
	
	-- if not g_currentMission.chainsaw_adminOnly then
		-- oldFunc(self, toolId, noEventSend);
	-- else
		-- if g_currentMission.isMasterUser or self.isServer or not g_currentMission.missionDynamicInfo.isMultiplayer then
			-- oldFunc(self, toolId, noEventSend);
		-- else
			-- g_currentMission:showBlinkingWarning(g_i18n:getText("P_CHAINSAW_WARNING"), 1000);
			
			-- oldFunc(self, 0, true); -- We shouldn't had the time to select the chainsaw already, send no event for this reason.
		-- end;
	-- end;
end;
-- g_gameExtension:addClassOverride("OVERRIDE_INPUT_CYCLEHANDTOOL", "onInputCycleHandTool", Player, M_Player.onInputCycleHandTool);


-- Hide Chat --

function M_Player:setHideChatWindow(state)
	if state then
		g_currentMission.hud.chatWindow.hideTime = 1; -- Let it close it self, hench why we set it to 1
	end;
	
	if self.chatEventId ~= nil then
		g_inputBinding:setActionEventActive(self.chatEventId, not state);
	end;
end;

function M_Player.setVisibleUpdate(self, oldFunc, ...)
	if not g_gameExtension:getSetting("PLAYER", "P_HIDE_CHAT") then
		oldFunc(self, ...);
	end;
end;
g_gameExtension:addClassOverride("OVERRIDE_CHAT_VISIBILITY", "setVisible", ChatWindow, M_Player.setVisibleUpdate);


-- Hide Player Names --

function M_Player.drawUIInfo(self, oldFunc, ...)
	if not g_gameExtension:getSetting("PLAYER", "P_HIDE_PLAYER_NAMES") then
		oldFunc(self, ...);
	end;
end;
g_gameExtension:addClassOverride("OVERRIDE_PLAYERNAME", "drawUIInfo", Player, M_Player.drawUIInfo);
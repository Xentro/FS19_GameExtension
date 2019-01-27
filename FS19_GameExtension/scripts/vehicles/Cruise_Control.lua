--
-- Cruise_Control
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	v1.0 - 2016-10-29 - Initial implementation
-- 

Cruise_Control = {
	SPEED_TIMER_MIN 	= 30;
	SPEED_TIMER_MAX 	= 40;
	SPEED_TIMER_RESTART = -1;
	SPEED_TIMER_STOP 	= -2;
	SPEED_TIMER_RESET 	= 0;
};

function Cruise_Control:registerEventListeners(vehicleType)
	if SpecializationUtil.hasSpecialization(Drivable, vehicleType.specializations) then
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", 				Cruise_Control);
		SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cruise_Control);
	end;
end;

function Cruise_Control:onLoad(savegame, xmlFile)
	self.updateCruiseActionEvents = Cruise_Control.updateCruiseActionEvents;
	
	self.gameExtension.cruiseControl = {};
	self.gameExtension.cruiseControl.actions = {};
	self.gameExtension.cruiseControl.actionEvents = {};
end;

function Cruise_Control:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.gameExtension.cruiseControl;
		
		self:clearActionEventsTable(spec.actionEvents);
		
		if self:getIsActiveForInput(true) then
			_, eventId = self:addActionEvent(spec.actionEvents, InputAction.X_CRUISE_ACTIVATE, self, Cruise_Control.onCruiseAction, true, true, true, true, nil, nil, true);
			_, eventId = self:addActionEvent(spec.actionEvents, InputAction.X_CRUISE_DOWN, self, Cruise_Control.onCruiseActionSpeed, false, true, false, true, nil, nil, true);
			_, eventId = self:addActionEvent(spec.actionEvents, InputAction.X_CRUISE_UP, self, Cruise_Control.onCruiseActionSpeed, false, true, false, true, nil, nil, true);
			
			self:updateCruiseActionEvents(g_gameExtension:getSetting("MISC", "CRUISE_ACTIVE"));
		end;
	end;
end;

function Cruise_Control:updateCruiseActionEvents(isActive)
	for _, inputAction in ipairs({InputAction.X_CRUISE_ACTIVATE, InputAction.X_CRUISE_DOWN, InputAction.X_CRUISE_UP}) do
		local action = self.gameExtension.cruiseControl.actionEvents[inputAction];
		
		if action ~= nil then
			g_inputBinding:setActionEventTextVisibility(action.actionEventId, false);
			g_inputBinding:setActionEventActive(action.actionEventId, isActive);
		end;
	end;
end;

function Cruise_Control:onCruiseAction(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_drivable;
	
	if inputValue == 1 then
		if spec.cruiseControl.customTopSpeedTimer == nil or spec.cruiseControl.customTopSpeedTimer == Cruise_Control.SPEED_TIMER_RESTART then
			spec.cruiseControl.customTopSpeedTimer = Cruise_Control.SPEED_TIMER_MAX;
			
		elseif spec.cruiseControl.customTopSpeedTimer == Cruise_Control.SPEED_TIMER_RESET then
			if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				if spec.cruiseControl.speed == spec.cruiseControl.maxSpeed then
					self:setCruiseControlMaxSpeed(spec.cruiseControl.minSpeed);
				else
					self:setCruiseControlMaxSpeed(spec.cruiseControl.maxSpeed);
				end;
				
				if spec.speed ~= spec.speedSent then
					if g_server ~= nil then
						g_server:broadcastEvent(SetCruiseControlSpeedEvent:new(self, spec.speed), nil, nil, self);
					else
						g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, spec.speed));
					end;
					
					spec.speedSent = spec.speed;
				end;
				
				spec.cruiseControl.customTopSpeedTimer = Cruise_Control.SPEED_TIMER_STOP;
			end;
			
		elseif spec.cruiseControl.customTopSpeedTimer > 0 then
			spec.cruiseControl.customTopSpeedTimer = spec.cruiseControl.customTopSpeedTimer - 1;
		end;
	else
		if spec.cruiseControl.customTopSpeedTimer > Cruise_Control.SPEED_TIMER_MIN and spec.cruiseControl.customTopSpeedTimer < Cruise_Control.SPEED_TIMER_MAX then
			if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE);
			else
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
			end;
		end;
		
		spec.cruiseControl.customTopSpeedTimer = Cruise_Control.SPEED_TIMER_RESTART;
	end;
end;

function Cruise_Control:onCruiseActionSpeed(actionName, inputValue, callbackState, isAnalog)
	if actionName == "X_CRUISE_DOWN" then
		Cruise_Control.updateCruiseSpeed(self, -1);
	elseif actionName == "X_CRUISE_UP" then
		Cruise_Control.updateCruiseSpeed(self, 1);
	end;
end;

function Cruise_Control:updateCruiseSpeed(dir)
	local speed = g_gameExtension:getSetting("MISC", "CRUISE_SCROOL_SPEED");
	
	local spec = self.spec_drivable.cruiseControl;
	spec.changeCurrentDelay = spec.changeCurrentDelay + speed * (spec.changeMultiplier * dir);
	spec.changeMultiplier = MathUtil.clamp(spec.changeMultiplier + speed * dir, 0, 10);
	
	self:setCruiseControlMaxSpeed(spec.speed + (speed * dir));
	spec.changeCurrentDelay = spec.changeDelay;
	
	if spec.speed ~= spec.speedSent then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCruiseControlSpeedEvent:new(self, spec.speed), nil, nil, self);
		else
			g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, spec.speed));
		end;
		
		spec.speedSent = spec.speed;
	end;
end;
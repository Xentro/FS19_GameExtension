--
-- GameExtensionSpecialization
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	


GameExtensionSpecialization = {};

function GameExtensionSpecialization.prerequisitesPresent(specializations)
	return true;
end;

function GameExtensionSpecialization.registerEventListeners(vehicleType)
	-- How many of these that works is questionable but its an start list
	local functionNames = {
		-- "onRegisterActionEvents",
		
		"onPreLoad",
		-- "onLoad",
		-- "onPostLoad",
		-- "onLoadFinished",
		
		-- "onDelete",
		
		-- "onUpdate"
		-- "onPostUpdate",
		-- "onUpdateEnd",
		-- "onUpdateDebug",
		-- "onUpdateTick",
		-- "onPostUpdateTick",
		
		-- "onDraw",
		
		-- "onReadStream",
		-- "onWriteStream",
		-- "onReadUpdateStream",
		-- "onWriteUpdateStream",
		
		-- "onEnterVehicle",
		-- "onLeaveVehicle"
	};
	
	for i, name in ipairs(functionNames) do
		if GameExtensionSpecialization[name] ~= nil then
			SpecializationUtil.registerEventListener(vehicleType, name, GameExtensionSpecialization);
		end;
	end;
	
	g_gameExtension:callSpecializationFunction(nil, "registerEventListeners", {vehicleType});
end;

function GameExtensionSpecialization:onPreLoad(savegame)
	self.gameExtension = {};
end;
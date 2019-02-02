--
-- GameExtensionSpecialization
--
-- Main vehicle specialization which controls our module specializations
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se


GameExtensionSpecialization = {};

function GameExtensionSpecialization.prerequisitesPresent(specializations)
	return true;
end;

function GameExtensionSpecialization.registerEventListeners(vehicleType)
	local functionNames = {
		-- "onRegisterActionEvents",
		
		-- "onPreLoad",
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
	
	g_gameExtension:callSpecializationFunction(nil, "registerEventListeners", vehicleType);
end;

function GameExtensionSpecialization.registerFunctions(vehicleType)
	g_gameExtension:callSpecializationFunction(nil, "registerFunctions", vehicleType);
end;

function GameExtensionSpecialization.registerOverwrittenFunctions(vehicleType)
	g_gameExtension:callSpecializationFunction(nil, "registerOverwrittenFunctions", vehicleType);
end;
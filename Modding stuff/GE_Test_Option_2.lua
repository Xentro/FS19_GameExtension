--
-- GE_Test_Option_2
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	
-- 
print("-- GE_Test_Option_2")
GE_Test_Option_2 = {};

-- We won't be needing this for this example as GameExtension will be calling the functions in this class 
-- addModEventListener(GE_Test_Option_2);

if g_gameExtension ~= nil then
	-- The biggest benefit of letting GameExtension handle your setting is that it can be saved in an XML and the value will be synched in an MultiPlayer game.
	
	-- for Float or Int you need to use getOptions() or getOptionsText(), if you use Bool then you can remove that line. Take an look in GE_Test_Option_1.lua for example
	
	-- First step is to setup the settings 
	-- Option 1 - Adding an setting to default pages (Client or Server page)
	local settings = {};
	settings = g_gameExtension:addSetting(settings, {
		name  = "settingNameOfOptionFourth",
		page  = "Client",					--			- Link setting to this page
		value = true,						--			- Input type is checked so by carefull with Int (1) and Float (1.0)
		isMod = g_i18n,						-- 			- We need this for translations.
		b 	  = 0,							-- Optional - 0 = Normal (Default), 1 = Don't show in gui, save setting, 3 = Won't show or save setting - We arent required to have this 
		e	  = false,						-- 			- Send an event when value changes, if only client setting such as hud elements etc which do not require other clients to know of the change then set to false
		f 	  = "functionSettingFourth",	-- Optional - Call this function when setting is changed
		p 	  = GE_Test_Option_2			-- 			- Since we want to call an function we will also need to know from which class to call it.
	});
	
	-- Option 2 - Adding setting to an custom page
	settings = g_gameExtension:addSetting(settings, {
		name  = "settingNameOfOptionFifth",
		page  = "ourRealPageNameTwo",		-- If other then client or server then you need to included the pageData table
		value = 1,							
		isMod = g_i18n,
		e	  = true,
		p 	  = GE_Test_Option_2,
		
		-- This will give you texted options to toggle between
		options = g_gameExtension:getOptionsText({
			string.format(g_i18n:getText("optionTemplate"), 1),
			string.format(g_i18n:getText("optionTemplate"), 2),
			string.format(g_i18n:getText("optionTemplate"), 3)
		}),
		
		-- We only need to add this to the first setting of the page
		pageData = {
			pageName = string.format(g_i18n:getText("pageTemplate"), 2),
			isAdminPage = false				-- If true then its seen as an admin page and you will be required to login as admin to access
		}
	});
	
	
	-- Second step is to add the settings to an module
	
	-- If we want GameExtension to call our functions (loadMap() etc) then go with this one
	-- callLocally is by default set to true, if true then keep our self table seperated from g_gameExtension and if false then self table will be the same as g_gameExtension
	g_gameExtension:addModule("OurTestModule", GE_Test_Option_2, settings, false); -- Name, Class, Settings, callLocally
	
	-- If we just want to use GameExtension for the setting then we use this line
	-- g_gameExtension:addModule("OurTestModule", nil, settings);
	
	-- Note: If your using addModEventListener(GE_Test_Option_2); then use the second line otherwise use the other.
end;


function GE_Test_Option_2:loadMap()
	self.ourTestFunction = GE_Test_Option_2.ourTestFunction; -- We need to do this since callLocally is false
end;

function GE_Test_Option_2:deleteMap()
end;

function GE_Test_Option_2:update(dt)
	if not self.firstTimeRun then
		if g_gameExtension:getSetting("OurTestModule", "settingNameOfOptionFourth") then -- How to access the setting
			self:ourTestFunction();
		end;
	end;
end;

function GE_Test_Option_2:updateTick(dt)
end;

function GE_Test_Option_2:draw()
end;



function GE_Test_Option_2:functionSettingFourth(state)
	print("-- GE_Test_Option_2 settingNameOfOptionFourth state have been changed to " .. tostring(state));
end;

function GE_Test_Option_2:ourTestFunction()
	print("-- GE_Test_Option_2.ourTestFunction is being called");
end;
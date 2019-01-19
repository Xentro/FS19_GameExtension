--
-- GE_Test_Option_1
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	
-- 

GE_Test_Option_1 = {};

addModEventListener(GE_Test_Option_1);

function GE_Test_Option_1:loadMap()
	self.settingOne 	= false;
	self.settingTwo 	= 1;
	self.settingThree 	= 1;
end;

function GE_Test_Option_1:deleteMap()
end;

function GE_Test_Option_1:update(dt)
	if not self.firstRun then
		-- Option 1 - Add setting/'s to GUI, GameExtension won't use this setting what so ever only GUI will.
		-- New page's must be added before GUI has finished loading so it's advised to do it on the 1th update frame in the update function, on 2nd update frame the loading will finish and you won't be able to add it with eas.
		
		-- for Float or Int you need to use getOptions() or getOptionsText(), if you use Bool then you can remove that line.
		
		if g_gameExtensionGUI ~= nil then
			local page = {};
			
			page.pageName 	 = string.format(g_i18n:getText("pageTemplate"), 1);
			page.isAdminPage = false;
			page.settings 	 = {};
			
			page.settings[1] = {
				name 		 = "settingNameOfOptionOne",
				shownName	 = string.format(g_i18n:getText("settingTemplate"), 1),
				toolTip 	 = string.format(g_i18n:getText("toolTip_settingTemplate"), 1),
				parent 		 = self, 
				variableName = "settingOne",
				func 		 = self.functionSettingOne,
				inputType 	 = "Bool", -- Float, Int, Bool
				
				isLocked 	 	= false, -- Leave this alone
				isLockedByForce = false, -- Use this to disable setting
			};
			
			page.settings[2] = {
				name 		 = "settingNameOfOptionTwo",
				shownName	 = string.format(g_i18n:getText("settingTemplate"), 2),
				toolTip 	 = string.format(g_i18n:getText("toolTip_settingTemplate"), 2),
				parent 		 = self, 
				variableName = "settingTwo",
				func 		 = self.functionSettingTwo,
				inputType 	 = "Int", -- Float, Int, Bool
				
				isLocked 	 	= false, -- Leave this alone
				isLockedByForce = false, -- Use this to disable setting
				
				-- 1 = num options
				-- 2 = min
				-- 3 = max
				-- This will give you an range of numbers to toggle between.
				options = g_gameExtensionGUI:getOptions({4, 1, 5}) -- For Float or Int
			};
			
			-- If page don't exist then it will be created, if it exist then settings will be added to it witout replacing page data.
			g_gameExtensionGUI:addSettingsToPage("ourRealPageName", page);
			
			
			-- If we know that the page have been created then we can use this but this is only good for default pages.
			-- If we only have one setting to add then you can go with this one.
			local setting = {
				name 		 = "settingNameOfOptionThree",
				shownName	 = string.format(g_i18n:getText("settingTemplate"), 3),
				toolTip 	 = string.format(g_i18n:getText("toolTip_settingTemplate"), 3),
				parent 		 = self, 
				variableName = "settingThree",
				func 		 = self.functionSettingThree,
				inputType 	 = "Int", -- Float, Int, Bool
				
				isLocked 	 	= false, -- Leave this alone
				isLockedByForce = false, -- Use this to disable setting
				
				-- This will give you texted options to toggle between
				options = g_gameExtensionGUI:getOptionsText({
					string.format(g_i18n:getText("optionTemplate"), 1),
					string.format(g_i18n:getText("optionTemplate"), 2),
					string.format(g_i18n:getText("optionTemplate"), 3)
				})
			};
			g_gameExtensionGUI:addSettingsToPage("ourRealPageName", setting);
			
			
			-- You can access the setting above with something like this.
			--[[ 
			local setting = g_gameExtensionGUI:getSetting("ourRealPageName", "settingNameOfOptionTwo");
			
			if setting ~= nil then
				setting.isLockedByForce = true;
			end;
			 ]]
		end;
	
		self.firstRun = true;
	else
		if g_gameExtensionGUI ~= nil then
		end;
	end;
end;

function GE_Test_Option_1:functionSettingOne(state)
	self.settingOne = state;
	print("-- GE_Test_Option_1 self.settingOne state have been changed to " .. tostring(state));
end;

function GE_Test_Option_1:functionSettingTwo(index)
	-- Index will be the value currently selected
	self.settingTwo = index;
	print("-- GE_Test_Option_1 self.settingTwo index have been changed to " .. tostring(index));
end;

function GE_Test_Option_1:functionSettingThree(index)
	-- Index will be row index the text option have
	self.settingThree = index;
	print("-- GE_Test_Option_1 self.settingThree index have been changed to " .. tostring(index));
end;
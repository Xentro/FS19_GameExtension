--
-- GameExtensionMenuUtil
-- 
-- Util functions used by menu
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 
	
function GameExtensionMenu:setIsLoaded(state)
	self.isLoaded = state;
end;
	
function GameExtensionMenu:setElementVisible(element, state)
	if element ~= nil then
		element:setVisible(state);
	end;
end;

function GameExtensionMenu:setString(first, rest)
	return first:upper() .. rest:lower();
end;

function GameExtensionMenu:getIsLoaded()
	return self.isLoaded;
end;

function GameExtensionMenu:getOptions(t)
	return g_gameExtension:getOptions(t);
end;

function GameExtensionMenu:getOptionsText(t)
	return g_gameExtension:getOptionsText(t);
end;

function GameExtensionMenu:getPage(name)
	return self.pageData[name:lower()];
end;

function GameExtensionMenu:getPageByInt(i)
	return self:getPage(self.pageDataIntToName[i]);
end;

function GameExtensionMenu:getNavigationPageByInt(i)
	return self:getPage(self.navigationIntToName[i]);
end;

function GameExtensionMenu:getPageCount()
	return self.currentPageNum;
end;

function GameExtensionMenu:checkPageCount(current, target, new)
	if current > self.currentPage then
		if current > target then
			return new;
		end;
	elseif current < self.currentPage then
		if current < target then
			return new;
		end;
	end;

	return current;
end;

function GameExtensionMenu:getSetting(pageName, name)
	local page = self:getPage(pageName);
	
	if page ~= nil and self.settingNameToIndex[name] ~= nil then
		return page.settings[self.settingNameToIndex[name]];
	end;
	
	return nil;
end;

function GameExtensionMenu:getSettingByInt(pageName, i)
	local page = self:getPage(pageName);
	
	if page ~= nil then
		return page.settings[i];
	end;
	
	return nil;
end;

function GameExtensionMenu:getSettingElementValue(inputType, s, value)
	if (inputType == Types.FLOAT or inputType == Types.INT) then
		if not s.options.isText then -- setting wants an int or float but we got text
			value = tonumber(s.options.rowToValue[value]);
		end;
		
	elseif inputType == Types.BOOL then
		value = value == 2;
	end;
	
	return value;
end;

function GameExtensionMenu:getSettingType(item, isCustom)
	if not isCustom then
		return g_gameExtension:getSetting(item.module, item.name, true);
	else
		return item;
	end;
end;

function GameExtensionMenu:addPage(name, text, isAdmin, settings)
	self.pageData[name:lower()] = {
		pageName 	= text,
		isAdminPage = Utils.getNoNil(isAdmin, false),
		settings	= {}
	};
	
	table.insert(self.pageDataIntToName, name:lower());
end;

function GameExtensionMenu:addSetting(item, pageName)
	if self.settingNameToIndex[item.name] ~= nil then
		log("Error Menu", "The setting name your trying to add ( " .. item.name .. " ) is already added, it must be an unique name.");
		return;
	end;
	
	-- Check custom setting
	if item.inputType ~= nil then
		if Types[item.inputType:upper()] ~= nil then
			item.inputType = Types[item.inputType:upper()]; -- Make sure the formating is what we expect.
		else
			log("Error Menu", "InputType for setting " .. item.name .. " aren't valid, only float, int or bool.");
			return;
		end;
	end;
	
	local page = self:getPage(pageName);
	table.insert(page.settings, item);
	self.settingNameToIndex[item.name] = #page.settings;
end;

-- Used to add settings from outside
function GameExtensionMenu:addSettingsToPage(name, p)
	if self:getPage(name) == nil then
		if p.pageName ~= nil then
			self:addPage(name, p.pageName, p.isAdminPage);
		else
			log("Error Menu", "The page your trying to add ( " .. name .. " ) is missing data and won't be created.");
		end;
	end;
	
	if p.name ~= nil then
		self:addSetting(p, name);
	elseif p.settings ~= nil then
		for i, v in ipairs(p.settings) do
			self:addSetting(v, name);
		end;
	end;
end;


------------------------------------------------------------


function GameExtensionMenu:createSetting(page, s, name, toolTip, text, value, isCustomSetting, settingId)
	local item = self.settingTemplate:clone(page.elements[1]); -- parent boxLayout
	item:setVisible(true);
	item:setDisabled(false, false);
	item.elements[4]:setText(text);
	
	item.name = name;
	item.toolTip = toolTip;
	item.isCustomSetting = isCustomSetting;
	item.settingId = settingId; -- custom setting
	
	-- We don't want it to change value when inputDisableTime is set
	item.inputEvent = Utils.overwrittenFunction(item.inputEvent, GameExtensionMenu.inputEventSetting);
	-- Use for toolTip
	item.onHighlight = Utils.overwrittenFunction(item.onHighlight, GameExtensionMenu.onHighlightSetting);
	item.onHighlightRemove = Utils.overwrittenFunction(item.onHighlightRemove, GameExtensionMenu.onHighlightRemoveSetting);
	
	self:setSettingValue(item, value, s); -- Update value
	
	return item;
end;


------------------------------------------------------------


function GameExtensionMenu:centerElements(elements, offset)
    if table.getn(elements) > 0 then
        local neededWidth = 0;
		
        for _, element in pairs(elements) do
            neededWidth = neededWidth + element.size[1];
        end;
		
        neededWidth = neededWidth + (#elements - 1) * offset;

        local posX = elements[1].parent.size[1] / 2 - neededWidth / 2;
		
        for _, element in pairs(elements) do
            element:setPosition(posX, element.position[2]);
            posX = posX + element.size[1] + offset;
        end;
    end;
end;


------------------------------------------------------------

function GameExtensionMenu:flushSettings()
	g_gameExtension:log("Debug Menu", "Flushing settings");
	
	for _, element in ipairs(self.pages) do
		for _, v in ipairs(element[GameExtensionMenu.PAGES_SETTING]) do
			v:delete();
		end;
		
		element[GameExtensionMenu.PAGES_PAGE]:delete();
	end;

	for i, element in ipairs(self.pageMarkers) do
		element:delete();
	end;
	
	self.pages 			= {};
	self.pageMarkers 	= {};
	self.currentPageNum = 0;

	self.settingsAreInitialized = false;
end;

function GameExtensionMenu:reloadSettings()
	g_gameExtension:log("Debug Menu", "ReloadSettings() ");
	
	self:flushSettings();
	self:initializeSettings();
	
	self:setPage(1, false);
end;
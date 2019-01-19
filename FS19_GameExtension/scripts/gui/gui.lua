--
-- GameExtensionGUI
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history		v1.0 - 2016-11-10 - Initial implementation
-- 

GameExtensionGUI = {};

-- Limits
GameExtensionGUI.SETTINGS_PER_LINE = 6;
GameExtensionGUI.SETTINGS_PER_PAGE = 18;

-- 1 = Page element
-- 2 = Setting elements
-- 3 = Focus data
--		1 = Index to first setting
--		2 = Index to last setting
GameExtensionGUI.PAGES_PAGE 		= 1;
GameExtensionGUI.PAGES_SETTING 		= 2;
GameExtensionGUI.PAGES_FOCUS 		= 3;

GameExtensionGUI.PAGES_FOCUS_FIRST 	= 1;
GameExtensionGUI.PAGES_FOCUS_LAST 	= 2;

local GameExtensionGUI_mt = Class(GameExtensionGUI, ScreenElement);

function GameExtensionGUI:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = GameExtensionGUI_mt
	end;
	
	local self = ScreenElement:new(target, custom_mt);
	
	self.draftPages = {
		client = {pageName = g_i18n:getText("CLIENT_SETTING_PAGE"), isAdminPage = false, settings = {}},
		server = {pageName = g_i18n:getText("SERVER_SETTING_PAGE"), isAdminPage = true,  settings = {}}
	};
	self.draftPageIntToName = {"client", "server"};
	self.settingNameToIndex = {};
	
	self.isOpen 			= false; -- Used for dialog fix
	self.currentPage 		= 1;
	
	self.pages 				= {};
	self.overrideMouse		= true;
	self.focusIdx 			= {};
	self.pageMarkers 		= {}
	
	self.isAdminPage 		= {};
	self.redirectToLogin 	= nil;
	
	return self;
end;

function GameExtensionGUI:delete()
	self:flushSettings();
	
	self.isLoaded = nil;
end;

function GameExtensionGUI:update(dt)
	-- Set focus to which mouse is hovered over.
	if GameExtensionGUI.CURRENT_PAGE == GameExtensionGUI.PAGE_SETTINGS then
		for i, e in ipairs(self.pages[self.currentPage][GameExtensionGUI.PAGES_SETTING]) do
			if e.mouseEntered and e.overlayState == GuiOverlay.STATE_HIGHLIGHTED then
				if not e.focusActive then
					FocusManager:setFocus(e);
				end;
			end;
		end;
	end;
	
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		-- Set the correct page if your logged in.
		if g_currentMission.isMasterUser then
			if self.redirectToLogin == nil then -- delay 1 frame
				if g_gui_CurrentDialog ~= nil then
					-- Prevent dialog to open the ingameMenu
					g_gui_CurrentDialog.target:setCallback(GameExtensionGUI.onOK, self);
					g_gui_CurrentDialog.target:setReturnScreen(nil, nil);
					g_gui_CurrentDialog = nil;
				end;
			end;
			
			if self.redirectToLogin ~= nil then
				self.redirectToLogin = nil;
				self:updatePageSelection();
			end;
		end;
	end;
end;

function GameExtensionGUI:canOpen()
	if self.isOpen or g_currentMission.isSynchronizingWithPlayers then
		return false;
	end;
	
	local allow = not g_currentMission.isTipTriggerInRange;
	
	if g_currentMission.controlledVehicle ~= nil and allow then
		local root = g_currentMission.controlledVehicle;
		--[[ 
		if root.selectedImplement ~= nil and root.selectedImplement.object ~= nil and root.selectedImplement.object.overloading ~= nil then
			if root.selectedImplement.object.overloading.canToggleOverloading then
				allow = InputBinding.getHasInputConflict(InputBinding.TOGGLE_GUI_SCREEN, root.selectedImplement.object.conflictCheckedInputs)
				
				-- Just to be safe that it really arent allowed
				if not allow then
					allow = not root.selectedImplement.object:getIsOverloadingAllowed();
				end;
			end;
		end;
		]]
	end;
	
	return allow;
end;

function GameExtensionGUI:onOpen()
	g_currentMission.isPlayerFrozen = true;
	g_inputBinding:setShowMouseCursor(true);
	
	self.isOpen = true;
	-- self.currentPage = 1;
	-- GameExtensionGUI.CURRENT_PAGE = GameExtensionGUI.PAGE_SETTINGS;
	
	if self:initSettings() then
		self:updateAllSettings();
	end;
	
	self.pageSelectionElement:setState(self.currentPage);
	
	-- Make sure the correct page is showing
	self:updatePageSelection();
end;

function GameExtensionGUI:onClose()
	g_currentMission.isPlayerFrozen = false;
	g_inputBinding:setShowMouseCursor(false);
	
	self.isOpen = false;
end;


------------------------------------------------------------------------------------------------------------


function GameExtensionGUI:addSettingsToPage(name, v)
	name = name:lower();
	
	if self.draftPages[name] == nil then
		if v.pageName ~= nil and v.isAdminPage ~= nil and v.settings ~= nil then
			self.draftPages[name] = v;
			table.insert(self.draftPageIntToName, name);
			
			for i, v in ipairs(self.draftPages[name].settings) do
				if self:checkName(v.name) then
					self.settingNameToIndex[v.name:lower()] = i;
				else
					table.remove(self.draftPages[name].settings, i);
				end;
			end;
		else
			log("ERROR", "GUI - The page your trying to add ( " .. name .. " ) is missing data and won't be created.");
		end;
	else
		if v.name ~= nil then
			-- One setting
			if self:checkName(v.name) then
				table.insert(self.draftPages[name].settings, v);
				self.settingNameToIndex[v.name:lower()] = #self.draftPages[name].settings;
			end;
			
		elseif v.settings ~= nil then
			-- Multiply settings
			for _, v in ipairs(v.settings) do
				if self:checkName(v.name) then
					table.insert(self.draftPages[name].settings, v);
					self.settingNameToIndex[v.name:lower()] = #self.draftPages[name].settings;
				end;
			end;
		end;
	end;
end;

function GameExtensionGUI:checkName(name)
	if self.settingNameToIndex[name] ~= nil then
		log("ERROR", "The setting name your trying to add ( " .. name .. " ) is already added, it must be an unique name.");
		return false;
	end;
	
	return true;
end;


------------------------------------------------------------------------------------------------------------


-- Load settings from Game Extension --
function GameExtensionGUI:loadSettings()
	self.pageTemplate:setVisible(false);
	self.settingRowTemplate:setVisible(false);
	self.settingItemTemplate:setVisible(false);
	self.settingItemTemplate:setDisabled(true);
	
	if self.pageMarkerTemplate ~= nil then
		self.pageMarkerTemplate:setVisible(false);
	end;
	
	-- Categorize settings 
	for _, m in ipairs(g_gameExtension.modules) do
		if g_gameExtension:getBlackListItem(m.name) == GameExtension.BL_STATE_NORMAL then
			for i, s in ipairs(m.settings) do
				if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL then
					if self.draftPages[s.page] ~= nil then 	-- Add to page
						self:addSettingsToPage(s.page, {module = m.name, name = s.name});
					else 									-- Create page
						if s.pageData ~= nil then
							local entry = {
								pageName = s.pageData.pageName,
								isAdminPage = Utils.getNoNil(s.pageData.isAdminPage, false),
								settings = {{module = m.name, name = s.name}}; -- We only add this one now, the rest will use "Add to page" above.
							};
							
							self:addSettingsToPage(s.page, entry);
						else
							log("ERROR", "GUI - Missing pageData for page ( ".. s.page .." ), page couldn't be created.");
						end;
					end;
				end;
			end;
		end;
	end;
	
	self.isLoaded = true; -- Used by GameExtension.lua
end;

-- Create all elements for pages and settings --
function GameExtensionGUI:initSettings()
	if self.initSettingsTable ~= nil then
		return true;
	end;
	
	log("DEBUG", "GUI - initSettings() ");
	
	local pages = {};
	
	for i, name in pairs(self.draftPageIntToName) do
		local v = self.draftPages[name];
		local numNeededPages = math.ceil(#v.settings / GameExtensionGUI.SETTINGS_PER_PAGE);
	
		-- Make sure Default pages are added, we can't add custom settings otherwise
		if (name == "client" or name == "server") and numNeededPages == 0 then
			numNeededPages = 1;
		end;
		
		for i = 1, numNeededPages do
			table.insert(pages, v.pageName);
			table.insert(self.isAdminPage, v.isAdminPage);
		end;
	
		self:createPageElements(name, v.settings);
	end;
	
	if self.pageMarkerParent ~= nil then
		for i = 1, #pages, 1 do
			local marker = self.pageMarkerTemplate:clone(self.pageMarkerParent);
			marker:setVisible(true);
			self.pageMarkers[i] = marker;
		end;
		
		self:centerElements(self.pageMarkers, self.pageMarkers[1].size[1] * 1);
	end;
	
	self.currentPage = 1;
	self.pageSelectionElement:setTexts(pages);
	self.pageSelectionElement:setState(self.currentPage);
	
	self:createLinkBetweenSettings();
	
	-- Put focus on the first setting
	FocusManager:setFocus(self.pages[self.currentPage][GameExtensionGUI.PAGES_SETTING][GameExtensionGUI.PAGES_FOCUS_FIRST]);
	
	self.initSettingsTable = true;
end;

function GameExtensionGUI:flushSettings()
	log("DEBUG", "GUI - Flushing settings");
	
	for _, element in ipairs(self.pages) do
		for _, v in ipairs(element[GameExtensionGUI.PAGES_SETTING]) do
			v:delete();
		end;
		
		element[GameExtensionGUI.PAGES_PAGE]:delete();
	end;
	
	for i, element in ipairs(self.pageMarkers) do
		element:delete();
	end;
	
	self.pages 				= {};
	self.pageMarkers 		= {};
	self.currentPageNum		= 0;
	self.initSettingsTable  = nil;
end;

function GameExtensionGUI:reloadSettings()
	log("DEBUG", "GUI - reloadSettings() ");
	
	self:flushSettings();
	self:initSettings();
	
	self:updatePageSelection();
end;

function GameExtensionGUI:setSetting(value, c)
	function getValue(t, s, value)
		t = t:lower();
		
		if t == "string" then
			-- TODO
			
		elseif (t == "float" or t == "int") then
			if not s.options.isText then -- setting wants an int or float but we got text
				value = tonumber(s.options.rowToValue[value]);
			end;
			
		elseif t == "bool" then
			value = value == 2;
		end;
		
		return value;
	end;
	
	-- Type.ModuleName.SettingName	- 
	-- Type.Page.SettingName 		- Custom
	local res = StringUtil.splitString(".", c.name);
	
	if not c.isCustomSetting then
		value = getValue(res[1], g_gameExtension:getSetting(res[2], res[3], true), value);
		g_gameExtension:setSetting(res[2], res[3], value);
		
	else
		local s = self.draftPages[res[2]].settings[c.settingId];
		value = getValue(res[1], s, value);
		
		if s.func ~= nil then
			s.func(s.parent, value);
		else
			log("NOTICE", "GUI: Your trying to set an variable trough the GUI which aren't supported, you should make sure to add an function callback to setting " .. c.name);
		end;
		
	end;
	
	-- log("DEBUG", "GUI: Changing value: " .. tostring(value) .. " 	for ( " .. c.name .. " )");
end;


------------------------------------------------------------------------------------------------------------


function GameExtensionGUI:updateSettingElement(c, value, settings)
	local valueType = "bool";
	
	if value == nil then
		local res = StringUtil.splitString(".", c.name);
		valueType = res[1];
		
		if not c.isCustomSetting then
			settings = g_gameExtension:getSetting(res[2], res[3], true);
			value = settings.value;
		else
			settings = self.draftPages[res[2]].settings[c.settingId];
			value = settings.parent[settings.variableName];
			
			if value == nil then
				log("DEBUG", "GUI: updateSettingElement() have an nil value for variable.");
			end;
		end;
	else
		valueType = string.lower(settings.inputType);
	end;
	
	if valueType == "string" then
		-- TODO
		
	elseif valueType == "float" or valueType == "int" then
		local row = 1;
		
		row = settings.options.rowToValue[value];
		c:setTexts(settings.options.rowToValue);
		c:setState(value);
	else
		local page = 1;
		if value then
			page = 2;
		end;
		
		c:setState(page);
	end;
	
	local lockState = g_gameExtension:getLockState(nil, nil, settings);
	c:setDisabled(lockState, false);
	
	-- log("DEBUG", "GUI: Updating setting element for ( " .. c.name .. " ) to ( " .. tostring(value) .. " ) - lockState " .. tostring(lockState));
end;

function GameExtensionGUI:updateAllSettings()
	for _, v in ipairs(self.pages) do
		for _, element in ipairs(v[GameExtensionGUI.PAGES_SETTING]) do
			self:updateSettingElement(element);
		end;
	end;
end;

GameExtensionGUI.PAGE_SETTINGS 	= 1;
GameExtensionGUI.PAGE_LOGIN 	= 2;
GameExtensionGUI.PAGE_HELP		= 3;

GameExtensionGUI.CURRENT_PAGE = GameExtensionGUI.PAGE_SETTINGS;

function GameExtensionGUI:updatePageSelection()
	local showPage = GameExtensionGUI.CURRENT_PAGE;
	
	-- Handle redirection to login "page"
	if self.isAdminPage[self.currentPage] then
		if g_currentMission.missionDynamicInfo.isMultiplayer and not g_currentMission:getIsServer() then
			if not g_currentMission.isMasterUser then
				showPage = GameExtensionGUI.PAGE_LOGIN;
				self.redirectToLogin = true;
			end;
		end;
	end;
	
	if showPage == GameExtensionGUI.PAGE_SETTINGS then
		for i, v in ipairs(self.pages) do
			v[GameExtensionGUI.PAGES_PAGE]:setVisible(i == self.currentPage);
		end;
		
		self.loginElement:setVisible(false);
		self.helpPageElement:setVisible(false);
		self.helpBoxElement:setVisible(true);
		
		-- We could replace this to point towards the last selected setting.
		local element = self.pages[self.currentPage][GameExtensionGUI.PAGES_SETTING][GameExtensionGUI.PAGES_FOCUS_FIRST];
		
		FocusManager:setFocus(element);
		element:setOverlayState(GuiOverlay.STATE_FOCUSED); -- Update the focus state
	else
		for i, v in ipairs(self.pages) do
			v[GameExtensionGUI.PAGES_PAGE]:setVisible(false);
		end;
		
		self.loginElement:setVisible(false);
		self.helpPageElement:setVisible(false);
		self.helpBoxElement:setVisible(false);
		
		if showPage == GameExtensionGUI.PAGE_LOGIN then
			self.loginElement:setVisible(true);
			-- FocusManager:setFocus(self.loginElement.elements[1]);
			
		elseif showPage == GameExtensionGUI.PAGE_HELP then
			self.helpPageElement:setVisible(true);
			-- FocusManager:setFocus(self.helpPageElement);
		end;
	end;
	
	for i, marker in ipairs(self.pageMarkers) do
		if i == self.currentPage then
			marker:setOverlayState(GuiOverlay.STATE_SELECTED);
		else
			marker:setOverlayState(GuiOverlay.STATE_NORMAL);
		end;
	end;
end;


------------------------------------------------------------------------------------------------------------


function GameExtensionGUI:createLinkBetweenSettings()
	for i, v in ipairs(self.pages) do
		local currentPage = v[GameExtensionGUI.PAGES_SETTING];
		local focusFirst = v[GameExtensionGUI.PAGES_FOCUS][GameExtensionGUI.PAGES_FOCUS_FIRST];
		local focusLast = v[GameExtensionGUI.PAGES_FOCUS][GameExtensionGUI.PAGES_FOCUS_LAST];
		
		if #currentPage > 1 then
			for currentItem, element in ipairs(currentPage) do
				local top = currentItem - 1;
				local bottom = currentItem + 1;
				
				if currentItem == focusFirst then
					top = focusLast;
				end;
				
				if currentItem == focusLast then
					bottom = focusFirst;
				end;
				
				FocusManager:linkElements(element, FocusManager.TOP, currentPage[top]);
				FocusManager:linkElements(element, FocusManager.BOTTOM, currentPage[bottom]);
				
				-- log("DEBUG", "GUI: Page " .. self.draftPageIntToName[i] .. " - Linking setting " .. element.name .. " (" .. currentItem .. " / " .. element.focusId .. ") 	to setting " .. currentPage[top].name .. " (" .. top .. " / " .. currentPage[top].focusId .. ") 	and " .. currentPage[bottom].name .. " (".. bottom .. " / " .. currentPage[bottom].focusId .. ")");
			end;
		end;
	end;
	
	-- logTable(FocusManager.guiFocusData["gameExtensionGUI"].idToElementMapping, 0, "gameExtensionGUI.idToElementMapping.");
end;


function GameExtensionGUI:createPageElements(pageName, items)
	function getSetting(item, isMod)
		if not isMod then
			return g_gameExtension:getSetting(item.module, item.name, true);
		else
			return item;
		end;
	end;
	
	local currentSettings, currentRow, currentRowSetting, currentPageElement, currentFrameElement = 0, 0, 0;
	local numSettings, validItem, lastItem, lastTableIndex = 0, 0, 0, {};
	
	-- Create an last index table, per page for focus
	for i, item in ipairs(items) do
		local customSetting = item.variableName ~= nil;
		local s = getSetting(item, customSetting);
		
		if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL then
			numSettings = numSettings + 1;
			validItem = validItem + 1;
			lastItem = i;
			
			if validItem == GameExtensionGUI.SETTINGS_PER_PAGE then
				validItem = 0;
				lastTableIndex[lastItem] = lastItem;
			end;
		end;
	end;
	
	lastTableIndex[lastItem] = lastItem;
	
	log("DEBUG", "GUI: We have " .. numSettings .. " settings for page ( " .. pageName .. " )");
	
	-- Make sure we create the default pages otherwise we get problems with settings not showing..
	if numSettings == 0 then
		local NP = self:clonePage();
		return;
	end;
	
	for i, item in ipairs(items) do
		local isCustomSetting = item.variableName ~= nil;
		local s = getSetting(item, isCustomSetting);
		
		if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL then
			currentSettings = currentSettings + 1;
			currentRowSetting = currentRowSetting + 1;
			
			-- Create page
			if (currentSettings == 1 or currentSettings > GameExtensionGUI.SETTINGS_PER_PAGE) then
				currentSettings = 1;
				currentRow = 0;
				currentPageElement = self:clonePage();
			end;
			
			-- Create row frame
			if currentSettings == 1
			or currentSettings == GameExtensionGUI.SETTINGS_PER_LINE + 1
			or currentSettings == (GameExtensionGUI.SETTINGS_PER_LINE * 2) + 1 then
				currentFrameElement = self.settingRowTemplate:clone(currentPageElement);
				currentFrameElement:setVisible(true);
				currentRowSetting = 1;
				currentRow = currentRow + 1;
				
				local positionRowTable = {
					{0.00, 0}, -- X, Y
					{0.25, 0},
					{0.50, 0}
				};
				
				currentFrameElement:move(positionRowTable[currentRow][1], positionRowTable[currentRow][2]);
			end;
			
			local focusIdOffset = 10;
			local focusId = "GE_autoId_" .. focusIdOffset + ((self.currentPageNum - 1) * GameExtensionGUI.SETTINGS_PER_PAGE) + currentSettings; -- 10 is an offset focusId as 1 - 4 is being used in xml
			local currentItem = {};
			local b = -0.085;
			local positionTable = {
				{0, 0}, -- X, Y
				{0, b},
				{0, b * 2},
				{0, b * 3},
				{0, b * 4},
				{0, b * 5}
			};
			
			local translation = Utils.getNoNil(s.isMod, g_i18n);
			
			-- Create setting, show data
			if not isCustomSetting then
				value = s.value;
				
				currentItem.name = s.inputType:lower() .. "." .. item.module .. "." .. s.name; -- type.ModuleName.SettingName
				currentItem.toolTip = translation:getText("toolTip_" .. s.name);
				currentItem.text = translation:getText(s.name);
			else -- We are only making use of the GUI
				value = s.parent[s.variableName];
				
				currentItem.name = s.inputType:lower() .. "." .. pageName .. "." .. s.name; -- type.PageName.VariableName -- we don't use last one.
				currentItem.settingId = i;
				currentItem.toolTip = s.toolTip;
				currentItem.text = s.shownName;
			end;
			
			local newItem = self.settingItemTemplate:clone(currentFrameElement);
			newItem:move(positionTable[currentRowSetting][1], positionTable[currentRowSetting][2]); -- We are only required to move the last setting.. all other gets the correct position.
			newItem:setVisible(true);
			newItem:setDisabled(false, false);
			newItem.elements[4]:setText(currentItem.text);
			
			newItem.name = currentItem.name;
			newItem.isCustomSetting = isCustomSetting;
			newItem.settingId = currentItem.settingId;
			newItem.toolTip = currentItem.toolTip;
			
			if currentSettings == 1 then
				self.pages[self.currentPageNum][GameExtensionGUI.PAGES_FOCUS][GameExtensionGUI.PAGES_FOCUS_FIRST] = currentSettings;
			elseif lastTableIndex[i] ~= nil then
				self.pages[self.currentPageNum][GameExtensionGUI.PAGES_FOCUS][GameExtensionGUI.PAGES_FOCUS_LAST] = currentSettings;
			end;
			
			-- wasSuccessful is returning false for some reason...
			-- local wasSuccessful = FocusManager:loadElementFromCustomValues(newItem, focusId, {}, false, currentSettings == 1);
			
			-- Work around to make it work anyway..
			if not wasSuccessful then
				newItem.focusId = focusId;
				FocusManager.guiFocusData["gameExtensionGUI"].idToElementMapping[newItem.focusId] = newItem;
			end;
			
			table.insert(self.pages[self.currentPageNum][GameExtensionGUI.PAGES_SETTING], newItem);
			
			local temp = "GUI: ";
			temp = temp .. "focusId: " .. newItem.focusId;
			-- temp = temp .. ", expectedFocusId: " .. focusId;
			-- temp = temp .. ", loadElementWasSuccessful: " .. tostring(wasSuccessful);
			temp = temp .. ", name: " .. newItem.name;
			temp = temp .. ", currentSetting: " .. currentSettings;
			temp = temp .. ", currentRow: " .. currentRow;
			temp = temp .. ", currentPageNum: " .. self.currentPageNum;
			temp = temp .. ", canReceiveFocus: " .. tostring(newItem:canReceiveFocus());
			temp = temp .. ", getIsDisabled: " .. tostring(newItem:getIsDisabled());
			-- log("DEBUG", temp);
			-- logTable(newItem, 0, "newItem.")
			
			self:updateSettingElement(newItem, value, s);
		end;
	end;
end;

function GameExtensionGUI:clonePage()
	self.currentPageNum = Utils.getNoNil(self.currentPageNum, 0);
	self.currentPageNum = self.currentPageNum + 1;
	
	local clonedPage = self.pageTemplate:clone(self.mainPageElement);
	clonedPage:updateAbsolutePosition();
	clonedPage:setVisible(true);
	
	table.insert(self.pages, {clonedPage, {}, {0, 0}}); -- Page element, settings, first and last settingItem - See top for more
	
	return clonedPage;
end;


------------------------------------------------------------------------------------------------------------


-- Use for custom settings to load options for Float and Int settings
function GameExtensionGUI:getOptions(t)
	return g_gameExtension:getOptions(t);
end;

function GameExtensionGUI:getOptionsText(t)
	return g_gameExtension:getOptionsText(t);
end;

function GameExtensionGUI:getPage(name)
	return self.draftPages[name];
end;

function GameExtensionGUI:getSetting(pageName, name)
	pageName = pageName:lower();
	name = name:lower();
	
	if self.draftPages[pageName] ~= nil and self.settingNameToIndex[name] ~= nil then
		return self.draftPages[pageName].settings[self.settingNameToIndex[name]];
	end;
	
	return nil;
end;
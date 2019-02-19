--
-- GameExtensionMenu
-- 
-- Main menu to change settings
-- 
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- 

GameExtensionMenu = {
	SETTINGS_PER_PAGE 	= 18,
	SETTINGS_PER_LINE 	= 6,

	-- 1 = Page element
	-- 2 = Setting elements
	-- 3 = Focus data
	--		1 = Index to first setting
	--		2 = Index to last setting
	PAGES_PAGE 			= 1,
	PAGES_SETTING 		= 2,
	PAGES_FOCUS 		= 3,

	PAGES_FOCUS_FIRST 	= 1,
	PAGES_FOCUS_LAST 	= 2,
	
	CONTROLS			= {
		-- Header
		"pageSelector",
		"pageMarkerTemplate",
		
		-- Body
		"rootPage",
		"toolTipBox",
			-- Settings
			"pageSettingsTemplate",
			"settingTemplate",
			-- Login
			"pageLogin",
		-- Footer
		"buttonsPanel",
		"menuButton",
	}
};


-- Menu stuff

function GameExtensionMenu:loadMenu()
	g_gameExtension:addTextToGlobal("PAGE_LOGIN");
	
	g_gui:loadProfiles(FolderPaths.menu .. "GameExtensionProfiles.xml");
	g_gui:loadGui(FolderPaths.menu .. "GameExtensionMenu.xml", "GameExtensionMenu", g_gameExtensionMenu);
	
	local buttonStates  = {false, true, false, true, nil}; -- Up, Down, Always, Start Active, callbackState
	g_gameExtension:addInputAction("GameExtension_Menu", nil, InputAction.TOGGLE_GE_MENU, g_gameExtensionMenu, g_i18n:getText("TOGGLE_GE_MENU"), false, GameExtensionMenu.openMenu, M_Misc.callbackSetShowHelpButton, buttonStates);
end;

function GameExtensionMenu:canOpenMenu()
	if (self:getIsOpen() or not self.canOpen or g_currentMission.isSynchronizingWithPlayers) then
		return false;
	end;
	
	return true;
end;

function GameExtensionMenu:openMenu()
	if self:canOpenMenu() then
		self.inputDisableTime = 100; -- Page selection changed when using gamepad on open
		g_gui:showGui("GameExtensionMenu");
	end;
end;

function GameExtensionMenu:closeMenu()
	g_gui:showGui("");
end;


-- Input

function GameExtensionMenu:inputEvent(action, value, eventUsed)
	if self.inputDisableTime <= 0 then
		if action == InputAction.MENU_BACK then
			eventUsed = not self:closeMenu();
		end;
	end;

	return GameExtensionMenu:superClass().inputEvent(self, action, value, eventUsed);
end;

function GameExtensionMenu:inputEventSetting(oldFunc, action, value, eventUsed)
	if g_gameExtensionMenu.inputDisableTime <= 0 then
		return oldFunc(self, action, value, eventUsed);
	end;

	return eventUsed;
end;

function GameExtensionMenu:onGuiSetupFinished() -- Update menuButtons
	GameExtensionMenu:superClass().onGuiSetupFinished(self);
	
	-- Assign the buttons 
	local actions = {
		{inputAction = InputAction.MENU_BACK, callback = self.closeMenu, text = g_i18n:getText("button_back")} -- Back button
	};
	
	for i, v in ipairs(actions) do
		self.menuButton[i]:setVisible(true);
		self.menuButton[i]:setText(v.text);
		self.menuButton[i]:setInputAction(v.inputAction);
		self.menuButton[i].onClickCallback = v.callback;
	end;
end;

	
-- Main menu class

local GameExtensionMenu_mt = Class(GameExtensionMenu, ScreenElement);

function GameExtensionMenu:new(target)
	local self = ScreenElement:new(target, GameExtensionMenu_mt);
	
	self.canOpen = true;
	self.isLoaded = false;
	self.settingsAreInitialized = false;
	
	-- Store pages and settings before creating the elements
	self.pageData = {};
	self.pageDataIntToName = {};
	self.settingNameToIndex = {};
	
	self:addPage("client", g_i18n:getText("CLIENT_SETTING_PAGE"), false);
	self:addPage("server", g_i18n:getText("SERVER_SETTING_PAGE"), true);
	
	-- Page elements
	self.pages = {};
	self.pageMarkers = {};
	self.currentPage = 1;
	self.currentPageNum = 0;
	
	self.currentToolTip = {
		current 	= nil,
		selected 	= nil, -- Focused setting
		highlighted = nil  -- Highlighted setting, mouse hover 
	};

	self.menuButton = {};
	
	self:registerControls(GameExtensionMenu.CONTROLS);
	
	return self;
end;

function GameExtensionMenu:delete()
	GameExtensionMenu:superClass().delete(self);
	self:flushSettings();
	self:setIsLoaded(false);
end;

function GameExtensionMenu:update(dt)
	if self.currentToolTip.highlighted ~= nil then
		self:updateToolTip(self.currentToolTip.highlighted); -- Mouse over setting element
	elseif self.currentToolTip.selected ~= nil then
		self:updateToolTip(self.currentToolTip.selected);	 -- Selected setting element
	end;

	GameExtensionMenu:superClass().update(self, dt);
end;

function GameExtensionMenu:onOpen()
	if self:initializeSettings() then
		-- Update all setting elements since they could have changed
		for _, v in ipairs(self.pages) do
			for _, element in ipairs(v[GameExtensionMenu.PAGES_SETTING]) do
				self:setSettingValue(element);
			end;
		end;
	end;
	
	self:setPage(self.currentPage, false);
	g_depthOfFieldManager:setBlurState(true);
	GameExtensionMenu:superClass().onOpen(self); -- This handles the mouse cursor
end;

function GameExtensionMenu:onClose()
	GameExtensionMenu:superClass().onClose(self);
	g_depthOfFieldManager:setBlurState(false);
end;


-- Creating Elements

function GameExtensionMenu:initializeSettings()
	if self.settingsAreInitialized then return true; end;
	g_gameExtension:log("Debug Menu", "InitializeSettings()");
	
	-- Hide templates
	self:setElementVisible(self.pageSettingsTemplate, false);
	self:setElementVisible(self.settingTemplate, false);
	
	local pagesTitles = {};
	self.navigationIntToName = {};

	for i, name in pairs(self.pageDataIntToName) do
		local p = self.pageData[name];
		local numNeededPages = math.max(math.ceil(#p.settings / GameExtensionMenu.SETTINGS_PER_PAGE), 1);
		
		for k = 1, numNeededPages do
			table.insert(pagesTitles, p.pageName);
			table.insert(self.navigationIntToName, name);
		end;
	
		self:createPage(name, p.settings);
	end;
	
	if self.pageMarkerTemplate ~= nil then
		self.pageMarkerTemplate:setVisible(false); -- Need it on reload
		
		for i = 1, #pagesTitles, 1 do
			local marker = self.pageMarkerTemplate:clone(self.pageMarkerTemplate.parent);
			marker:setVisible(true);
			self.pageMarkers[i] = marker;
		end;
		
		self:centerElements(self.pageMarkers, self.pageMarkers[1].size[1] * 1);
	end;
	
	self.pageSelector:setTexts(pagesTitles);
	self:linkSettingsElements();
	self.settingsAreInitialized = true;
end;

function GameExtensionMenu:createPage(pageName, items)
	local numSettings, countToPageLimit, lastItem, lastTableIndex = 0, 0, 0, {};
	
	-- Create an last index table, per page for focus
	for i, item in ipairs(items) do
		local s = self:getSettingType(item, item.variableName ~= nil);
		
		if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL then
			numSettings = numSettings + 1;
			countToPageLimit = countToPageLimit + 1;
			lastItem = i;
			
			if countToPageLimit == GameExtensionMenu.SETTINGS_PER_PAGE then
				lastTableIndex[lastItem] = lastItem;
				countToPageLimit = 0;
			end;
		end;
	end;
	
	lastTableIndex[lastItem] = lastItem; -- We havent reached page limit, add last setting
	g_gameExtension:log("Debug Menu", "We have " .. numSettings .. " settings for page ( " .. pageName .. " )");
	
	if numSettings == 0 then
		self:clonePage(); -- Create page even if no settings
	else
		local currentSetting, currentPageElement = 0;
		
		for i, item in ipairs(items) do
			local isCustomSetting = item.variableName ~= nil;
			local s = self:getSettingType(item, isCustomSetting);
			local newItem;
			
			if g_gameExtension:getBlackListItem(s.name) == GameExtension.BL_STATE_NORMAL then
				currentSetting = currentSetting + 1;

				-- Create new page
				if (currentSetting == 1 or currentSetting > GameExtensionMenu.SETTINGS_PER_PAGE) then
					currentSetting = 1;
					currentPageElement = self:clonePage();
				end;

				if not isCustomSetting then
					local translation = Utils.getNoNil(s.isMod, g_i18n);
					newItem = self:createSetting(currentPageElement, s, s.inputType .. "." .. item.module .. "." .. s.name, translation:getText("toolTip_" .. s.name), translation:getText(s.name), s.value, isCustomSetting);
				else
					newItem = self:createSetting(currentPageElement, s, s.inputType .. "." .. pageName .. "." .. s.name, s.toolTip, s.shownName, s.parent[s.variableName], isCustomSetting, currentSetting);
				end;
				
				-- Update focus
				newItem.focusId = FocusManager.serveAutoFocusId();
				FocusManager.guiFocusData["GameExtensionMenu"].idToElementMapping[newItem.focusId] = newItem;
				
				table.insert(self.pages[self.currentPageNum][GameExtensionMenu.PAGES_SETTING], newItem); -- We are done add
			
				if currentSetting == 1 then
					self.pages[self.currentPageNum][GameExtensionMenu.PAGES_FOCUS][GameExtensionMenu.PAGES_FOCUS_FIRST] = currentSetting;
				elseif lastTableIndex[i] ~= nil then
					self.pages[self.currentPageNum][GameExtensionMenu.PAGES_FOCUS][GameExtensionMenu.PAGES_FOCUS_LAST] = currentSetting;
					
					-- Create dummy, saves us the hazzle of needing to position the last item
					newItem = self.settingTemplate:clone(currentPageElement.elements[1]):delete();
				end;
			end;
		end;
	end;
end;

function GameExtensionMenu:clonePage()
	self.currentPageNum = self.currentPageNum + 1;
	
	local clonedPage = self.pageSettingsTemplate:clone(self.rootPage);
	clonedPage:updateAbsolutePosition();
	-- clonedPage:setVisible(true);
	
	table.insert(self.pages, {clonedPage, {}, {0, 0}}); -- Page element, settings, first and last settingItem - See top for more
	
	return clonedPage;
end;

function GameExtensionMenu:linkSettingsElements()
	for i, v in ipairs(self.pages) do
		local settings = v[GameExtensionMenu.PAGES_SETTING];
		local focusFirst = v[GameExtensionMenu.PAGES_FOCUS][GameExtensionMenu.PAGES_FOCUS_FIRST];
		local focusLast = v[GameExtensionMenu.PAGES_FOCUS][GameExtensionMenu.PAGES_FOCUS_LAST];
		
		if #settings > 1 then
			for currentItem, element in ipairs(settings) do
				local top = currentItem - 1;
				local bottom = currentItem + 1;
				
				if currentItem == focusFirst then
					top = focusLast;
				end;
				
				if currentItem == focusLast then
					bottom = focusFirst;
				end;
				
				FocusManager:linkElements(element, FocusManager.TOP, settings[top]);
				FocusManager:linkElements(element, FocusManager.BOTTOM, settings[bottom]);
				
				-- g_gameExtension:log("Debug Menu", "Page " .. self.pageDataIntToName[i] .. " - Linking setting " .. element.name .. " (" .. currentItem .. " / " .. element.focusId .. ") 	to setting " .. settings[top].name .. " (" .. top .. " / " .. settings[top].focusId .. ") 	and " .. settings[bottom].name .. " (".. bottom .. " / " .. settings[bottom].focusId .. ")");
			end;
		end;
	end;
	
	-- logTable(FocusManager.guiFocusData["GameExtensionMenu"].idToElementMapping, 0, "GameExtensionMenu.idToElementMapping.");
end;


-- Page Handeling

GameExtensionMenu.PAGE_FORCE = nil;
GameExtensionMenu.PAGE_LOGIN = -1;
GameExtensionMenu.PAGE_HELP  = -2;

function GameExtensionMenu:onClickPageSelection(currentPage)
	self:setPage(currentPage, false);
end;

function GameExtensionMenu:onPagePrevious(arg1)
	local page = self:checkPageCount(self.currentPage - 1, 1, self:getPageCount());
	self:setPage(page, true);
end;

function GameExtensionMenu:onPageNext()
	local page = self:checkPageCount(self.currentPage + 1, self:getPageCount(), 1);
	self:setPage(page, true);
end;

function GameExtensionMenu:setPage(currentPage, buttonCall)
	-- We want it to display the page your on even if we are showing something else
	self.pageSelector:setState(currentPage);
	
	for i, marker in ipairs(self.pageMarkers) do
		if i == currentPage then
			marker:setOverlayState(GuiOverlay.STATE_SELECTED);
		else
			marker:setOverlayState(GuiOverlay.STATE_NORMAL);
		end;
	end;

	self.currentPage = currentPage; -- We need this intact for navigation

	-- Now we can fool the system...
	local page = self:getNavigationPageByInt(currentPage);
	if page.isAdminPage then
		if g_currentMission.missionDynamicInfo.isMultiplayer and not g_currentMission:getIsServer() then
			if not g_currentMission.isMasterUser then
				currentPage = GameExtensionMenu.PAGE_LOGIN;
			end;
		end;
	end;
	
	if GameExtensionMenu.PAGE_FORCE ~= nil then
		currentPage = GameExtensionMenu.PAGE_FORCE; -- For testing purposes
	end;
	
	for i, v in ipairs(self.pages) do
		v[GameExtensionMenu.PAGES_PAGE]:setVisible(i == currentPage);
	end;
	
	self.toolTipBox:setVisible(currentPage >= 1);
	self.pageLogin:setVisible(currentPage == GameExtensionMenu.PAGE_LOGIN);
	
	-- Focus
	if self.currentPage ~= currentPage then
		self.lastFocusedSetting = nil; -- New page, empty
	end;

	if currentPage >= 1 then
		local element = self.pages[currentPage][GameExtensionMenu.PAGES_SETTING][GameExtensionMenu.PAGES_FOCUS_FIRST];

		if self.lastFocusedSetting ~= nil then
			element = self.lastFocusedSetting;
		end;
		
		FocusManager:setFocus(element);
		element:setOverlayState(GuiOverlay.STATE_FOCUSED); -- Update the focus state
	end;
end;


-- Settings Handeling

-- Type.ModuleName.SettingName
-- Type.PageName.VariableName 	- Custom, Last one aren't used
GameExtensionMenu.SPLIT_TYPE 	= 1;
GameExtensionMenu.SPLIT_MODULE 	= 2;
GameExtensionMenu.SPLIT_SETTING = 3;

function GameExtensionMenu:onClickSetSettingElement(value, element)
	local res = StringUtil.splitString(".", element.name);
	
	if not element.isCustomSetting then
		value = self:getSettingElementValue(res[GameExtensionMenu.SPLIT_TYPE], g_gameExtension:getSetting(res[GameExtensionMenu.SPLIT_MODULE], res[GameExtensionMenu.SPLIT_SETTING], true), value);
		g_gameExtension:setSetting(res[GameExtensionMenu.SPLIT_MODULE], res[GameExtensionMenu.SPLIT_SETTING], value);
		
	else
		local s = self:getSettingByInt(res[GameExtensionMenu.SPLIT_MODULE], element.settingId);

		if s ~= nil then
			value = self:getSettingElementValue(res[GameExtensionMenu.SPLIT_TYPE], s, value);
			
			if s.func ~= nil then
				s.func(s.parent, value);
			else
				g_gameExtension:log("Notice", "Menu: Your trying to set an variable trough the menu which aren't supported, you should make sure to add an function callback to setting " .. element.name);
			end;
		else
			g_gameExtension:log("Error Menu", "Failed onClickSetSettingElement() - Setting id ( " .. tostring(element.settingId) .. " ), Page " .. tostring(res[GameExtensionMenu.SPLIT_MODULE]));
		end;
	end;
	
	-- g_gameExtension:log("Debug Menu", "Changing value: " .. tostring(value) .. " 	for ( " .. element.name .. " )");
end;

function GameExtensionMenu:setSettingValue(element, value, settings)
	local valueType = Types.BOOL;
	
	if value == nil then
		local res = StringUtil.splitString(".", element.name);
		valueType = res[GameExtensionMenu.SPLIT_TYPE];
		
		if not element.isCustomSetting then
			settings = g_gameExtension:getSetting(res[GameExtensionMenu.SPLIT_MODULE], res[GameExtensionMenu.SPLIT_SETTING], true);
			value = settings.value;
		else
			settings = self.pageData[res[GameExtensionMenu.SPLIT_MODULE]].settings[element.settingId];
			value = settings.parent[settings.variableName];
			
			if value == nil then
				g_gameExtension:log("Debug Menu", "setSettingValue() have an nil value for variable.");
			end;
		end;
	else
		valueType = settings.inputType;
	end;
	
	if valueType == Types.FLOAT or valueType == Types.INT then
		local row = 1;
		
		row = settings.options.rowToValue[value];
		element:setTexts(settings.options.rowToValue);
		element:setState(value, true);
	else
		local page = 1;
		if value then
			page = 2;
		end;
		
		element:setState(page, true);
	end;
	
	local lockState = g_gameExtension:getLockState(nil, nil, settings);
	element:setDisabled(lockState, false);
	
	-- g_gameExtension:log("Debug Menu", "Updating setting element for ( " .. element.name .. " ) to ( " .. tostring(value) .. " ) - lockState " .. tostring(lockState));
end;


-- ToolTip

function GameExtensionMenu:updateHelpText(element)
	self.currentToolTip.selected = element;
	self.lastFocusedSetting = element; -- Auto focus this setting on open
end;

function GameExtensionMenu:onHighlightSetting(oldfunc, element)
	if oldFunc ~= nil then oldFunc(self); end;
	g_gameExtensionMenu.currentToolTip.highlighted = self;
end;

function GameExtensionMenu:onHighlightRemoveSetting(oldfunc, element)
	if oldFunc ~= nil then oldFunc(self); end;
	g_gameExtensionMenu.currentToolTip.highlighted = nil;
end;

function GameExtensionMenu:updateToolTip(current)
	if self.currentToolTip.current ~= nil then
		if self.currentToolTip.current ~= current then
			self:setToolTip(current);
		end;
	else
		self:setToolTip(current);
	end;
end;

function GameExtensionMenu:setToolTip(current)
	self.currentToolTip.current = current;

	if current.toolTip ~= nil then
		self.toolTipBox.elements[2]:setText(current.toolTip);
	end;
end;
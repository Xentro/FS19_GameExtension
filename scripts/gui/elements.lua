--
-- GameExtensionGUI
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history		v1.0 - 2016-11-10 - Initial implementation
-- 

function GameExtensionGUI:centerElements(elements, offset)
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


-- Selection --
function GameExtensionGUI:onCreatePageSelection(element)
	self.pageSelectionElement = element;
end;

function GameExtensionGUI:onClickUpdatePageSelection(row)
	self.currentPage = row;
	
	self:updatePageSelection();
end;

function GameExtensionGUI:onCreateMarkerParent(element)
	self.pageMarkerParent = element;
end;

function GameExtensionGUI:onCreateMarkerTemplate(element)
	if self.pageMarkerTemplate == nil then
		self.pageMarkerTemplate = element;
	end;
end;


-- Setting Page
function GameExtensionGUI:onCreateMainPage(element)
	self.mainPageElement = element;
end;

function GameExtensionGUI:onCreatePageTemplate(element)
	if self.pageTemplate == nil then
		self.pageTemplate = element;
	end;
end;

function GameExtensionGUI:onCreateSettingTemplate(element)
	if self.settingRowTemplate == nil then
		self.settingRowTemplate = element;
	end;
end;

function GameExtensionGUI:onCreateSettingItem(element)
	if self.settingItemTemplate == nil then
		self.settingItemTemplate = element;
		self.settingItemTemplate.buttonLRChange = false;
		
		-- logTable(element, 0, "temp.");
		-- log("DEBUG", "");
		-- logTable(element, 1, "element.");
	end;
end;

function GameExtensionGUI:toggleCustomInputContextCallback(arg1)
	log("DEBUG", "toggleCustomInputContextCallback " .. tostring(arg1));
end;

function GameExtensionGUI:onFocusEnterSettingItem(element)
	if element.toolTip ~= nil then
		self.helpBoxElement:setVisible(true);
		self.helpBoxElement.elements[2]:setText(element.toolTip);
	end;
end;


-- Login Page
function GameExtensionGUI:onCreateLogin(element)
	self.loginElement = element;
	
	-- Temporary
	self.loginElement.elements[1]:setText(g_i18n:getText("PAGE_LOGIN"));
end;

function GameExtensionGUI:onClickLogin()
	-- if g_dedicatedServerInfo == nil and g_currentMission.missionDynamicInfo.isMultiplayer and not g_currentMission:getIsServer() then
		-- We could open the error dialog here instead of opening the password dialog
	-- else
		local dialog = g_gui:showDialog("PasswordDialog");
		dialog.target:setCallback(GameExtensionGUI.passwordCallback, self);
	-- end;
end;

function GameExtensionGUI:passwordCallback(password, login)
	if login then
		g_client:getServerConnection():sendEvent(GetAdminEvent:new(password));
	else
		g_gui:closeDialogByName("PasswordDialog");
	end;
end;


-- Help Page
function GameExtensionGUI:onCreatePageHelp(element)
	self.helpPageElement = element;
end;


-- Help Bar
function GameExtensionGUI:onCreateHelpBox(element)
	self.helpBoxElement = element;
end;


-- Button
function GameExtensionGUI:onCreateHelp(element)
	element.text = g_i18n:getText(element.text);
end;

function GameExtensionGUI:onClickBack()
	self:setReturnScreen("", "");
	
	GameExtensionGUI:superClass().onClickBack(self);
end;

function GameExtensionGUI:onClickHelp(element)
	if GameExtensionGUI.CURRENT_PAGE == GameExtensionGUI.PAGE_SETTINGS then
		GameExtensionGUI.CURRENT_PAGE = GameExtensionGUI.PAGE_HELP;
		element.text = g_i18n:getText("PAGE_SETTING");
	else
		GameExtensionGUI.CURRENT_PAGE = GameExtensionGUI.PAGE_SETTINGS;
		element.text = g_i18n:getText("PAGE_HELP");
	end;
	
	self:updatePageSelection();
end;


-- Exit GUI
function GameExtensionGUI:exitGUI()
	g_gui:showGui("");
end;


-- Dialog fix
local oldFunc = Gui.showDialog;
Gui.showDialog = function(self, name)
	local dialog = oldFunc(self, name);
	
	if name == "InfoDialog" and g_gameExtensionGUI ~= nil and g_gameExtensionGUI.isOpen then
		g_gui_CurrentDialog = dialog;
	end;
	
	return dialog;
end;

function GameExtensionGUI.onOK(self)
	g_gui:closeAllDialogs();
end;
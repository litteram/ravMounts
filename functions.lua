local name, ravMounts = ...
local L = ravMounts.L
local defaults = ravMounts.data.defaults
local mountTypes = ravMounts.data.mountTypes
local mountIDs = ravMounts.data.mountIDs
local mapIDs = ravMounts.data.mapIDs

local faction, _ = UnitFactionGroup("player")
local flyable, cloneMountID, mapID, inAhnQiraj, inVashjir, inMaw, haveGroundMounts, haveFlyingMounts, havePassengerGroundMounts, havePassengerFlyingMounts, haveVendorMounts, haveSwimmingMounts, haveAhnQirajMounts, haveVashjirMounts, haveMawMounts, haveChauffeurMounts, normalMountModifier, vendorMountModifier, passengerMountModifier, normalMountModifier, vendorMountModifier, passengerMountModifier
local prevControl
local dropdowns = {}
local mountModifiers = {
    "normalMountModifier",
    "vendorMountModifier",
    "passengerMountModifier",
}
local tooltipLabels = {
    ["vendor"] = L.Vendor,
    ["passengerGround"] = L.PassengerGround,
    ["passengerFlying"] = L.PassengerFlying,
    ["flex"] = L.Flex,
}

local function contains(table, input)
    for index, value in ipairs(table) do
        if value == input then
            return index
        end
    end
    return false
end

local function addLabelsFromSpell(target, spellID, showCloneable)
    if showCloneable == nil then showCloneable = true end
    local type, cloneable
    for mountType, label in pairs(tooltipLabels) do
        for _, mountID in ipairs(ravMounts.data.mountIDs[mountType]) do
            local _, lookup, _ = C_MountJournal.GetMountInfoByID(mountID)
            if tonumber(lookup) == tonumber(spellID) then
                type = label
                break
            end
        end
        if type then
            break
        end
    end
    if showCloneable then
        for _, mountID in ipairs(RAV_data.mounts.allByID) do
            local _, lookup, _ = C_MountJournal.GetMountInfoByID(mountID)
            if lookup == spellID then
                cloneable = true
                break
            end
        end
    end
    if type or (showCloneable and cloneable) then
        target:AddLine("|cff" .. ravMounts.color .. ravMounts.name .. ":|r " .. (type and type or "") .. ((type and showCloneable and cloneable) and ", " or "") .. ((showCloneable and cloneable) and L.Cloneable or ""), 1, 1, 1)
    end
    target:Show()
end

function ravMounts:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ravMounts.color .. ravMounts.name .. ":|r " .. message)
end

function ravMounts:SendVersion()
    local inInstance, _ = IsInInstance()
    if inInstance then
        C_ChatInfo.SendAddonMessage(name, RAV_version, "INSTANCE_CHAT")
    elseif IsInGroup() then
        if GetNumGroupMembers() > 5 then
            C_ChatInfo.SendAddonMessage(name, RAV_version, "RAID")
        end
        C_ChatInfo.SendAddonMessage(name, RAV_version, "PARTY")
    end
    local guildName, _, _, _ = GetGuildInfo("player")
    if guildName then
        C_ChatInfo.SendAddonMessage(name, RAV_version, "GUILD")
    end
end

function ravMounts:AssignVariables()
    flyable = ravMounts:IsFlyableArea()
    cloneMountID = ravMounts:GetCloneMount()
    mapID = C_Map.GetBestMapForUnit("player")
    inAhnQiraj = contains(mapIDs.ahnqiraj, mapID)
    inVashjir = contains(mapIDs.vashjir, mapID)
    inMaw = contains(mapIDs.maw, mapID)
    haveGroundMounts = next(RAV_data.mounts.ground) ~= nil and true or false
    haveFlyingMounts = next(RAV_data.mounts.flying) ~= nil and true or false
    havePassengerGroundMounts = next(RAV_data.mounts.passengerGround) ~= nil and true or false
    havePassengerFlyingMounts = next(RAV_data.mounts.passengerFlying) ~= nil and true or false
    haveVendorMounts = next(RAV_data.mounts.vendor) ~= nil and true or false
    haveSwimmingMounts = next(RAV_data.mounts.swimming) ~= nil and true or false
    haveAhnQirajMounts = next(RAV_data.mounts.ahnqiraj) ~= nil and true or false
    haveVashjirMounts = next(RAV_data.mounts.vashjir) ~= nil and true or false
    haveMawMounts = next(RAV_data.mounts.maw) ~= nil and true or false
    haveChauffeurMounts = next(RAV_data.mounts.chauffeur) ~= nil and true or false
    normalMountModifier = RAV_data.options.normalMountModifier == "alt" and IsAltKeyDown() or RAV_data.options.normalMountModifier == "ctrl" and IsControlKeyDown() or RAV_data.options.normalMountModifier == "shift" and IsShiftKeyDown() or false
    vendorMountModifier = RAV_data.options.vendorMountModifier == "alt" and IsAltKeyDown() or RAV_data.options.vendorMountModifier == "ctrl" and IsControlKeyDown() or RAV_data.options.vendorMountModifier == "shift" and IsShiftKeyDown() or false
    passengerMountModifier = RAV_data.options.passengerMountModifier == "alt" and IsAltKeyDown() or RAV_data.options.passengerMountModifier == "ctrl" and IsControlKeyDown() or RAV_data.options.passengerMountModifier == "shift" and IsShiftKeyDown() or false
end

function ravMounts:EnsureMacro()
    if not UnitAffectingCombat("player") and RAV_data.options.macro then
        ravMounts:AssignVariables()
        local flying = haveFlyingMounts and RAV_data.mounts.flying or nil
        local ground = (inAhnQiraj and haveAhnQirajMounts) and RAV_data.mounts.ahnqiraj or (inMaw and haveMawMounts) and RAV_data.mounts.maw or haveGroundMounts and RAV_data.mounts.ground or nil
        local vendor = haveVendorMounts and RAV_data.mounts.vendor or nil
        local passenger = (flyable and havePassengerFlyingMounts) and RAV_data.mounts.passengerFlying or havePassengerGroundMounts and RAV_data.mounts.passengerGround or nil
        local swimming = (inVashjir and haveVashjirMounts) and RAV_data.mounts.vashjir or haveSwimmingMounts and RAV_data.mounts.swimming or nil
        local body = "/" .. ravMounts.command
        if ground or flying or vendor or passenger or swimming then
            body = "\n" .. body
            if ground then
                local mountName, _ = C_MountJournal.GetMountInfoByID(ground[random(#ground)])
                body = mountName .. body
            end
            if flying then
                local mountName, _ = C_MountJournal.GetMountInfoByID(flying[random(#flying)])
                if ground then
                    if RAV_data.options.normalMountModifier ~= "none" then
                        body = "[swimming,flyable,mod:" .. RAV_data.options.normalMountModifier .. "][flyable,nomod:" .. RAV_data.options.normalMountModifier .. "][noflyable,mod:" .. RAV_data.options.normalMountModifier .. "] " .. mountName .. "; " .. body
                    else
                        body = "[flyable] " .. mountName .. "; " .. body
                    end
                else
                    body = mountName .. body
                end
            end
            if swimming then
                local mountName, _ = C_MountJournal.GetMountInfoByID(swimming[random(#swimming)])
                if RAV_data.options.normalMountModifier ~= "none" then
                    body = "[swimming,nomod:" .. RAV_data.options.normalMountModifier .. "] " .. mountName .. ((ground or flying) and "; " or "") .. body
                else
                    body = "[swimming] " .. mountName .. ((ground or flying) and "; " or "") .. body
                end
            end
            if vendor and RAV_data.options.vendorMountModifier ~= "none" then
                local mountName, _ = C_MountJournal.GetMountInfoByID(vendor[random(#vendor)])
                body = "[mod:" .. RAV_data.options.vendorMountModifier .. "] " .. mountName .. ((ground or flying or swimming) and "; " or "") .. body
            end
            if passenger and RAV_data.options.passengerMountModifier ~= "none" then
                local mountName, _ = C_MountJournal.GetMountInfoByID(passenger[random(#passenger)])
                body = "[mod:" .. RAV_data.options.passengerMountModifier .. "] " .. mountName .. ((ground or flying or swimming or vendor) and "; " or "") .. body
            end
            body = "#showtooltip " .. body
        end
        -- Max: 120 Global, 18 Character (so we'll make ours global)
        local numberOfMacros, _ = GetNumMacros()
        -- Edit if it exists, create if not
        if body == RAV_macroBody then
            -- Do nothing
        elseif GetMacroIndexByName(ravMounts.name) > 0 then
            EditMacro(GetMacroIndexByName(ravMounts.name), ravMounts.name, "INV_Misc_QuestionMark", body)
            RAV_macroBody = body
        elseif numberOfMacros < 120 then
            CreateMacro(ravMounts.name, "INV_Misc_QuestionMark", body)
            RAV_macroBody = body
        elseif not hasSeenNoSpaceMessage then
            -- This isn't saved to remind the player on each load
            hasSeenNoSpaceMessage = true
            ravMounts:PrettyPrint(L.NoMacroSpace)
        end
    end
end

function ravMounts:RegisterDefaultOption(key, value)
    if RAV_data.options[key] == nil then
        RAV_data.options[key] = value
    end
end

function ravMounts:SetDefaultOptions()
    if RAV_data == nil then
        RAV_data = {}
    end
    if RAV_data.options == nil then
        RAV_data.options = {}
    end
    if RAV_data.options.flexMounts == true or RAV_data.options.flexMounts == false then
        RAV_data.options.flexMounts = nil
    end
    for k, v in pairs(defaults) do
        ravMounts:RegisterDefaultOption(k, v)
    end
end

function ravMounts:RegisterControl(control, parentFrame)
    if (not parentFrame) or (not control) then
        return
    end
    parentFrame.controls = parentFrame.controls or {}
    table.insert(parentFrame.controls, control)
end

function ravMounts:CreateLabel(cfg)
    cfg.initialPoint = cfg.initialPoint or "TOPLEFT"
    cfg.relativePoint = cfg.relativePoint or "BOTTOMLEFT"
    cfg.offsetX = cfg.offsetX or 0
    cfg.offsetY = cfg.offsetY or -16
    cfg.relativeTo = cfg.relativeTo or prevControl
    cfg.fontObject = cfg.fontObject or "GameFontNormalLarge"

    local label = cfg.parent:CreateFontString(cfg.name, "ARTWORK", cfg.fontObject)
    label.label = cfg.label
    label.type = cfg.type
    label:SetPoint(cfg.initialPoint, cfg.relativeTo, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    if cfg.width then
        label:SetWidth(cfg.width)
    end
    if cfg.countMounts then
        label.countMounts = cfg.countMounts
        label:SetText(string.format(cfg.label, table.maxn(RAV_data.mounts[cfg.countMounts])))
    else
        label:SetText(cfg.label)
    end

    ravMounts:RegisterControl(label, cfg.parent)
    if not cfg.ignorePlacement then
        prevControl = label
    end
    return label
end

function ravMounts:CreateCheckBox(cfg)
    cfg.initialPoint = cfg.initialPoint or "TOPLEFT"
    cfg.relativePoint = cfg.relativePoint or "BOTTOMLEFT"
    cfg.offsetX = cfg.offsetX or 0
    cfg.offsetY = cfg.offsetY or -6
    cfg.relativeTo = cfg.relativeTo or prevControl

    local checkBox = CreateFrame("CheckButton", cfg.name, cfg.parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox.var = cfg.var
    checkBox.label = cfg.label
    checkBox.type = cfg.type
    checkBox:SetPoint(cfg.initialPoint, cfg.relativeTo, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    checkBox.Text:SetText(cfg.label)
    if cfg.tooltip then
        checkBox.tooltipText = cfg.tooltip
    end

    checkBox.GetValue = function(self)
        return checkBox:GetChecked()
    end
    checkBox.SetValue = function(self)
        checkBox:SetChecked(RAV_data.options[cfg.var])
    end

    checkBox:SetScript("OnClick", function(self)
        checkBox.value = self:GetChecked()
        RAV_data.options[checkBox.var] = checkBox:GetChecked()
        ravMounts:MountListHandler()
        ravMounts:EnsureMacro()
        ravMounts:RefreshControls(ravMounts.Options.controls)
    end)

    ravMounts:RegisterControl(checkBox, cfg.parent)
    if not cfg.ignorePlacement then
        prevControl = checkBox
    end
    return checkBox
end

function ravMounts:CreateDropDown(cfg)
    cfg.initialPoint = cfg.initialPoint or "TOPLEFT"
    cfg.relativePoint = cfg.relativePoint or "BOTTOMLEFT"
    cfg.offsetX = cfg.offsetX or 0
    cfg.offsetY = cfg.offsetY or -6
    cfg.relativeTo = cfg.relativeTo or prevControl
    cfg.width = cfg.width or 130

    dropdowns[cfg.var] = CreateFrame("Frame", cfg.name, cfg.parent, "UIDropDownMenuTemplate")
    dropdowns[cfg.var].var = cfg.var
    dropdowns[cfg.var].label = cfg.label
    dropdowns[cfg.var].type = cfg.type
    dropdowns[cfg.var]:SetPoint(cfg.initialPoint, cfg.relativeTo, cfg.relativePoint, cfg.offsetX, cfg.offsetY)
    UIDropDownMenu_SetWidth(dropdowns[cfg.var], cfg.width)
    UIDropDownMenu_SetText(dropdowns[cfg.var], cfg.label)
    UIDropDownMenu_Initialize(dropdowns[cfg.var], function(self)
        for _, value in ipairs(cfg.options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = value:gsub("^%l", string.upper)
            info.checked = RAV_data.options[cfg.var] == value and true or false
            if not info.checked and value ~= "none" and cfg.group == "mountModifier" then
                for _, mountModifier in ipairs(mountModifiers) do
                    if RAV_data.options[mountModifier] == value then
                        info.disabled = true
                    end
                end
            end
            info.func = function(option, arg1, arg2, checked)
                RAV_data.options[cfg.var] = option.value:lower()
                info.checked = true
                ravMounts:RefreshControls(ravMounts.Options.controls)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    ravMounts:RegisterControl(dropdowns[cfg.var], cfg.parent)
    if not cfg.ignorePlacement then
        prevControl = dropdowns[cfg.var]
    end
    return dropdowns[cfg.var]
end

function ravMounts:RefreshControls(controls)
    ravMounts:MountListHandler()
    ravMounts:EnsureMacro()
    for i, control in pairs(controls) do
        if control.type == "CheckBox" then
            control:SetValue(control)
            control.oldValue = control:GetValue()
        elseif control.type == "DropDown" then
            UIDropDownMenu_SetText(dropdowns[control.var], control.label .. ": " .. RAV_data.options[control.var]:gsub("^%l", string.upper))
        elseif control.countMounts then
            control:SetText(string.format(control.label, table.maxn(RAV_data.mounts[control.countMounts])))
            control.oldValue = control:GetText()
        end
    end
    CloseDropDownMenus()
end

function ravMounts:MountSummon(list)
    if not UnitAffectingCombat("player") and #list > 0 then
        local iter = 10 -- magic number (can random fail us so much?)
        local n = random(#list)
        while not select(5, C_MountJournal.GetMountInfoByID(list[n])) and iter > 0 do
            n = random(#list)
            iter = iter - 1
        end
        C_MountJournal.SummonByID(list[n])
    end
end

function ravMounts:GetCloneMount()
    local clone = UnitIsPlayer("target") and "target" or UnitIsPlayer("focus") and "focus" or false
    if clone then
        for buffIndex = 1, 40 do
            local mountIndex = contains(RAV_data.mounts.allByName, UnitBuff(clone, buffIndex))
            if mountIndex then
                return RAV_data.mounts.allByID[mountIndex]
            end
        end
    end
    return false
end

-- Collect Data and Sort it
function ravMounts:MountListHandler()
    -- Reset the mount data to be repopulated
    RAV_data.mounts = {}
    RAV_data.mounts.allByName = {}
    RAV_data.mounts.allByID = {}
    RAV_data.mounts.ground = {}
    RAV_data.mounts.flying = {}
    RAV_data.mounts.vendor = {}
    RAV_data.mounts.passengerGround = {}
    RAV_data.mounts.passengerFlying = {}
    RAV_data.mounts.swimming = {}
    RAV_data.mounts.ahnqiraj = {}
    RAV_data.mounts.vashjir = {}
    RAV_data.mounts.maw = {}
    RAV_data.mounts.chauffeur = {}
    -- Let's start looping over our Mount Journal adding Mounts to their
    -- respective groups
    for _, mountID in pairs(C_MountJournal.GetMountIDs()) do
        local mountName, spellID, _, _, isUsable, _, isFavorite, _, mountFaction, hiddenOnCharacter, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        local _, _, _, _, mountType = C_MountJournal.GetMountInfoExtraByID(mountID)
        local isGroundMount = contains(mountTypes.ground, mountType)
        local isFlyingMount = contains(mountTypes.flying, mountType)
        local isVendorMount = contains(mountIDs.vendor, mountID)
        local isPassengerGroundMount = contains(mountIDs.passengerGround, mountID)
        local isPassengerFlyingMount = contains(mountIDs.passengerFlying, mountID)
        local isSwimmingMount = contains(mountTypes.swimming, mountType)
        local isAhnQirajMount = contains(mountTypes.ahnqiraj, mountType)
        local isVashjirMount = contains(mountTypes.vashjir, mountType)
        local isMawMount = contains(mountIDs.maw, mountID)
        local isChauffeurMount = contains(mountTypes.chauffeur, mountType)
        local isFlexMount = contains(mountIDs.flex, mountID)
        if isCollected then
            -- 0 = Horde, 1 = Alliance
            -- Check for mismatch, means not available
            if mountFaction == 0 and faction ~= "Horde" then
                -- skip
            elseif mountFaction == 1 and faction ~= "Alliance" then
                -- skip
            else
                table.insert(RAV_data.mounts.allByName, mountName)
                table.insert(RAV_data.mounts.allByID, mountID)
                if isFlyingMount and (not RAV_data.options.normalMounts or isFavorite) and not isVendorMount and not isPassengerFlyingMount and not isPassengerGroundMount then
                    if isFlexMount then
                        if RAV_data.options.flexMounts == "both" or RAV_data.options.flexMounts == "ground" then
                            table.insert(RAV_data.mounts.ground, mountID)
                        end
                        if RAV_data.options.flexMounts == "both" or RAV_data.options.flexMounts == "flying" then
                            table.insert(RAV_data.mounts.flying, mountID)
                        end
                    else
                        table.insert(RAV_data.mounts.flying, mountID)
                    end
                end
                if isGroundMount and (isFavorite or not RAV_data.options.normalMounts) and not isVendorMount and not isPassengerFlyingMount and not isPassengerGroundMount then
                    table.insert(RAV_data.mounts.ground, mountID)
                end
                if isVendorMount and (isFavorite or not RAV_data.options.vendorMounts) then
                    table.insert(RAV_data.mounts.vendor, mountID)
                end
                if isPassengerFlyingMount and (isFavorite or not RAV_data.options.passengerMounts) then
                    table.insert(RAV_data.mounts.passengerFlying, mountID)
                end
                if isPassengerGroundMount and (isFavorite or not RAV_data.options.passengerMounts) then
                    table.insert(RAV_data.mounts.passengerGround, mountID)
                end
                if isSwimmingMount and (isFavorite or not RAV_data.options.swimmingMounts) then
                    table.insert(RAV_data.mounts.swimming, mountID)
                end
                if isChauffeurMount then
                    table.insert(RAV_data.mounts.chauffeur, mountID)
                end
                if isAhnQirajMount then
                    table.insert(RAV_data.mounts.ahnqiraj, mountID)
                end
                if isVashjirMount then
                    table.insert(RAV_data.mounts.vashjir, mountID)
                end
                if isMawMount then
                    table.insert(RAV_data.mounts.maw, mountID)
                end
            end
        end
    end
end

-- Check a plethora of conditions and choose the appropriate Mount from the
-- Mount Journal, and do nothing if conditions are not met
function ravMounts:MountUpHandler(specificType)
    if IsFlying() then
        return
    end
    ravMounts:AssignVariables()
    if (string.match(specificType, "vend") or string.match(specificType, "repair") or string.match(specificType, "trans") or string.match(specificType, "mog")) and haveVendorMounts then
        ravMounts:MountSummon(RAV_data.mounts.vendor)
    elseif (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and havePassengerFlyingMounts and flyable then
        ravMounts:MountSummon(RAV_data.mounts.passengerFlying)
    elseif string.match(specificType, "fly") and (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and havePassengerFlyingMounts then
        ravMounts:MountSummon(RAV_data.mounts.passengerFlying)
    elseif (string.match(specificType, "2") or string.match(specificType, "two") or string.match(specificType, "multi") or string.match(specificType, "passenger")) and havePassengerGroundMounts then
        ravMounts:MountSummon(RAV_data.mounts.passengerGround)
    elseif string.match(specificType, "swim") and haveSwimmingMounts then
        ravMounts:MountSummon(RAV_data.mounts.swimming)
    elseif (specificType == "vj" or string.match(specificType, "vash") or string.match(specificType, "jir")) and haveVashjirMounts then
        ravMounts:MountSummon(RAV_data.mounts.vashjir)
    elseif string.match(specificType, "fly") and haveFlyingMounts then
        ravMounts:MountSummon(RAV_data.mounts.flying)
    elseif (specificType == "aq" or string.match(specificType, "ahn") or string.match(specificType, "qiraj")) and haveAhnQirajMounts then
        ravMounts:MountSummon(RAV_data.mounts.ahnqiraj)
    elseif specificType == "ground" and haveGroundMounts then
        ravMounts:MountSummon(RAV_data.mounts.ground)
    elseif specificType == "chauffeur" and haveChauffeurMounts then
        ravMounts:MountSummon(RAV_data.mounts.chauffeur)
    elseif (specificType == "copy" or specificType == "clone" or RAV_data.options.clone) and cloneMountID then
        C_MountJournal.SummonByID(cloneMountID)
        return
    elseif vendorMountModifier and passengerMountModifier and (IsMounted() or UnitInVehicle("player")) then
        DoEmote(EMOTE171_TOKEN)
        return
    elseif IsMounted() or UnitInVehicle("player") then
        Dismount()
        VehicleExit()
        CancelShapeshiftForm()
        UIErrorsFrame:Clear()
        return
    elseif haveVendorMounts and vendorMountModifier then
        ravMounts:MountSummon(RAV_data.mounts.vendor)
    elseif havePassengerFlyingMounts and flyable and passengerMountModifier and not normalMountModifier then
        ravMounts:MountSummon(RAV_data.mounts.passengerFlying)
    elseif havePassengerGroundMounts and passengerMountModifier and (not flyable or (flyable and normalMountModifier)) then
        ravMounts:MountSummon(RAV_data.mounts.passengerGround)
    elseif haveVashjirMounts and IsSwimming() and not normalMountModifier and inVashjir then
        ravMounts:MountSummon(RAV_data.mounts.vashjir)
    elseif haveSwimmingMounts and IsSwimming() and not normalMountModifier then
        ravMounts:MountSummon(RAV_data.mounts.swimming)
    -- elseif haveFlyingMounts and ((flyable and not normalMountModifier and not IsSwimming()) or (not flyable and normalMountModifier)) then
    elseif haveFlyingMounts and ((IsSwimming() and flyable and normalMountModifier) or (flyable and not normalMountModifier) or (not flyable and normalMountModifier)) then
        ravMounts:MountSummon(RAV_data.mounts.flying)
    elseif inAhnQiraj and haveAhnQirajMounts then
        ravMounts:MountSummon(RAV_data.mounts.ahnqiraj)
    elseif inMaw and haveMawMounts then
        ravMounts:MountSummon(RAV_data.mounts.maw)
    elseif haveGroundMounts then
        ravMounts:MountSummon(RAV_data.mounts.ground)
    elseif haveFlyingMounts then
        ravMounts:MountSummon(RAV_data.mounts.flying)
    elseif haveChauffeurMounts then
        ravMounts:MountSummon(RAV_data.mounts.chauffeur)
    else
        ravMounts:PrettyPrint(L.NoMounts)
        return
    end
end

function ravMounts:TooltipLabels()
    hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
        local unit = select(1, ...)
        local spellID = select(10, UnitAura(...))
        if unit ~= "player" and spellID then
            addLabelsFromSpell(self, spellID)
        end
    end)

    hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
        local unit = select(1, ...)
        local spellID = select(10, UnitBuff(...))
        if unit ~= "player" and spellID then
            addLabelsFromSpell(self, spellID)
        end
    end)

    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if string.find(link, "^spell:") then
            local spellID, _ = strsplit(":", string.sub(link, 7))
            addLabelsFromSpell(ItemRefTooltip, spellID, false)
        end
    end)

    GameTooltip:HookScript("OnTooltipSetSpell", function(self)
        local spellID = select(2, self:GetSpell())
        if spellID then
            for i = 1, self:NumLines() do
                if string.match(_G["GameTooltipTextLeft"..i]:GetText(), ravMounts.name) then
                    return
                end
            end
            addLabelsFromSpell(self, spellID, false)
        end
    end)
end

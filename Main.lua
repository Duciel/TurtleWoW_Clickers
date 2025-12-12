Clickers = CreateFrame("Frame", "Clickers");
Clickers:RegisterEvent("ADDON_LOADED");
Clickers.main = {};

setmetatable(Clickers.main, {__index = getfenv(0)});
setfenv(1, Clickers.main);

cooldownTracker = {};
	
function Clickers.main:GetFrame()
    return Clickers;
end

function Clickers.main:GetEnv()
    return Clickers.main;
end

--- Function to check if a debuff is present on the unit
-- @param debuff				The debuff to check, can be either the ID, a list of ID, or the name of the icon
-- @param[opt="target"] unit	The unit to check the debuff (target, player ...)
-- @param[opt=1] debuffStack	The minimum number of stack to check, if no value passed, it will check if at least one stack is present
-- @return found				Boolean to tell if the debuff was found or not
function Clickers.main:FindDebuff(debuff, unit, debuffStack)
	if unit == nil then
		unit = "target";
	end

	if debuffStack == nil then
		debuffStack = 1;
	end
	
	local i = 1;
	local icon, stack, debuffType, id = UnitDebuff(unit, i);
	local type = type(debuff);
	
	while(icon ~= nil) do
		if (stack >= debuffStack) then
			if (type == "number") then
				if (debuff == id) then
					return true;
				end
			elseif (type == "string") then
				if (debuff == icon) then
					return true;
				end
			elseif (type == "table") then
				if (Clickers.main:Contains(debuff, id)) then
					return true;
				end
			end
		end

		i = i + 1;
		icon, stack, debuffType, id = UnitDebuff("target", i);

		if (icon == nil) then
			icon, stack, id = UnitBuff("target", i);
		end
	end
	
	return false;
end

--- Function to check if a buff is present on the unit
-- @param buff					The buff to check, can be either the ID, a list of ID, or the name of the icon
-- @param[opt="target"] unit	The unit to check the buff (target, player ...)
-- @param[opt=1] buffStack		The minimum number of stack to check, if no value passed, it will check if at least one stack is present
-- @return found				Boolean to tell if the buff was found or not
function Clickers.main:FindBuff(buff, unit, buffStack)
	if unit == nil then
		unit = "target";
	end

	if buffStack == nil then
		buffStack = 1;
	end

	local i = 1;
	local icon, stack, id = UnitBuff(unit, i);
	local type = type(buff);
	
	while(icon ~= nil) do
		if (stack >= buffStack) then
			if (type == "number") then
				if (buff == id) then
					return true;
				end
			elseif (type == "string") then
				if (buff == icon) then
					return true;
				end
			elseif (type == "table") then
				if (Clickers.main:Contains(buff, id)) then
					return true;
				end
			end
		end

		i = i + 1;
		icon, stack, id = UnitBuff(unit, i);
	end
	
	return false;
end

--- Function to check if a value is contained in a table
-- @param tab		he table containing all the values
-- @param val		The value to find in the table
-- @return found	Boolean to tell if the value was found or not
function Clickers.main:Contains(tab, val)
	for i, value in ipairs(tab) do
		if value == val then
			return true;
		end
	end

	return false;
end

--- Function to get the ID of a spell
-- @param name						name of the spell
-- @booktype [opt=BOOKTYPE_SPELL]	where to look for the spell, default player spell book
-- @return id						ID of the spell
function Clickers.main:GetSpellID(name, booktype)
	if booktype == nil then
		booktype = BOOKTYPE_SPELL;
	end
	
	local i = 1;
	local spellName, spellRank = GetSpellName(i, booktype);

	while (spellName ~= nil) do
		if (spellName == name) then
			return i;
		else
			i = i + 1;
			spellName, spellRank = GetSpellName(i, booktype);
		end
	end
end

function Clickers.main:SplitRankFromSpell(spell)
	local spellName = string.gsub(spell, "%(Rank %d+%)", "");
	local spellRank = 1;
	
	return spellName, spellRank;
end

--- Function to get the Cooldown from a spell
-- @param name						name of the spell
-- @booktype [opt=BOOKTYPE_SPELL]	where to look for the spell, default player spell book
-- @return cooldown					Return the cooldown of the spell (not the remaining cooldown, 0 if spell is ready)
function Clickers.main:GetSpellCooldownByName(spell, booktype)
	if booktype == nil then
		booktype = BOOKTYPE_SPELL;
	end
	
	spellName = Clickers.main:SplitRankFromSpell(spell);

	local spellID = Clickers.main:GetSpellID(spellName);
	local StartTime, Duration, Enable = GetSpellCooldown(spellID, booktype);
	return Duration;
end

function Clickers.main:GetItemCooldown(item)
	local bag, slot = Clickers.main:FindItem(item);

	local StartTime, Duration, Enable = GetContainerItemCooldown(bag, slot);
	return Duration;
end

--- Function to get the Cooldown from a spell
-- @param name						name of the spell
-- @booktype [opt=BOOKTYPE_SPELL]	where to look for the spell, default player spell book
-- @return cooldown					Return the cooldown of the spell (not the remaining cooldown, 0 if spell is ready)
function Clickers.main:SpellCast(spell, unit, rank)
	if unit == nil then
		unit = "target";
	end
	
	if rank ~= nil then
		spell = spell .. "(Rank " .. rank .. ")";
	end
	
	if Clickers.main:FindDebuff(28431, "player") then -- Poison Charge
		Clickers.main:UseBagItem(3386) -- Elixir of Poison Resistance
	end
	
	--local spellName, spellRank = Clickers.main:SplitRankFromSpell(spell);
	
	--print("Spell : " .. spellName);
	--print("Rank : " .. spellRank);
	
	--local spellData = TheoryCraft_GetSpellDataByName(spellName, spellRank);
	
	--print("Cost : " .. spellData.basemanacost);

	if Clickers.main:GetSpellCooldownByName(spell) == 0 then
		CastSpellByName(spell, unit);
		if not(Clickers.main:GetSpellCooldownByName(spell) == 0) then
			cooldownTracker[spell] = GetTime();
		end
	end
end

function Clickers.main:TrinketAndCast(spell, unit, trinket1, trinket2)
	if trinket1 == nil then
		trinket1 = true;
	end
	if trinket2 == nil then
		trinket2 = true;
	end
	
	local remainingCooldown, totalCooldown, hasCooldown;

	if trinket1 then
		remainingCooldown, totalCooldown, hasCooldown = GetInventoryItemCooldown(unit, 13);
		if hasCooldown == 1 and remainingCooldown == 0 then
			UseInventoryItem(13);
		end
	end

	if trinket2 then
		remainingCooldown, totalCooldown, hasCooldown = GetInventoryItemCooldown(unit, 14);
		if hasCooldown == 1 and remainingCooldown == 0 then
			UseInventoryItem(14);
		end
	end
	
	Clickers.main:SpellCast(spell, unit);
end

function Clickers.main:UseBagItem(item, self)
	local bag, slot = Clickers.main:FindItem(item);
	UseContainerItem(bag, slot, self);
end

function Clickers.main:IsNotClipping(spell, threshold)
	if threshold == nil then
		threshold = 1.2;
	end
		
	local spellTime = Clickers.main.cooldownTracker[spell];
	if spellTime == nil then
		spellTime = 0;
	end
	
	if spellTime + Clickers.main:GetSpellCooldownByName(spell) - GetTime() > threshold then
		return true;
	else
		return false;
	end
end

function Clickers.main:FindItem(item)
	local type = type(item);
	local bag = 0;
	while (bag < 5) do
		local slot = 1;
		local maxSlot = GetContainerNumSlots(bag);
		while (slot <= maxSlot) do
			itemLink = GetContainerItemLink(bag, slot);
			if itemLink then
				_, _, id = Clickers.main:SplitHyperlink(itemLink);
				if (type == "number" and item == id) then
					return bag, slot;
				else
					name = GetItemInfo(id);
					if (type == "string" and item == name) then
						return bag, slot;
					end
				end
			end
			slot = slot + 1;
		end
		bag = bag + 1;
	end
end

function Clickers.main:EquipItem(item, slot)
	if not(CursorHasItem()) then
		local bag, slot = Clickers.main:FindItem(item);
		PickupContainerItem(bag, slot);
		EquipCursorItem(slot);
	end
end

function Clickers.main:SplitHyperlink(link)
	local _, _, color, object = string.find(link, "|cff(%x*)|(.*)")
	--Clickers.debug:print("color : "..color)
	--Clickers.debug:print("object : "..object)
	local _, _, objectType, id, a, b, c, d = string.find(object, "H([^:]*):?(%d+):?(%d*):?(%d*):?(%d*)(.*)")
	--Clickers.debug:print("type : "..objectType)
	--Clickers.debug:print("ID : "..id)
	--Clickers.debug:print("a : "..a)
	--Clickers.debug:print("b : "..b)
	--Clickers.debug:print("c : "..c)
	--Clickers.debug:print("d : "..d)
	
	return color, objectType, tonumber(id);
end

function Clickers.main:CheckHP(unit)
	if unit == nil then
		unit = "target"
	end

	return UnitHealth(unit) / UnitHealthMax(unit) * 100;
end

function Clickers.main:CheckMana(unit)
	if unit == nil then
		unit = "target"
	end

	return UnitMana(unit) / UnitManaMax(unit) * 100;
end

function Clickers.main:IsInBossCombat()
	local bossEncounters = {
		["Tower of Karazhan"] = {
			"", --Keeper Gnarlmoon
			"Ley",
			"Anomalus",
			"Medivh",
			"Chess"
		},
		["The Rock of Desolation"] = {
			"Sandal",
			"Rupturan",
			"Kruul",
			"Mephi"
		},
		["Naxxramas"] = {},
		["Ahn'Qiraj"] = {},
		["Blackwing Lair"] = {},
		["Molten Core"] = {},
		["Blackrock Spire"] = {
			"0xF1300023890D79EC" --Scarshield Legionnaire on the left
		},
	};
	
	local zone = GetRealZoneText();
	
	for i, boss in ipairs(bossEncounters[zone]) do
		if UnitAffectingCombat(boss) then
			return true;
		end
	end
	
	return false;
end
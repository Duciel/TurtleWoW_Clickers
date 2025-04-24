Duciel = CreateFrame("Frame", "Duciel");
Duciel:RegisterEvent("ADDON_LOADED");
Duciel.main = {};

setmetatable(Duciel.main, {__index = getfenv(0)});
setfenv(1, Duciel.main);

cooldownTracker = {};
	
function Duciel.main:GetFrame()
    return Duciel;
end

function Duciel.main:GetEnv()
    return Duciel.main;
end

--- Function to check if a debuff is present on the unit
-- @param debuff				The debuff to check, can be either the ID, a list of ID, or the name of the icon
-- @param[opt="target"] unit	The unit to check the debuff (target, player ...)
-- @param[opt=1] debuffStack	The minimum number of stack to check, if no value passed, it will check if at least one stack is present
-- @return found				Boolean to tell if the debuff was found or not
function Duciel.main:FindDebuff(debuff, unit, debuffStack)
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
				if (Duciel.main:Contains(debuff, id)) then
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
function Duciel.main:FindBuff(buff, unit, buffStack)
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
				if (Duciel.main:Contains(buff, id)) then
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
function Duciel.main:Contains(tab, val)
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
function Duciel.main:GetSpellID(name, booktype)
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

function Duciel.main:SplitRankFromSpell(spell)
	local spellName = string.gsub(spell, "%(Rank %d+%)", "");
	local spellRank = 1;
	
	return spellName, spellRank;
end

--- Function to get the Cooldown from a spell
-- @param name						name of the spell
-- @booktype [opt=BOOKTYPE_SPELL]	where to look for the spell, default player spell book
-- @return cooldown					Return the cooldown of the spell (not the remaining cooldown, 0 if spell is ready)
function Duciel.main:GetSpellCooldownByName(spell, booktype)
	if booktype == nil then
		booktype = BOOKTYPE_SPELL;
	end
	
	spellName = Duciel.main:SplitRankFromSpell(spell);

	local spellID = Duciel.main:GetSpellID(spellName);
	local StartTime, Duration, Enable = GetSpellCooldown(spellID, booktype);
	return Duration;
end

function Duciel.main:GetItemCooldown(item)
	local bag, slot = Duciel.main:FindItem(item);

	local StartTime, Duration, Enable = GetContainerItemCooldown(bag, slot);
	return Duration;
end

--- Function to get the Cooldown from a spell
-- @param name						name of the spell
-- @booktype [opt=BOOKTYPE_SPELL]	where to look for the spell, default player spell book
-- @return cooldown					Return the cooldown of the spell (not the remaining cooldown, 0 if spell is ready)
function Duciel.main:SpellCast(spell, unit, rank)
	if unit == nil then
		unit = "target";
	end
	
	if rank ~= nil then
		spell = spell .. "(Rank " .. rank .. ")";
	end
	
	if Duciel.main:FindDebuff(28431, "player") then -- Poison Charge
		Duciel.main:UseBagItem(3386) -- Elixir of Poison Resistance
	end
	
	--local spellName, spellRank = Duciel.main:SplitRankFromSpell(spell);
	
	--print("Spell : " .. spellName);
	--print("Rank : " .. spellRank);
	
	--local spellData = TheoryCraft_GetSpellDataByName(spellName, spellRank);
	
	--print("Cost : " .. spellData.basemanacost);

	if Duciel.main:GetSpellCooldownByName(spell) == 0 then
		CastSpellByName(spell, unit);
		if not(Duciel.main:GetSpellCooldownByName(spell) == 0) then
			cooldownTracker[spell] = GetTime();
		end
	end
end

function Duciel.main:TrinketAndCast(spell, unit, trinket1, trinket2)
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
	
	Duciel.main:SpellCast(spell, unit);
end

function Duciel.main:UseBagItem(item, self)
	local bag, slot = Duciel.main:FindItem(item);
	UseContainerItem(bag, slot, self);
end

function Duciel.main:IsNotClipping(spell, threshold)
	if threshold == nil then
		threshold = 1.2;
	end
		
	local spellTime = Duciel.main.cooldownTracker[spell];
	if spellTime == nil then
		spellTime = 0;
	end
	
	if spellTime + Duciel.main:GetSpellCooldownByName(spell) - GetTime() > threshold then
		return true;
	else
		return false;
	end
end

function Duciel.main:FindItem(item)
	local type = type(item);
	local bag = 0;
	while (bag < 5) do
		local slot = 1;
		local maxSlot = GetContainerNumSlots(bag);
		while (slot <= maxSlot) do
			itemLink = GetContainerItemLink(bag, slot);
			if itemLink then
				_, _, id = Duciel.main:SplitHyperlink(itemLink);
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

function Duciel.main:EquipItem(item, slot)
	if not(CursorHasItem()) then
		local bag, slot = Duciel.main:FindItem(item);
		PickupContainerItem(bag, slot);
		EquipCursorItem(slot);
	end
end

function Duciel.main:SplitHyperlink(link)
	local _, _, color, object = string.find(link, "|cff(%x*)|(.*)")
	--Duciel.debug:print("color : "..color)
	--Duciel.debug:print("object : "..object)
	local _, _, objectType, id, a, b, c, d = string.find(object, "H([^:]*):?(%d+):?(%d*):?(%d*):?(%d*)(.*)")
	--Duciel.debug:print("type : "..objectType)
	--Duciel.debug:print("ID : "..id)
	--Duciel.debug:print("a : "..a)
	--Duciel.debug:print("b : "..b)
	--Duciel.debug:print("c : "..c)
	--Duciel.debug:print("d : "..d)
	
	return color, objectType, tonumber(id);
end

function Duciel.main:CheckHP(unit)
	if unit == nil then
		unit = "target"
	end

	return UnitHealth(unit) / UnitHealthMax(unit) * 100;
end

function Duciel.main:CheckMana(unit)
	if unit == nil then
		unit = "target"
	end

	return UnitMana(unit) / UnitManaMax(unit) * 100;
end
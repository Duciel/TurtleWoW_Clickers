Clickers = Clickers.main:GetFrame();
Clickers.buffTracker = {};

setmetatable(Clickers.buffTracker, {__index = getfenv(0)});
setfenv(1, getfenv(0));

function Clickers.buffTracker:CheckRaidConsumes()
	--if IsRaidOfficer() == 1 then
		nb = GetNumRaidMembers();
		
		if nb > 0 then
			for i = 1, nb do
				unit = "raid"..i;
				Clickers.buffTracker:CheckConsumes(unit);
			end
		end
	--end
end

function Clickers.buffTracker:CheckConsumes(unit)
	if unit == nil or unit == "" then
		unit = "target";
	end
	
	local log = "CHECK_BUFFS: " .. UnitName(unit) .. " --> ";
	
	local i = 1;
	local _, stack, id = UnitBuff(unit, i);
	
	while(id ~= nil) do
		log = log .. i .. " : " .. id .. " (" .. stack .. ") | ";
		i = i + 1;
		_, stack, id = UnitBuff(unit, i);
	end
	
	if i > 32 then
		log = log .. "Buff cap reached";
	end
	
	CombatLogAdd(log);
end

Clickers:RegisterEvent("PLAYER_REGEN_DISABLED");

Clickers:SetScript("OnEvent", function()
	if event == "PLAYER_REGEN_DISABLED" then
		--if Clickers.main:IsInBossCombat() then
			Clickers.buffTracker:CheckRaidConsumes();
		--end
	end
end)
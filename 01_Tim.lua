--//UNLESS SPECIFIED OTHERWISE, DO NOT EDIT THIS SCRIPT. HOWEVER YOU MAY MODIFY IT AT YOUR OWN RISK OF BREAKING IT

--//ToDo:

--//debug stuff removen
--// -> Units Recruitbar machen
--// -> Tileblocker schutz vor units dem vision building und der barracks geben
--// -> wenn barracks gar nicht geht dann mit zierobjekten

--// ->> AM ENDE: ALLE VARIABLEN MIT GETTER UND SETTER VERSEHEN
--//Alle nutzbaren funktionen für den user auflisten


--//---------------------------------------------------------------
--//-------------------GLOBAL VARIABLES----------------------------
--//---------------------------------------------------------------

MSG_ERR_WARRIOR_LIB = "WarriorsLib not found. Can not run script.";
MSG_OK_LOAD = "WarriorsLib found, script ready. GLHF!";
MSG_ERR_BARRACKS_TOO_MANY = "You can have one recruitment interface only.";
MSG_ERR_BARRACKS_CANT_BUILD = "You can not build your recruitment interface here.";
MSG_TEMPLE_IN_RANGE = "A Dark Temple or Fortress is in too close proximity.";
MSG_BUILDING_IN_RANGE = "A Mushroom Farm, Dark Temple or Fortress is in too close proximity.";
MSG_MUSHROOMFARM_NOMANA = "not enough mana for this Mushroom Farm.";
MSG_MUSHROOMFARM_BLOCKED = "Entities are tileblocking this Mushroom Farm.";
MSG_MUSHROOMFARM_DISABLED = "Mushroom Farms are disabled.";
MSG_DARKTEMPLE_NOMANA = "not enough mana for this Dark Temple.";
MSG_DARKTEMPLE_BLOCKED = "Entities are tileblocking this Dark Temple.";
MSG_DARKTEMPLE_DISABLED = "Dark Temples are disabled.";
MSG_FORTRESS_NOMANA = "not enough mana for this Fortress.";
MSG_FORTRESS_BLOCKED = "Entities are tileblocking this Fortress.";
MSG_FORTRESS_DISABLED  = "Fotresses are disabled.";

ENUM_MILITARY = {Settlers.SWORDSMAN_01, Settlers.SWORDSMAN_02, Settlers.SWORDSMAN_03, Settlers.BOWMAN_01, Settlers.BOWMAN_02, Settlers.BOWMAN_03, Settlers.MEDIC_01, Settlers.MEDIC_02, Settlers.MEDIC_03, Settlers.AXEWARRIOR_01, Settlers.AXEWARRIOR_02, Settlers.AXEWARRIOR_03, Settlers.BLOWGUNWARRIOR_01, Settlers.BLOWGUNWARRIOR_02, Settlers.BLOWGUNWARRIOR_03, Settlers.BACKPACKCATAPULTIST_01, Settlers.BACKPACKCATAPULTIST_02, Settlers.BACKPACKCATAPULTIST_03, Settlers.PRIEST, Settlers.SQUADLEADER}
ENUM_BUILDINGS = {Buildings.WOODCUTTERHUT, Buildings.STONECUTTERHUT, Buildings.SAWMILL, Buildings.FORESTERHUT, Buildings.RESIDENCESMALL, Buildings.RESIDENCEMEDIUM, Buildings.RESIDENCEBIG, Buildings.STONEMINE, Buildings.COALMINE, Buildings.IRONMINE, Buildings.GOLDMINE, Buildings.SULFURMINE, Buildings.SMELTIRON, Buildings.SMELTGOLD, Buildings.TOOLSMITH, Buildings.WEAPONSMITH, Buildings.GRAINFARM, Buildings.ANIMALRANCH, Buildings.MILL, Buildings.BAKERY, Buildings.SLAUGHTERHOUSE, Buildings.FISHERHUT, Buildings.HUNTERHUT, Buildings.WATERWORKHUT, Buildings.VINYARD, Buildings.STORAGEAREA, Buildings.MARKETPLACE, Buildings.DONKEYRANCH, Buildings.PORT, Buildings.SHIPYARD, Buildings.BIGTEMPLE, Buildings.SMALLTEMPLE, Buildings.EYECATCHER01, Buildings.EYECATCHER02, Buildings.EYECATCHER03, Buildings.EYECATCHER04, Buildings.EYECATCHER05, Buildings.EYECATCHER06, Buildings.EYECATCHER07, Buildings.EYECATCHER08, Buildings.EYECATCHER09, Buildings.EYECATCHER10, Buildings.EYECATCHER11, Buildings.EYECATCHER12, Buildings.BARRACKS, Buildings.GUARDTOWERSMALL, Buildings.GUARDTOWERBIG, Buildings.LOOKOUTTOWER, Buildings.CASTLE, Buildings.AMMOMAKERHUT, Buildings.HEALERHUT, Buildings.VEHICLEHALL}

CustomAI = {0, 0, 0, 0, 0, 0, 0, 0}

bEnabledGardenerUsage = {0, 0, 0, 0, 0, 0, 0, 0}
bEnabledPriestsUsage = {0, 0, 0, 0, 0, 0, 0, 0}

--//Gardener Recruit Variables
iTimeGardenerRecruit = Game.Time();
iDelayGardenerRecruit = 15;
iIntervallGardenerRecruit = 5;
iLimitGardenerRecruit = 100;
iAmountGardenerRecruit = 5;

--//Gardener Attack Variables
iTimeGardenerAttack = Game.Time();
iDelayGardenerAttack = 30;
iIntervallGardenerAttack = 15;

--//Priest Attack Variables
iTimePriestsAttack = Game.Time();
bEnabledPriestsAttack = 0;
iDeltaTimePriestsAttack = 0;
iDelayPriestsAttack = 45;
iIntervallPriestsAttack = 20;
iCostPriestsAttack = 20;

--//Player Mushroom Farm Variables
bEnabledMushroomFarmPlayer = 1;
iCostMushroomFarmPlayer = 60;

--//Player Dark Temple Variables
bEnabledDarkTemplePlayer = 1;
iCostDarkTemplePlayer = 1000;

--//Player Fortress Variables
bEnabledFortressPlayer = 1;
iCostFortressPlayer = 2000;

--//---------------------------------------------------------------
--//-------------------AUXILLARY FUNCTIONS-------------------------
--//---------------------------------------------------------------

function ForceWarriorsLib()
	dbg.stm(MSG_ERR_WARRIOR_LIB);
	Game.PlayerLost(Game.LocalPlayer());
	Game.DefaultGameEndCheck();
end

function sizeof(T)
	local i = 0;
	while(T[i+1] ~= nil) do
		i = i + 1;
	end

	return i;
end

function SearchBuilding(i, oBuildingType, oBuildingState)
	local x = -1;
	local y = -1;

	if Buildings.Amount (i, oBuildingType, oBuildingState) > 0 then
		while Buildings.ExistsBuildingInArea(i, oBuildingType, x, y, 1, oBuildingState) == 0 and y <= Map.Height() do
			y = y + 2;

			while Buildings.ExistsBuildingInArea(i, oBuildingType, x, y, 1, oBuildingState) == 0 and x <= Map.Width() do
				x = x + 1;
			end

			if Buildings.ExistsBuildingInArea(i, oBuildingType, x, y, 5, oBuildingState) == 0 then
				x = 0;
			end
		end
	end

	local obj = {x, y};
	return obj;
end

--//---------------------------------------------------------------
--//-------------------AI BEHAVIOR FUNCTIONS-----------------------
--//---------------------------------------------------------------

function cbUseSoldiers(party, x, y)
	local i = 1;
	while(i <= sizeof(ENUM_MILITARY)) do
		local entities = WarriorsLib.SelectWarriors(Map.Height() / 2,  Map.Width() / 2, (Map.Height() / 4) + (Map.Width() / 4), party, ENUM_MILITARY[i]);

		if (entities ~= nil) then
			WarriorsLib.Send(entities, x, y, WarriorsLib.MOVE_FORWARDS); 
		end

		i = i + 1;
	end
end

function cbRecruitGardeners()
	if ((Game.Time() >= iDelayGardenerRecruit) and (iTimeGardenerRecruit + iIntervallGardenerRecruit <= Game.Time())) then
		iTimeGardenerRecruit = Game.Time();
		
		local i = 1;
		while(i <= Game.NumberOfPlayers()) do
			if ((CustomAI[i] == 1) and (Game.HasPlayerLost(i) ~= 1)) then
				if (bEnabledGardenerUsage[i] == 1) then
					if (Buildings.Amount(i, Buildings.TOOLSMITH, Buildings.READY) > 0) then
						local obj = SearchBuilding(i, Buildings.TOOLSMITH, Buildings.READY);

						if ((obj[1] ~= -1) and (obj[2] ~= -1)) then
							local threshold = iLimitGardenerRecruit - Settlers.Amount(i, Settlers.GARDENER);

							if (threshold >= iAmountGardenerRecruit) then
								Settlers.AddSettlers(obj[1], obj[2], i, Settlers.GARDENER, iAmountGardenerRecruit);
							else
								Settlers.AddSettlers(obj[1], obj[2], i, Settlers.GARDENER, threshold);
							end
						end
					end
				end
			end

			i = i + 1;
		end
	end
end

function cbUseGardeners()
	if ((Game.Time() >= iDelayGardenerAttack) and (iTimeGardenerAttack + iIntervallGardenerAttack <= Game.Time())) then
		iTimeGardenerAttack = Game.Time();
		
		local i = 1;
		while(i <= Game.NumberOfPlayers()) do
			if ((CustomAI[i] == 1) and (Game.HasPlayerLost(i) ~= 1)) then
				if (bEnabledGardenerUsage[i] == 1) then
					if (Settlers.Amount(i, Settlers.GARDENER) > 0) then
						if (Game.Random(2) == 1) then
							local gardeners = WarriorsLib.SelectWarriors(Map.Height() / 2,  Map.Width() / 2, (Map.Height() / 4) + (Map.Width() / 4), i, Settlers.GARDENER);
							
							if (gardeners ~= nil) then
								local area = {Game.Random(Map.Height() / 2)+1, Game.Random(Map.Width() / 2)+1};
								
								if ((Game.IsAreaDarkLand(area[1], area[2], 1) == 1) and (Game.IsAreaOwned(i, area[1], area[1], 1) == 1)) then
									WarriorsLib.Send(gardeners, area[1], area[2], WarriorsLib.MOVE_FORWARDS);
									cbUseSoldiers(i, area[1], area[2]);
								elseif (Buildings.Amount(Game.LocalPlayer(), Buildings.MUSHROOMFARM, Buildings.READY) > 0) then
									local obj = SearchBuilding(Game.LocalPlayer(), Buildings.MUSHROOMFARM, Buildings.READY);

									if ((obj[1] ~= -1) and (obj[2] ~= -1)) then
										WarriorsLib.Send(gardeners, obj[1], obj[2], WarriorsLib.MOVE_FORWARDS);
										cbUseSoldiers(i, obj[1], obj[2]);
									end
								elseif (Buildings.Amount(Game.LocalPlayer(), Buildings.DARKTEMPLE, Buildings.READY) > 0) then
									local obj = SearchBuilding(Game.LocalPlayer(), Buildings.DARKTEMPLE, Buildings.READY);
								
									if ((obj[1] ~= -1) and (obj[2] ~= -1)) then
										WarriorsLib.Send(gardeners, obj[1], obj[2], WarriorsLib.MOVE_FORWARDS);
										cbUseSoldiers(i, obj[1], obj[2]);
									end
								elseif (Buildings.Amount(Game.LocalPlayer(), Buildings.FORTRESS, Buildings.READY) > 0) then
									local obj = SearchBuilding(Game.LocalPlayer(), Buildings.FORTRESS, Buildings.READY);
								
									if ((obj[1] ~= -1) and (obj[2] ~= -1)) then
										WarriorsLib.Send(gardeners, obj[1], obj[2], WarriorsLib.MOVE_FORWARDS);
										cbUseSoldiers(i, obj[1], obj[2]);
									end
								end
							end

							return 0;
						end
					end
				end
			end

			i = i + 1;
		end
	end
end

function cbUsePriests()
	if (bEnabledPriestsAttack == 1) then
		if ((Game.Time() >= iDelayPriestsAttack) and (iTimePriestsAttack + iIntervallPriestsAttack <= Game.Time())) then
			if (iDeltaTimePriestsAttack >= 29) then
				iDeltaTimePriestsAttack = 0;
				
				local i = 1;
				while(i <= Game.NumberOfPlayers()) do
					if ((CustomAI[i] == 1) and (Game.HasPlayerLost(i) ~= 1)) then
						if (bEnabledPriestsUsage[i] == 1) then
							if (Settlers.Amount(i, Settlers.PRIEST) > 0) then
								if (Buildings.Amount(Game.LocalPlayer(), Buildings.MUSHROOMFARM, Buildings.READY) > 0) then
									local obj = SearchBuilding(Game.LocalPlayer(), Buildings.MUSHROOMFARM, Buildings.READY);

									if ((obj[1] ~= -1) and (obj[2] ~= -1)) then
										if (Settlers.AmountInArea(i, Settlers.PRIEST, obj[1], obj[2], 8) > 0) then
											if (Magic.CurrentManaAmount(i) >= iCostPriestsAttack) then
												iTimePriestsAttack = Game.Time();

												if (Game.Random(2) == 1) then
													Magic.DecreaseMana(i, iCostPriestsAttack);
													Magic.CastSpell(i, -1, 3, obj[1], obj[2]);

													return 0;
												end
											end
										end							
									end
								end
							end
						end
					end

					i = i + 1;
				end
			else
				iDeltaTimePriestsAttack = iDeltaTimePriestsAttack + 1;
			end
		end
	end
end

function cbCustomAI()
	cbRecruitGardeners();
	cbUseGardeners();
	cbUsePriests();
end

function RegisterCustomAI(i, bGardener, bPriests)
	if (WarriorsLib.isHuman(i) == 1) then
		return 0;
	end

	if (bEnabledPriestsAttack == 0) then
		if (bPriests == 1) then
			bEnabledPriestsAttack = 1;
		end
	end

	CustomAI[i] = 1;
	bEnabledGardenerUsage[i] = bGardener;
	bEnabledPriestsUsage[i] = bPriests;

	return 1;
end

--//---------------------------------------------------------------
--//---------------------BUILDING FUNCTIONS------------------------
--//---------------------------------------------------------------

function cbIsBuildingInProximity(x, y, r, oBuildingType)
	if ((oBuildingType == Buildings.DARKTEMPLE) or (oBuildingType == Buildings.FORTRESS)) then
		if ((Buildings.ExistsBuildingInArea(Game.LocalPlayer(), Buildings.DARKTEMPLE, x, y, r, Buildings.READY) > 0) or (Buildings.ExistsBuildingInArea(Game.LocalPlayer(), Buildings.FORTRESS, x, y, r, Buildings.READY) > 0) or (Buildings.ExistsBuildingInArea(Game.LocalPlayer(), Buildings.MUSHROOMFARM, x, y, r, Buildings.READY) > 0)) then
			return 1;
		end
	else
		if ((Buildings.ExistsBuildingInArea(Game.LocalPlayer(), Buildings.DARKTEMPLE, x, y, r, Buildings.READY) > 0) or (Buildings.ExistsBuildingInArea(Game.LocalPlayer(), Buildings.FORTRESS, x, y, r, Buildings.READY) > 0)) then
			return 1;
		end
	end

	return 0;
end

function cbIsEntityInProximity(x, y, r)
	if ((Settlers.AmountInArea(1, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(2, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(3, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(4, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(5, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(6, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(7, Settlers.ANY_SETTLER, x, y, r) > 0) or (Settlers.AmountInArea(8, Settlers.ANY_SETTLER, x, y, r) > 0)) then
		return 1;
	end
	
	return 0;
end

function cbGenerateVision(x, y)
	if (Game.IsAreaDarkLand(x, y, 1) == 1) then
		local i = 1;
		while (i <= Game.NumberOfPlayers()) do
			if (Game.IsAreaOwned(i, x, y, 1) == 1) then
				return 0;
			end
			
			i = i + 1;
		end

		local id = Buildings.AddBuilding(x, y, Game.LocalPlayer(), Buildings.CASTLE);
		if (id ~= nil) then
			Buildings.Delete(id, 2);
		end

		return 1;
	end

	return 0;
end

function cbBuildMushroomFarm(x, y)
	if (bEnabledMushroomFarmPlayer == 1) then
		if (cbIsBuildingInProximity(x, y, 30, Buildings.MUSHROOMFARM) == 0) then	
			if (cbIsEntityInProximity(x, y, 3) == 0) then
				if (Magic.CurrentManaAmount(Game.LocalPlayer()) >= iCostMushroomFarmPlayer) then
					Magic.DecreaseMana(Game.LocalPlayer(), iCostMushroomFarmPlayer);
					Map.DeleteDecoObject(x, y, 5);
					cbGenerateVision(x, y);
					Effects.AddEffect(Effects.MUSHROOMFARM_BUILD, Sounds.MAGIC_STONECURSE, x, y, 0);
					Buildings.AddBuilding(x, y, Game.LocalPlayer(), Buildings.MUSHROOMFARM);
				else
					dbg.stm(MSG_MUSHROOMFARM_NOMANA);
				end
			else
				dbg.stm(MSG_MUSHROOMFARM_BLOCKED);
			end
		else
			dbg.stm(MSG_TEMPLE_IN_RANGE);
		end
	else
		dbg.stm(MSG_MUSHROOMFARM_DISABLED);
	end
end

function cbBuildDarkTemple(x, y)
	if (bEnabledDarkTemplePlayer == 1) then
		if (cbIsBuildingInProximity(x, y, 30, Buildings.DARKTEMPLE) == 0) then	
			if (cbIsEntityInProximity(x, y, 10) == 0) then
				if (Magic.CurrentManaAmount(Game.LocalPlayer()) >= iCostDarkTemplePlayer) then
					Magic.DecreaseMana(Game.LocalPlayer(), iCostDarkTemplePlayer);
					Map.DeleteDecoObject(x, y, 10);
					cbGenerateVision(x, y);
					Effects.AddEffect(Effects.NO_EFFECT, Sounds.MAGIC_STONECURSE, x, y, 0);
					Buildings.AddBuilding(x, y, Game.LocalPlayer(), Buildings.DARKTEMPLE);
				else
					dbg.stm(MSG_DARKTEMPLE_NOMANA);
				end
			else
				dbg.stm(MSG_DARKTEMPLE_BLOCKED);
			end
		else
			dbg.stm(MSG_BUILDING_IN_RANGE);
		end
	else
		dbg.stm(MSG_DARKTEMPLE_DISABLED);
	end
end

function cbBuildFortress(x, y)
	if (bEnabledFortressPlayer == 1) then
		if (cbIsBuildingInProximity(x, y, 30, Buildings.FORTRESS) == 0) then	
			if (cbIsEntityInProximity(x, y, 10) == 0) then
				if (Magic.CurrentManaAmount(Game.LocalPlayer()) >= iCostFortressPlayer) then
					Magic.DecreaseMana(Game.LocalPlayer(), iCostFortressPlayer);
					Map.DeleteDecoObject(x, y, 10);
					cbGenerateVision(x, y);
					Effects.AddEffect(Effects.NO_EFFECT, Sounds.MAGIC_STONECURSE, x, y, 0);
					Buildings.AddBuilding(x, y, Game.LocalPlayer(), Buildings.FORTRESS);
				else
					dbg.stm(MSG_FORTRESS_NOMANA);
				end
			else
				dbg.stm(MSG_FORTRESS_BLOCKED);
			end
		else
			dbg.stm(MSG_BUILDING_IN_RANGE);
		end
	else
		dbg.stm(MSG_FORTRESS_DISABLED);
	end
end

function cbBuildStoneMine(x, y)
	cbGenerateVision(x, y);
end

function cbBuildBarracks(x, y)
	if (Buildings.Amount(Game.LocalPlayer(), Buildings.BARRACKS, Buildings.READY) <= 0) then
		if (cbGenerateVision(x+1, y+1) == 1) then
			Buildings.AddBuilding(x, y, Game.LocalPlayer(), Buildings.BARRACKS);
		else
			dbg.stm(MSG_ERR_BARRACKS_CANT_BUILD);
		end
	else
		dbg.stm(MSG_ERR_BARRACKS_TOO_MANY);
	end
end

function cbBuildingHandler()
	local i = 1;
	while(i <= sizeof(ENUM_BUILDINGS)) do
		while(Buildings.Amount(Game.LocalPlayer(), ENUM_BUILDINGS[i], Buildings.UNDERCONSTRUCTION) > 0) do
			local obj = SearchBuilding(Game.LocalPlayer(), ENUM_BUILDINGS[i], Buildings.UNDERCONSTRUCTION);
			if ((obj[1] == -1) or (obj[2] == -1)) then return 0; end
			
			Buildings.CrushBuilding(Buildings.GetFirstBuilding(Game.LocalPlayer(), ENUM_BUILDINGS[i]));
			
			if (ENUM_BUILDINGS[i] == Buildings.RESIDENCESMALL) then
				cbBuildMushroomFarm(obj[1], obj[2]);
			elseif (ENUM_BUILDINGS[i] == Buildings.RESIDENCEMEDIUM) then
				cbBuildDarkTemple(obj[1], obj[2]);
			elseif (ENUM_BUILDINGS[i] == Buildings.RESIDENCEBIG) then
				cbBuildFortress(obj[1], obj[2]);
			elseif (ENUM_BUILDINGS[i] == Buildings.STONEMINE) then
				cbBuildStoneMine(obj[1], obj[2]);
			elseif (ENUM_BUILDINGS[i] == Buildings.BARRACKS) then
				cbBuildBarracks(obj[1], obj[2]);
			end
		end

		i = i + 1;
	end
end

--//---------------------------------------------------------------
--//-------------------GETTER AND SETTER---------------------------
--//---------------------------------------------------------------



--//---------------------------------------------------------------
--//-------------------GLOBAL FUNCTIONS----------------------------
--//---------------------------------------------------------------

function foo()
	dbg.stm("foo");
end

function new_game()
	if (WarriorsLib ~= nil) then
		dbg.stm(MSG_OK_LOAD);

		request_event(cbCustomAI, Events.FIVE_TICKS);
		request_event(cbBuildingHandler, Events.TICK);
		request_event(main_new_game, Events.FIRST_TICK_OF_NEW_GAME);
		request_event(main_new_and_loaded_game, Events.FIRST_TICK_OF_NEW_OR_LOADED_GAME);
	else
		request_event(ForceWarriorsLib, Events.FIRST_TICK_OF_NEW_OR_LOADED_GAME);
	end

	request_event(foo, Events.MENUCLICK);
	dbg.stm("1");
end

function register_functions()
	reg_func(ForceWarriorsLib);
	reg_func(cbCustomAI);
	reg_func(cbBuildingHandler);
	reg_func(main_new_game);
	reg_func(main_new_and_loaded_game);

	RegisterFunctions();

	reg_func(foo);
	dbg.stm("2");
end

--//------------------------EDIT HERE------------------------------
--//---PUT YOUR CODE HERE USE THE MAIN FUNCTIONS AS ENTRY POINTS---
--//---------------------------------------------------------------

--//Functions
--//
--// - 


function RegisterFunctions()
	
end

function main_new_game()
	Magic.IncreaseMana(Game.LocalPlayer(), 300);

	AI.SetPlayerVar(2, "AttackMode", 3,3,3);
	AI.SetPlayerVar(3, "AttackMode", 0,0,0);
	AI.SetPlayerVar(2, "SoldierLimitAbsolute", 100,150,150);
	AI.SetPlayerVar(3, "SoldierLimitAbsolute", 100,120,120);
end

function main_new_and_loaded_game()
	RegisterCustomAI(2, 1, 1);
	RegisterCustomAI(3, 1, 1);

	--//Tutorial.RWM(1);
end
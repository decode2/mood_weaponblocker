
#define DEBUG

#define PLUGIN_NAME           "Weapons by map blocker"
#define PLUGIN_AUTHOR         "Deco"
#define PLUGIN_DESCRIPTION    "Bloquea armas prohibidas en mapas"
#define PLUGIN_VERSION        "0.1"
#define PLUGIN_URL            "www.piu-games.com"

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#pragma newdecls required

char sMapname[64];

enum BlockedWeapons{
	
	WEAPON_G3SG1,
	WEAPON_SCAR20,
	WEAPON_AWP
}

char sMapsAwp[] = {
	
	// AWP
	"$2000$_csgo",
	"fy_pool_day_classic",
	"fy_iceworld2k_t0",
	"aim_redline"
};

char sMapsG3[] = {
	
	// G3SG1
	"$2000$_csgo",
	"fy_pool_day_classic",
	"fy_iceworld2k_t0"
};

char sMapsScar[] = {
	
	// SCAR20
	"$2000$_csgo",
	"fy_pool_day_classic",
	"fy_iceworld2k_t0"
};

public Plugin myinfo = {
	
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart(){
	
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for the game CSGO only.");
}

public void OnMapStart(){
	
	// Parse mapname
	GetCurrentMap(sMapname, sizeof(sMapname));
}

public Action WeaponsOnEquip(int client, int weapon){
	
	if(!IsClientInGame(client)){
		return Plugin_Handled;
	}
	
	if (!canUseWeaponInMap(weapon)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action WeaponsOnCanUse(int client, int weapon){
	
	if(!IsValidEdict(weapon) || !IsClientInGame(client)){
		return Plugin_Handled;
	}
	
	if (!canUseWeaponInMap(weapon)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

bool canUseWeaponInMap(int weapon){
	
	if (!IsValidEntity(weapon)){
		LogError("ERROR! Weapon id %d is not valid", weapon);
		return false;
	}
	
	char weap[32];
	GetEdictClassname(weapon, weap, sizeof(weap));
	
	bool canUse = true;
	
	if (StrEqual(weap, "weapon_awp")){
		
		for (int i = 0; i < sizeof(sMapsAwp); i++){
			
			if (StrEqual(sMapname, sMapsAwp[i])){
				canUse = true;
				break;
			}
		}
	}
	
	if (StrEqual(weap, "weapon_g3sg1")){
		
		for (int i = 0; i < sizeof(sMapsG3); i++){
			
			if (StrEqual(sMapname, sMapsG3[i])){
				canUse = true;
				break;
			}
		}
	}
	
	if (StrEqual(weap, "weapon_scar20")){
		
		for (int i = 0; i < sizeof(sMapsScar); i++){
			
			if (StrEqual(sMapname, sMapsScar[i])){
				canUse = true;
				break;
			}
		}
	}
	
	return canUse;
}
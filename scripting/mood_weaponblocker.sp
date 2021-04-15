
#define DEBUG

#define PLUGIN_NAME           "Weapons by map blocker"
#define PLUGIN_AUTHOR         "Deco"
#define PLUGIN_DESCRIPTION    "Bloquea armas prohibidas en mapas"
#define PLUGIN_VERSION        "0.2"
#define PLUGIN_URL            "www.piu-games.com"

#include <sourcemod>
#include <sdktools>
#include <map>

#pragma semicolon 1

#pragma newdecls required

ArrayList arrayBlocked;
ArrayList arrayBlockedName;

public Plugin myinfo = {
	
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart(){
	
	// ATM we only support csgo
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for the game CSGO only.");
	
	// Cache blocked weapons to optimize searches
	arrayBlocked = new ArrayList(10);
	arrayBlockedName = new ArrayList(10);
	
	// Start maps module
	MapsOnInit();
}

public void OnMapStart(){
	
	// Forward event to module
	MapsOnMapStart();
	
	// Cache destroy!
	arrayBlocked.Clear();
	arrayBlockedName.Clear();
	
	// Cache!
	int blocked = CacheBlockedWeaponsOnMapStart();
	if (blocked){
		
		char sWeapons[24][16];
		for (int i = 0; i < blocked; i++){
			
			arrayBlockedName.GetString(i, sWeapons[i], sizeof(sWeapons));
		}
		
		char buffer[512];
		ImplodeStrings(sWeapons, blocked, ", ", buffer, sizeof(buffer));
		PrintToChatAll(" \x09[MOOD]\x01 Armas bloqueadas en este mapa: \x03%s\x01.", buffer);
	}
	else{
		PrintToChatAll(" \x09[MOOD]\x01 No se han bloqueado armas en este mapa.");
	}
}

public void OnPluginEnd(){
	
	// Forward event to module
	MapsOnPluginEnd();
	
	// Delete this now
	delete arrayBlocked;
	delete arrayBlockedName;
}

int CacheBlockedWeaponsOnMapStart(){
	
	int blocked = 0;
	
	// Prepare loop
	MapData map;
	
	for (int i = 0; i < maps.Length; i++){
		
		maps.GetArray(i, map);
		
		if (StrEqual(map.name, sMapName, false) ){
			
			for (int j = 0; j < sizeof(WeaponsEntName); j++){
				
				if (!map.blockedWeapons){
					break;
				}
				
				if (map.blockedWeapons & WeaponsBitFields[j]){
					arrayBlocked.PushString(WeaponsEntName[j]);
					arrayBlockedName.PushString(WeaponsName[j]);
					blocked++;
				}
			}
			break;
		}
	}
	
	return blocked;
}

// OnEquip hook
public Action WeaponsOnEquip(int client, int weapon){
	
	if(!IsClientInGame(client)){
		return Plugin_Handled;
	}
	
	if (!canUseWeaponInMap(weapon)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// OnCanUse hook
public Action WeaponsOnCanUse(int client, int weapon){
	
	if(!IsValidEdict(weapon) || !IsClientInGame(client)){
		return Plugin_Handled;
	}
	
	if (!canUseWeaponInMap(weapon)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Simple func to detect if weapon is blocked in current map
bool canUseWeaponInMap(int weapon){
	
	if (!IsValidEntity(weapon)){
		LogError("ERROR! Weapon id %d is not valid", weapon);
		return false;
	}
	
	char weap[32];
	GetEdictClassname(weapon, weap, sizeof(weap));
	
	if (arrayBlocked.FindString(weap) != -1){
		return false;
	}
	
	return true;
}
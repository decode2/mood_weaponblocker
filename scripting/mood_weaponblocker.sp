
#define DEBUG

#define PLUGIN_NAME           "Weapons by map blocker"
#define PLUGIN_AUTHOR         "Deco"
#define PLUGIN_DESCRIPTION    "Bloquea armas prohibidas en mapas"
#define PLUGIN_VERSION        "0.3"
#define PLUGIN_URL            "www.piu-games.com"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
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

public void OnClientPutInServer(int client){
	
	//SDKHook(client, SDKHook_WeaponCanUse, 	WeaponsOnCanUse);
	SDKHook(client, SDKHook_WeaponEquip, 	WeaponsOnEquip);
}

public void OnClientDisconnect(int client){
	
	//SDKUnhook(client, SDKHook_WeaponCanUse, WeaponsOnCanUse);
	SDKUnhook(client, SDKHook_WeaponEquip, 	WeaponsOnEquip);
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
	
	/*if(!IsClientInGame(client)){
		return Plugin_Continue;
	}*/
	
	if (!canUseWeaponInMap(weapon)){
		AcceptEntityInput(weapon, "kill");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// OnCanUse hook
public Action WeaponsOnCanUse(int client, int weapon){
	
	if(!IsValidEdict(weapon) || !IsClientInGame(client)){
		return Plugin_Continue;
	}
	
	if (!canUseWeaponInMap(weapon)){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Block buy command
public Action CS_OnBuyCommand(int client, const char[] szWeapon){
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0)
		return Plugin_Continue;
	
	char weap[32];
	strcopy(weap, sizeof(weap), szWeapon);
	
	LowerCaseString(weap);
	StripWeaponPrefix(weap, sizeof(weap));
	
	if (!canUseWeaponFindByStr(weap)){
		
		upperCaseString(weap);
		PrintToChat(client, " \x09[MOOD]\x01 Arma bloqueada en este mapa! (\x04%s\x01)", weap);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Simple func to detect if weapon is blocked in current map
bool canUseWeaponInMap(int weapon){
	
	if (!IsValidEdict(weapon)){
		LogError("ERROR! Weapon id %d is not valid", weapon);
		return true;
	}
	
	char weap[32];
	GetEdictClassname(weapon, weap, sizeof(weap));
	
	LowerCaseString(weap);
	StripWeaponPrefix(weap, sizeof(weap));
	
	return canUseWeaponFindByStr(weap);
}

bool canUseWeaponFindByStr(const char[] szWeapon){
	
	if (arrayBlocked.FindString(szWeapon) != -1){
		return false;
	}
	
	return true;
}

void StripWeaponPrefix(char[] weapon, int size){
	
	ReplaceString(weapon, size, "weapon_", "", false);
}

// Lower case a string
void LowerCaseString(char[] s){
	for(int i = 0;; ++i){
		// Break early at zero-termination
		if(s[i] == '\0'){
			break;
		}
		
		if(IsCharUpper(s[i])){
			s[i] = CharToLower(s[i]);
		}
	}
}

// Lower case a string
void upperCaseString(char[] s){
	for(int i = 0;; ++i){
		// Break early at zero-termination
		if(s[i] == '\0'){
			break;
		}
		
		if(IsCharLower(s[i])){
			s[i] = CharToUpper(s[i]);
		}
	}
}
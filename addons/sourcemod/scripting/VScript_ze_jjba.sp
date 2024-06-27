#pragma semicolon 1

#define MAP_NAME "ze_jjba_v5fs"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <outputinfo>
#include <vscripts/JJBA>
#include <multicolors>

#pragma newdecls required

bool bValidMap = false;
ArrayList g_aMovingNpc = null;

public Plugin myinfo = 
{
	name = "JJBA vscripts",
	author = "Cloud Strife, .Rushaway, maxime1907",
	description = "JJBA vscripts",
	version = "2.0",
	url = "https://steamcommunity.com/id/cloudstrifeua/"
};

public void OnMapStart()
{
	char sCurMap[256];
	GetCurrentMap(sCurMap, sizeof(sCurMap));
	bValidMap = (strcmp(MAP_NAME, sCurMap, false) == 0);
	if (bValidMap)
	{
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		g_aMovingNpc = new ArrayList();
	}
	else
	{
		char sFilename[256];
		GetPluginFilename(INVALID_HANDLE, sFilename, sizeof(sFilename));

		ServerCommand("sm plugins unload %s", sFilename);
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(12.0, Credits, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!bValidMap)
		return;

	if (!CanTestFeatures() || GetFeatureStatus(FeatureType_Native, "SDKHook_OnEntitySpawned") != FeatureStatus_Available)
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnedPost);
}

public void OnEntitySpawnedPost(int entity)
{
	if (!IsValidEntity(entity))
		return;

	// 1 frame later required to get some properties
	RequestFrame(ProcessEntitySpawned, entity);
}

public void OnEntitySpawned(int entity, const char[] classname)
{
	ProcessEntitySpawned(entity);
}

stock void ProcessEntitySpawned(int entity)
{
	if (!bValidMap || !IsValidEntity(entity))
		return;

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));

	if (strcmp(classname, "phys_thruster") == 0)
	{
		char sTarget[128];
		GetOutputTarget(entity, "m_OnUser1", 0, sTarget, sizeof(sTarget));
		if(!sTarget[0])
			return;
		
		if (StrContains(sTarget, "npc_physbox") != -1)
		{
			int ent = Vscripts_GetEntityIndexByName(sTarget, "func_physbox");
			MovingNpc npc = null;
			bool bAlreadyInList = false;
			for (int i = 0; i < g_aMovingNpc.Length; i++)
			{
				MovingNpc tmp = view_as<MovingNpc>(g_aMovingNpc.Get(i));
				if(tmp.entity == ent)
				{
					npc = tmp;
					bAlreadyInList = true;
				}
			}
			if(!bAlreadyInList)
			{
				npc = new MovingNpc(ent);
			}
			GetEntPropString(entity, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
			if(StrContains(sTarget, "npc_thruster_forward") != -1)
			{
				npc.SetThruster(true, entity);
			}
			else if(StrContains(sTarget, "npc_thruster_side") != -1)
			{
				npc.SetThruster(false, entity);
			}
			
			if(bAlreadyInList)
			{
				npc.Start();
				
			}
			else
				g_aMovingNpc.Push(npc);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if(!bValidMap)
		return;

	if (!CanTestFeatures() || GetFeatureStatus(FeatureType_Native, "SDKHook_OnEntitySpawned") != FeatureStatus_Available)
		SDKUnhook(entity, SDKHook_SpawnPost, OnEntitySpawnedPost);

	if(!IsValidEntity(entity))
		return;

	char sClassname[128];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	if(strcmp(sClassname, "func_physbox") == 0)
	{
		for (int i = 0; i < g_aMovingNpc.Length; i++)
		{
			MovingNpc npc = view_as<MovingNpc>(g_aMovingNpc.Get(i));
			if(npc.entity == entity)
			{
				npc.Stop();
				delete npc;
				g_aMovingNpc.Erase(i);
				break;
			}
		}
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Cleanup();
}

public void Cleanup()
{
	if (g_aMovingNpc)
	{
		for (int i = 0; i < g_aMovingNpc.Length; i++)
		{
			MovingNpc npc = view_as<MovingNpc>(g_aMovingNpc.Get(i));
			npc.Stop();
			delete npc;
			g_aMovingNpc.Erase(i);
		}
	}
}

public void OnMapEnd()
{
	Cleanup();
	if (bValidMap)
	{
		UnhookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		delete g_aMovingNpc;
	}
	bValidMap = false;
}

public Action Credits(Handle timer)
{
	CPrintToChatAll("{pink}[VScripts] {white}Map using VScripts ported by Cloud Strife.");
	return Plugin_Continue;
}
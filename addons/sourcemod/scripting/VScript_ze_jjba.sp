#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Cloud Strife"
#define PLUGIN_VERSION "1.00"
#define MAP_NAME "ze_jjba_v5fs"

#include <sourcemod>
#include <sdktools>
#include <outputinfo>
#include <vscripts/JJBA>

#pragma newdecls required

bool bValidMap = false;
ArrayList g_aMovingNpc = null;

public Plugin myinfo = 
{
	name = "JJBA vscripts",
	author = PLUGIN_AUTHOR,
	description = "JJBA vscripts",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/cloudstrifeua/"
};

public void OnMapStart()
{
	char sCurMap[256];
	GetCurrentMap(sCurMap, sizeof(sCurMap));
	bValidMap = (strcmp(MAP_NAME, sCurMap, false) == 0);
	if (bValidMap)
		g_aMovingNpc = new ArrayList();
	else
	{
		char sFilename[256];
		GetPluginFilename(INVALID_HANDLE, sFilename, sizeof(sFilename));

		ServerCommand("sm plugins unload %s", sFilename);
	}
}

public void OnEntitySpawned(int entity, const char[] classname)
{
	if(!bValidMap)
		return;

	if(IsValidEntity(entity))
	{
		if(strcmp(classname, "phys_thruster") == 0)
		{
			char sTarget[128];
			GetOutputTarget(entity, "m_OnUser1", 0, sTarget, sizeof(sTarget));
			if(!sTarget[0])
				return;
			
			if (StrContains(sTarget, "npc_physbox") != -1)
			{
				int ent = GetEntityIndexByName(sTarget, "func_physbox");
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
}

public void OnEntityDestroyed(int entity)
{
	if(!bValidMap)
		return;

	if(IsValidEntity(entity))
	{
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
	if (bValidMap)
	{
		Cleanup();
		delete g_aMovingNpc;
	}
	bValidMap = false;
}
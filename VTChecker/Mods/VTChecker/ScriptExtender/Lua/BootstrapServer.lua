local Channels = Ext.Require("Shared/Channels.lua")
local Runner = Ext.Require("Server/Runner.lua")
local State = Ext.Require("Shared/State.lua")

local state = State.Get()
if not state.ServerInitialized then
    state.ServerInitialized = true

    Ext.Events.SessionLoading:Subscribe(function()
        State.MarkSessionLoaded(false)
        State.SetBusy(false)
    end)

    Ext.Events.SessionLoaded:Subscribe(function()
        State.MarkSessionLoaded(true)
    end)

    Ext.Events.GameStateChanged:Subscribe(function(event)
        local toState = tostring(event and event.ToState or "")
        if toState:find("Menu", 1, true) or toState:find("Unload", 1, true) then
            State.MarkSessionLoaded(false)
            State.SetBusy(false)
        end
    end)

    Channels.RunScript:SetRequestHandler(function(payload, user)
        return Runner.Run(user, payload)
    end)
end

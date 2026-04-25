local Channels = Ext.Require("Shared/Channels.lua")
local Runner = Ext.Require("Server/Runner.lua")
local State = Ext.Require("Shared/State.lua")

local state = State.Get()
if not state.ServerInitialized then
    state.ServerInitialized = true

    Ext.Events.SessionLoaded:Subscribe(function()
        State.MarkSessionLoaded(true)
    end)

    Channels.RunScript:SetRequestHandler(function(payload, user)
        return Runner.Run(user, payload)
    end)
end

local Controller = Ext.Require("Client/Controller.lua")
local State = Ext.Require("Shared/State.lua")

local state = State.Get()
if not state.ClientInitialized then
    state.ClientInitialized = true
    Controller.Init()
end

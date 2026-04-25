local State = Ext.Require("Shared/State.lua")
local Executor = Ext.Require("Shared/Executor.lua")

local Runner = {}

function Runner.Run(user, payload)
    local state = State.Get()

    if state.IsBusy then
        return {
            Success = false,
            Output = state.OutputText or "",
            StatusMessage = "VTChecker is already running the script."
        }
    end

    if not state.SessionLoaded then
        return {
            Success = false,
            Output = "",
            StatusMessage = "Load a save before running the script."
        }
    end

    State.SetBusy(true)
    local ok, output, err = Executor.Run("server")
    State.SetBusy(false)

    State.SetOutput(output)

    if ok then
        return {
            Success = true,
            Output = output,
            StatusMessage = "Script completed successfully."
        }
    end

    local statusMessage = err or "Script failed."
    return {
        Success = false,
        Output = output,
        StatusMessage = statusMessage
    }
end

return Runner

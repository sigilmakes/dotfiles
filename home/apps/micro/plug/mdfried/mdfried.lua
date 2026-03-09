VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")

function mdfried(bp)
    local filePath = bp.Buf.AbsPath

    if filePath == "" then
        micro.InfoBar():Error("No file open")
        return
    end

    -- Check if it's a markdown file
    if not string.match(filePath, "%.md$") and not string.match(filePath, "%.markdown$") then
        micro.InfoBar():Error("Not a markdown file")
        return
    end

    -- Shell-escape the path to handle spaces and special characters
    local escaped = filePath:gsub("'", "'\\''")
    local output, err = shell.RunInteractiveShell("mdfried '" .. escaped .. "'", false, false)
    if err ~= nil then
        micro.InfoBar():Error("mdfried error: ", err)
    end
end

function init()
    config.MakeCommand("mdfried", mdfried, config.NoComplete)
end

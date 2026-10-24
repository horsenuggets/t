--[[

LuneTestEnvironment

Lets the upstream test suite run under Lune without editing it. Builds the Roblox globals
the tests expect (backed by "@lune/roblox") and marks tests that can't work outside Roblox
as skipped in a Testable plan, so upstream syncs never conflict with fork-only changes.

--]]

const Testable = require("@devpackages/Testable")
const roblox = require("@lune/roblox")

export type Plan = {
    findNodes: (self: Plan, callback: (node: any) -> boolean) -> { any },
}

const LuneTestEnvironment = {}

--[[
    Creates the Roblox globals the upstream tests use. "Instance.new" accepts the legacy
    parent argument that Roblox supports and Lune's version ignores.

    @return A table of global names to values, for Testable's runner environment
]]
function LuneTestEnvironment.createGlobals(): { [string]: any }
    return {
        -- Lune provides Enum at runtime, but its type definitions don't declare it.
        Enum = (roblox :: any).Enum,
        Instance = {
            new = function(className: string, parent: any?)
                assert(type(className) == "string", "className must be a string")
                const instance = roblox.Instance.new(className)
                if parent ~= nil then
                    instance.Parent = parent
                end
                return instance
            end,
        },
    }
end

--[[
    Marks the given tests as skipped in a Testable plan. Errors if any listed test isn't
    in the plan, so the skip list can't silently go stale after an upstream sync.

    @param plan - The Testable plan to modify
    @param skips - Full test names mapped to the reason each one is skipped
    @return The full names of the skipped tests, sorted
]]
function LuneTestEnvironment.skipTests(plan: Plan, skips: { [string]: string }): { string }
    assert(type(plan) == "table", "plan must be a table")
    assert(type(skips) == "table", "skips must be a table")

    const skipped = {}
    const nodes = plan:findNodes(function(node)
        return skips[node:getFullName()] ~= nil
    end)
    for _, node in nodes do
        node.modifier = Testable.TestEnum.NodeModifier.Skip
        table.insert(skipped, node:getFullName())
    end

    for name in skips do
        if not table.find(skipped, name) then
            error(`Skipped test "{name}" was not found in the test plan.`)
        end
    end

    table.sort(skipped)
    return skipped
end

return LuneTestEnvironment

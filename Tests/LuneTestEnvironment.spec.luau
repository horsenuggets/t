--[[

LuneTestEnvironment.spec

Tests for the fork's Lune test environment helper, which provides Roblox globals to the
upstream tests and skips the ones that can't run under Lune.

--]]

return function()
    const LuneTestEnvironment = require("../Scripts/Helpers/LuneTestEnvironment")
    const Testable = require("@devpackages/Testable")
    const t = require("@t")

    const SKIP = Testable.TestEnum.NodeModifier.Skip

    const function createPlan()
        return Testable.TestPlanner.createPlan({
            {
                method = function()
                    it("first", function() end)
                    it("second", function() end)
                end,
                path = { "Root" },
                pathStringForSorting = "Root",
            },
        })
    end

    const function getModifiers(plan): { [string]: string }
        const modifiers = {}
        const nodes = plan:findNodes(function()
            return true
        end)
        for _, node in nodes do
            modifiers[node:getFullName()] = node.modifier
        end
        return modifiers
    end

    it("should create Instances with Lune's Roblox library", function()
        const globals = LuneTestEnvironment.createGlobals()
        const frame = globals.Instance.new("Frame")

        assert(t.Instance(frame))
        assert(frame.ClassName == "Frame")
        assert(frame.Parent == nil)
    end)

    it("should support the legacy parent argument of Instance.new", function()
        const globals = LuneTestEnvironment.createGlobals()
        const frame = globals.Instance.new("Frame")
        const button = globals.Instance.new("ImageButton", frame)

        assert(button.Parent == frame)
        assert(frame:FindFirstChildOfClass("ImageButton") == button)
    end)

    it("should provide Roblox enums", function()
        const globals = LuneTestEnvironment.createGlobals()

        assert(t.Enums(globals.Enum))
        assert(t.Enum(globals.Enum.SortOrder))
        assert(t.EnumItem(globals.Enum.SortOrder.Name))
    end)

    it("should create independent globals on every call", function()
        const first = LuneTestEnvironment.createGlobals()
        const second = LuneTestEnvironment.createGlobals()

        assert(first ~= second)
        assert(first.Instance ~= second.Instance)
    end)

    it("should skip only the listed tests", function()
        const plan = createPlan()
        const skipped = LuneTestEnvironment.skipTests(plan, { ["Root first"] = "Reason." })
        const modifiers = getModifiers(plan)

        assert(#skipped == 1 and skipped[1] == "Root first")
        assert(modifiers["Root first"] == SKIP)
        assert(modifiers["Root second"] ~= SKIP)
        assert(modifiers["Root"] ~= SKIP)
    end)

    it("should return skipped tests in sorted order", function()
        const plan = createPlan()
        const skipped = LuneTestEnvironment.skipTests(plan, {
            ["Root second"] = "Reason.",
            ["Root first"] = "Reason.",
        })

        assert(#skipped == 2)
        assert(skipped[1] == "Root first" and skipped[2] == "Root second")
    end)

    it("should leave the plan unchanged with no skips", function()
        const plan = createPlan()
        const before = getModifiers(plan)
        const skipped = LuneTestEnvironment.skipTests(plan, {})
        const after = getModifiers(plan)

        assert(#skipped == 0)
        for name, modifier in before do
            assert(after[name] == modifier)
        end
    end)

    it("should error when a listed test is missing from the plan", function()
        const plan = createPlan()
        const ok, message = pcall(LuneTestEnvironment.skipTests, plan, { ["Root missing"] = "Reason." })

        assert(not ok)
        assert(string.find(tostring(message), `"Root missing"`, 1, true))
    end)
end

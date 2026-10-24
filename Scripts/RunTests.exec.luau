#!/usr/bin/env -S lune run

--[[

RunTests.exec

Executes all test suites and exits with appropriate status code. Provides the Roblox
globals the upstream tests use and skips the few that can't run under Lune.

[Usage] ./Scripts/RunTests.exec.luau

--]]

const LuneTestEnvironment = require("./Helpers/LuneTestEnvironment")
const Testable = require("@devpackages/Testable")
const process = require("@lune/process")

const COVERAGE_THRESHOLD = 0
-- Tests that need Roblox engine features Lune doesn't provide, mapped to the reason.
const SKIPPED_TESTS = {
    ["TTest should support Roblox RBXScriptSignal"] = "Lune has no RBXScriptSignal type, so the test has no signal to check.",
}

const RunTests = {}

-- Mirrors Testable.run, with a step between planning and running that skips the tests
-- above. Testable.run has no hook for that, so the steps are called individually.
function RunTests.test(): boolean
    for name, value in LuneTestEnvironment.createGlobals() do
        Testable.TestRunner.environment[name] = value
    end

    const modules = Testable.TestBootstrap:getModulesFromMultipleRoots(project.Tests)
    const plan = Testable.TestPlanner.createPlan(modules)
    for _, name in LuneTestEnvironment.skipTests(plan, SKIPPED_TESTS) do
        print(`Skipping "{name}". {SKIPPED_TESTS[name]}`)
    end

    const results = Testable.TestRunner.runPlan(plan)
    Testable.Reporters.TextReporter.report(results)
    return results.failureCount == 0
end

function RunTests.coverage(): boolean
    const report = Testable.Coverage.collect(project.Source)
    if report == nil then
        return true
    end
    Testable.Reporters.CoverageReporter.report(report, COVERAGE_THRESHOLD)
    return report.TotalPercentage >= COVERAGE_THRESHOLD
end

function RunTests.exec()
    Testable.configure({
        Coverage = true,
        CoverageThreshold = COVERAGE_THRESHOLD,
        CoverageRoots = project.Source,
    })
    const passed = RunTests.test()
    const covered = RunTests.coverage()
    process.exit(if passed and covered then 0 else 1)
end

RunTests.exec()

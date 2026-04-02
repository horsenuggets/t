#!/usr/bin/env -S lune run

--[[

Lint

Runs luau-lsp static analysis on the project.

--]]

local Lint = require("../Submodules/luau-cicd/Scripts/Helpers/Lint")

Lint.run()

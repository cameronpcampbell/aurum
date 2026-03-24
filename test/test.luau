--!strict

local aurum = require("../src")

local app = aurum.new()

app.route ("GET", "/shop /product /shirts /:id[string] ? :size['lg' | 'md' | 'small']") (function(cx)
    local params = cx.params
    local search_params = cx.search_params
end)




# Aurum

An experiment of what a future Luau web framework could look like with the new type solver.

```luau
app.route ("GET", "/shop /product /shirts /:id[string] ? :size['lg' | 'md' | 'small']") (function(cx)
    -- The types for the variables below are automatically evaluated from the path above.
    local params: { read id: string } = cx.params
    local search_params: { read size: "lg" | "md" | "small" } = cx.search_params
end)
```
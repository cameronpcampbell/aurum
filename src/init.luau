--!strict
--!nolint LocalShadow

--> Union Helpers ----------------------------------------------------------------------
type function union_from_components(input: { type })
    local input_len = #input
    return if input_len == 0 then nil elseif input_len == 1 then input[1] else types.unionof(table.unpack(input))
end
----------------------------------------------------------------------------------------

--> Path Helpers -----------------------------------------------------------------------
type function clean_path(path: type)
    assert(path.tag, "singleton")
    
    local path = path:value()
    assert(type(path), "string")

    local path = string.gsub(path :: string, "[ \t\n\r\f]+", "")
    local path = string.gsub(path :: string, "[\\/]+", "/")
    local path = string.gsub(path :: string, "?+", "?")
    local path = string.gsub(path :: string, "%[+", "[")
    local path = string.gsub(path :: string, "%]+", "]")

    return path
end

type function extract_enum_path_param_type(param_type: string)
    local components = param_type:split("|") :: { string | type }

    for idx, component: string in components do
        components[idx] = extract_path_param_type(component)
    end

    return union_from_components(components)
end

type function extract_path_param_type(param_type: string)
    if param_type:find("|") then
        return extract_enum_path_param_type(param_type)
    end

    return
        if param_type == "any" then types.any
        elseif param_type == "unknown" then types.unknown
        elseif param_type == "never" then types.never
        elseif param_type == "boolean" then types.boolean
        elseif param_type == "true" then types.singleton(true)
        elseif param_type == "false" then types.singleton(false)
        elseif param_type == "buffer" then types.buffer
        elseif param_type == "number" then types.number
        elseif param_type == "string" then types.string
        elseif
            (param_type:sub(1, 1) == "'" and param_type:sub(#param_type) == "'") or
            (param_type:sub(1, 1) == '"' and param_type:sub(#param_type) == '"') or
            (param_type:sub(1, 1) == "`" and param_type:sub(#param_type) == "`")
        then
            types.singleton(param_type:sub(2, -2))
        elseif param_type == "thread" then types.thread
        else types.unknown 
end

type function extract_params(
    params: type,
    params_path: string
)
    for _, item in params_path:split("/") do
        if item:sub(1, 1) ~= ":" then continue end

        local param_type: type?

        local type_start_split_at = item:find("%[")

        local item_name = item:sub(
            2,
            if type_start_split_at then type_start_split_at - 1 else nil
        )
        if #item_name == 0 then continue end

        if type_start_split_at then
            -- item has a type.

            local type_end_split_at = item:find("]")

            local type_string = item:sub(
                type_start_split_at + 1,
                if type_end_split_at then type_end_split_at - 1 else nil
            )
            
            param_type = extract_path_param_type(type_string)
        end

        params:setreadproperty(types.singleton(item_name), param_type or types.any)
    end
end

type function extract_path_data(
    path: string,
    params: type,
    search_params: type
)
    local search_params_split_at = path:find("?")

    local params_path: string?, search_params_path: string?
    if search_params_split_at then
        params_path, search_params_path = path:sub(1, search_params_split_at), path:sub(search_params_split_at + 1)
    else
        params_path = path
    end

    if params_path and #params_path ~= 0 then
        extract_params(params, params_path)
    end

    if search_params_path and #search_params_path ~= 0 then
        extract_params(search_params, search_params_path)
    end

    --params:setreadproperty(types.singleton("debug"), types.singleton(params_path))
    --search_params:setreadproperty(types.singleton("debug"), types.singleton(search_params_path))
end

type function build_cx(path: type)
    local path = clean_path(path)

    local params = types.newtable()
    local search_params = types.newtable()

    local cx = types.newtable()
    cx:setreadproperty(types.singleton("params"), params)
    cx:setreadproperty(types.singleton("search_params"), search_params)

    extract_path_data(path, params, search_params)

    return cx
end
----------------------------------------------------------------------------------------

type RouteMethod = 
    | "GET"
    | "HEAD"
    | "POST"
    | "PUT"
    | "DELETE"
    | "CONNECT"
    | "OPTIONS"
    | "TRACE"
    | "PATCH"

local function route<S>(
    method: RouteMethod | string,
    path: S | ""
)
    return function(callback: (build_cx<S>) -> ())
    end
end

local function new()
    return {
        route = route
    }
end

return {
    new = new
}
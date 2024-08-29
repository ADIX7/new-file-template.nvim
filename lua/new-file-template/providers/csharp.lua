local M = {}

-- Function to search for a file recursively up to the root
local function find_csproj_file(start_dir)
    local csproj_dir = vim.fs.root(start_dir, function(name)
        return name:match("%.csproj$") ~= nil
    end)

    if csproj_dir == nil then
        return nil
    end

    local csprojs = vim.fn.glob(vim.fs.joinpath(csproj_dir, "*.csproj"), true, true)
    return {
        dir = csproj_dir,
        file = csprojs[1]
    }
end

local function read_file(file_path)
    local file = io.open(file_path, "r")
    if not file then
        error("Could not open file: " .. file_path)
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function get_root_namespace(xml_content)
    local pattern = "<RootNamespace>(.-)</RootNamespace>"
    local root_namespace = string.match(xml_content, pattern)
    return root_namespace
end

M.get_new_file_options = function(dir)
    local csproj = find_csproj_file(dir)

    if csproj == nil then
        vim.notify("No .csproj file found", vim.log.levels.ERROR)
        return nil
    end

    local csproj_content = read_file(csproj.file)
    local root_namespace = get_root_namespace(csproj_content)
    if root_namespace == nil then
        root_namespace = csproj.file:match("([^/]+)%.csproj$")
    end

    local relative_path = string.sub(dir, string.len(csproj.dir) + 2, string.len(dir) - 1)
    local namespace = root_namespace .. "." .. relative_path:gsub("/", ".")

    return {
        values = {
            cs_namespace = namespace
        },
        templates = {
            {
                text = "C# class",
                file_name_title = "Class name",
                file_name_template = "$(file_name).cs",
                cursor_start_row = 5,
                template = [[
namespace $(cs_namespace);

public class $(file_name)
{

}
]]
            },
            {
                text = "C# interface",
                file_name_title = "Interface name",
                file_name_template = "I$(file_name).cs",
                cursor_start_row = 5,
                template = [[
namespace $(cs_namespace);

public interface I$(file_name)
{

}
]]
            },
        }
    }
end

return M

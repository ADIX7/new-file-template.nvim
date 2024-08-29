local M = {}

function M.setup()
    -- Your setup code goes here
    M.providers = {
        csharp = require('new-file-template.providers.csharp'),
    }
end

function M.oil_handler()
    local oil_ok, oil = pcall(require, "oil")
    if not oil_ok then
        vim.notify("Oil not found", vim.log.levels.ERROR)
        return
    end

    local dir = require('oil').get_current_dir() -- Get the current directory from oil.nvim

    local new_files = {}
    local global_values = {}

    for _, provider in pairs(M.providers) do
        local options = provider.get_new_file_options(dir)
        if options ~= nil then
            if options.values ~= nil then
                for key, value in pairs(options.values) do
                    global_values[key] = value
                end
            end

            for _, template in pairs(options.templates) do
                table.insert(new_files, template)
            end
        end
    end

    vim.ui.select(new_files,
        {
            prompt = "Select a filetype: ",
            format_item = function(item)
                return item.text
            end,
        },
        function(selected)
            if not selected then
                return
            end
            -- Create the file and write specific content
            local user_selected_filename = vim.fn.input(selected.file_name_title .. ': ', '')

            local engine = require('new-file-template.template-text')

            local values = {
                file_name = user_selected_filename
            }

            for key, value in pairs(global_values) do
                values[key] = value
            end

            if selected.values ~= nil then
                for key, value in pairs(selected.values) do
                    values[key] = value
                end
            end

            local ok, filename_parse_result = engine.parse(selected.file_name_template, {}, values)

            if not ok then
                vim.notify("Error parsing filename: " .. filename_parse_result, vim.log.levels.ERROR)
                return
            end

            local ok, filename = filename_parse_result.evaluate()

            if not ok then
                vim.notify(table.concat(filename, "\n"), vim.log.levels.ERROR)
                return
            end

            local content_template = selected.template
            local ok, content_parsed_result = engine.parse(content_template, {}, values)

            if not ok then
                vim.notify("Error parsing content template: " .. content_parsed_result, vim.log.levels.ERROR)
                return
            end

            local ok, content = content_parsed_result.evaluate()

            if not ok then
                vim.notify(table.concat(content, "\n"), vim.log.levels.ERROR)
                return
            end

            if dir:sub(-1) == '/' then
                dir = dir:sub(1, -2)
            end

            local full_path = dir .. '/' .. filename

            local file = io.open(full_path, "w")
            if file then
                file:write(content)
                file:close()
                -- Optionally, open the file in a new buffer
                vim.cmd('edit ' .. full_path)

                if selected.cursor_start_row ~= nil then
                    vim.api.nvim_win_set_cursor(0, {selected.cursor_start_row, 0})
                end
            else
                vim.notify("Error creating file: " .. filename, vim.log.levels.ERROR)
            end
        end
    )
end

return M

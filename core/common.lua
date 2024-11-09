import("net.http")
import("utils.archive")
import("platform")
import("devel.git")
import("lib.detect.find_tool")
import("async.runjobs")

--local common = {}

function xlings_str_format(s)
    return tostring(s):gsub("\\", "\\\\")
            :gsub("\n", "\\n")
            :gsub("\"", "\\\"")
            :gsub("\t", "\\t")
            :gsub("\r", "\\r")
            -- remove ansi color
            -- https://github.com/fluent/fluent-bit/discussions/6151
            -- strip ansi https://stackoverflow.com/a/49209650/368691
            :gsub('[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]', '')
end

function xlings_str_split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from-1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

function xlings_str_trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- lua style (only support var)
function xlings_config_file_parse(filename)
    local config = {}
    local file, err
    try
    {
        function()
            file = io.open(filename, "r")
        end,
        catch
        {
            function (e)
                err = e
            end
        }
    }
    
    if not file then
        cprint("${yellow}[xlings]: " .. err)
        os.sleep(1000)
        return config
    end

    local multi_line_value = false
    local key, value
    for line in file:lines() do
        -- not match
        if multi_line_value then
            if line:find("]]") then
                config[key] = config[key] .. "\n" .. line:sub(1, -3)
                multi_line_value = false
            else
                config[key] = config[key] .. "\n" .. line
            end
        else
            -- key only match a_b_id -> id
            key, value = line:match("(%w+)%s*=%s*(.+)")
            if key and value then
                --value = value:trim()
                value = value:match("^%s*(.-)%s*$")
                if value:sub(1, 1) == "\"" and value:sub(-1) == "\"" then
                    value = value:sub(2, -2)
                elseif value:sub(1, 2) == "[[" then
                    value = value:sub(3)
                    multi_line_value = true
                end
                config[key] = value
            end
        end
    end
    file:close()
    return config
end

function xlings_save_config_to_file(config, file)
    local file, err = io.open(file, "w")

    if not file then
        print("[xlings]: Error opening file: " .. err)
        return
    end

    for k, v in pairs(config) do
        file:write(k .. " = \"" .. v .. "\"\n")
    end
    file:close()
end

function xlings_exec(cmd)
    os.exec(platform.get_config_info().cmd_wrapper .. tostring(cmd))
end

function xlings_run_bat_script(content, use_adnim) -- only for windows
    local script_file = path.join(platform.get_config_info().rcachedir, "win_tmp.bat")
    xlings_create_file_and_write(script_file, content)
    if use_adnim then
        os.exec([[powershell -Command "Start-Process ']] .. script_file .. [[' -Verb RunAs -Wait]])
    else
        os.exec(script_file)
    end
end

function xlings_python(file)
    if os.host() == "windows" then
        file = file:gsub("/", "\\")
        xlings_exec("python " .. file)
    else
        xlings_exec("python3 " .. file)
    end
end

function xlings_clear_screen()
    --[[
        if os.host() == "windows" then
            os.exec("xligns_clear.bat")
        else
            os.exec("clear")
        end
    ]]
    os.exec(platform.get_config_info().cmd_clear)
end

function xlings_download(url, dest)
    cprint("[xlings]: downloading %s to %s", url, dest)

    local tool = find_tool("curl")
    if tool then -- support progress-bar
        local outputdir = path.directory(dest)
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end
        -- -#, --progress-bar
        -- -L, --location):
        xlings_exec(tool.program .. " -L -# -o " .. dest .. " " .. url)
        --os.vrunv(tool.program, {"-#", "-o", dest, url})
    else
        -- { insecure = true }
        runjobs("download",function () http.download(url, dest) end, { progress = true })
    end
end

function xlings_create_file_and_write(file, content)
    local file, err = io.open(file, "w")

    if not file then
        print("[xlings]: Error opening file: " .. err)
        return
    end

    file:write(content)
    file:close()
end

function xlings_file_append(file, content)
    local file, err = io.open(file, "a")

    if not file then
        print("[xlings]: Error opening file: " .. err)
        return
    end

    file:write(content)
    file:close()
end

function xlings_read_file(file)
    local file, err = io.open(file, "r")

    if not file then
        print("[xlings]: Error opening file: " .. err)
        return
    end

    local content = file:read("*a")
    file:close()
    return content
end

function xlings_path_format(path)
    path = tostring(path)

    path = path:gsub("\\", "/")
    
    -- remove ./
    path = path:gsub("%./", "")
    
    -- remove ../
    --path = path:gsub("%.%.%/", "")
    
    -- /// -> /
    path = path:gsub("/+", "/")

    -- remove leading and trailing whitespaces
    path = string.gsub(path, "^%s*(.-)%s*$", "%1")

    return path
end

function xlings_install()

    xlings_uninstall() -- TODO: avoid delete mdbook?

    cprint("[xlings]: install xlings to %s", platform.get_config_info().install_dir)

    local install_dir = platform.get_config_info().install_dir
    -- cp xliings to install_dir and force overwrite
    os.cp(platform.get_config_info().sourcedir, install_dir, {force = true})

    -- add bin to linux bashrc and windows's path env
    cprint("[xlings]: add bin to linux's .bashrc or windows's path env")

    if is_host("linux") then
        local bashrc = os.getenv("HOME") .. "/.bashrc"
        local content = "\nexport PATH=$PATH:" .. install_dir .. "/bin"
        -- append to bashrc when not include xlings str in .bashrc
        if not os.isfile(bashrc) then
            xlings_create_file_and_write(bashrc, content)
        else
            local bashrc_content = io.readfile(bashrc)
            if not string.find(bashrc_content, content) then
                xlings_file_append(bashrc, content)
            end
        end
    else
        local path_env = os.getenv("PATH")
        if not string.find(path_env, install_dir) then

            path_env = path_env .. ";" .. install_dir
            -- os.setenv("PATH", path_env) -- only tmp, move to install.win.bat
            -- os.exec("setx PATH " .. path_env)
        end
    end
end

function xlings_uninstall()
    local install_dir = platform.get_config_info().install_dir
    try
    {
        function()
            os.rm(install_dir)
        end,
        catch
        {
            function (e)
                -- TODO: error: cannot remove directory C:\Users\Public\xlings Unknown Error (145)
            end
        }
    }

    cprint("[xlings]: xlings uninstalled(" .. install_dir .. ") - ok")

end

function xlings_update()
    cprint("[xlings]: try to update xlings...")
    local install_dir = platform.get_config_info().install_dir
    git.pull({remote = "origin", tags = true, branch = "main", repodir = install_dir})
end

-- download repo from git_url to destination directory
function xlings_download_repo(git_url, dest_dir)
    local repo_name = git_url:match("([^/]+)%.git$")
    dest_dir = dest_dir .. "/" .. repo_name
    cprint("[xlings]: downloading ${magenta}%s${clear} from %s", repo_name, git_url)
    if os.isdir(dest_dir) then
        cprint("[xlings]: " .. repo_name .. " already exists.")
        return
    end
    git.clone(
        git_url,
        {
            depth = 1, branch = "main",
            outputdir = dest_dir, recursive = true,
        }
    )
    cprint("[xlings]: %s - ${green}ok${clear}", dest_dir)
end

--return common
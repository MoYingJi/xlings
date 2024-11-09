import("installer.vscode")
import("installer.visual_studio")
import("installer.mdbook")
import("installer.gcc")
import("installer.c_and_cpp")
import("installer.python")
import("installer.devcpp")
import("installer.vcpp6")
import("installer.rust")

local supported_installers = {
    ["vscode"]    = vscode,
    ["mdbook"]    = mdbook,
    ["vs"]        = visual_studio,
    ["devcpp"]    = devcpp,
    ["devc++"]    = devcpp,
    ["vc++6.0"]   = vcpp6,
    ["c"]         = c_and_cpp,
    ["cpp"]       = c_and_cpp,
    ["c++"]       = c_and_cpp,
    ["gcc"]       = gcc,
    ["g++"]       = gcc,
    ["python"]    = python,
    ["python3"]   = python,
    ["rust"]      = rust,
}

function list()
    cprint("\t${bright}xinstaller lists${clear}")
    for name, x_installer in pairs(supported_installers) do
        if x_installer.support()[os.host()] then
            print(" " .. name)
        end
    end
end

function get_installer(name)
    local installer = supported_installers[name]
    if installer then
        return installer
    else
        cprint("[xlings]: ${red}installer not found${clear} - ${green}%s${clear}", name)
    end
end


local function print_info(info, name)
    if not info then return end

    cprint("\n--- ${cyan}info${clear}")

    local fields = {
        {key = "name", label = "name"},
        {key = "homepage", label = "homepage"},
        {key = "author", label = "author"},
        {key = "maintainers", label = "maintainers"},
        {key = "licenses", label = "licenses"},
        {key = "github", label = "github"},
        {key = "docs", label = "docs"},
        --{key = "profile", label = "profile"}
    }

    cprint("")
    for _, field in ipairs(fields) do
        local value = info[field.key]
        if value then
            cprint(string.format("${bright}%s:${clear} ${dim}%s${clear}", field.label, value))
        end
    end

    cprint("")

    if info["profile"] then
        cprint( "\t${green bright}" .. info["profile"] .. "${clear}")
    end

    cprint("")

end

function support(name)
    local x_installer = get_installer(name)
    if x_installer then
        if x_installer.support()[os.host()] then
            return true
        else
            cprint("[xlings]: ${red}<%s>-platform not support${clear} - ${green}%s${clear}", os.host(), name)
        end
    end

    return false

end

function installed(name)
    local x_installer = get_installer(name)
    if x_installer then
        return x_installer.installed()
    end
    return false
end

function install(name, x_installer, req_confirm)

    -- please input y or n
    if req_confirm then
        cprint("[xlings]: ${bright}install %s? (y/n)", name)
        local confirm = io.read()
        if confirm ~= "y" then
            return
        end
    end

    local success = x_installer.install()

    if success then
        cprint("[xlings]: ${green bright}" .. name .. "${clear} already installed(${yellow}takes effect in a new terminal or cmd${clear})")
    else
        cprint("[xlings]: ${red}" .. name .. " install failed or not support, clear cache and retry${clear}")
        install(name, x_installer)
    end

end

function uninstall()
    -- TODO
end

function main(name, options)

    if options == nil then
        options = { -- default config
            confirm = true,
            info = false,
            feedback = false,
        }
    end

    if support(name) then
        local x_installer = get_installer(name)

        if x_installer.info and options.info then
            local info = x_installer.info()
            print_info(info, name)
        end

        if x_installer.installed() then
            cprint("[xlings]: already installed - ${green bright}" .. name .. "${clear}")
        else
            install(name, x_installer, options.confirm)
        end

    end

    if options.feedback then

        cprint("\n\t\t${blue}反馈 & 交流 | Feedback & Discourse${clear}")
        cprint(
            "${bright}\n" ..
            "\thttps://forum.d2learn.org/category/9/xlings\n" ..
            "\thttps://github.com/d2learn/xlings/issues\n" ..
            "${clear}"
        )

    end

end
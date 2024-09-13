import("platform")
import("common")

local config = platform.get_config_info()

local vscode_url = {
    linux = "https://vscode.download.prss.microsoft.com/dbazure/download/stable/38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40/code_1.93.1-1726079302_amd64.deb",
    windows = "https://vscode.download.prss.microsoft.com/dbazure/download/stable/38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40/VSCodeUserSetup-x64-1.93.1.exe",
}

local vscode_package = {
    linux = "vscode.deb",
    windows = "vscode_setup.exe",
}

local vscode_file = path.join(config.rcachedir, vscode_package[os.host()])

function installed()
    if os.host() == "windows" then
        
    elseif os.host() == "linux" or os.host() == "macosx" then
    	return try {
            function()
                os.exec("code --version")
                return true
            end, catch {
                function(e)
                    return false
                end
            }
        }
    else
        -- TODO
    end
    return false
end

function install()
    print("[xlings]: Installing vscode...")

    local url = vscode_url[os.host()]

    if not os.isfile(vscode_file) then
        common.xlings_download(url, vscode_file)
    end

    if os.host() == "windows" then
        -- TODO: install vscode on windows
    elseif os.host() == "linux" then
        os.exec("sudo dpkg -i " .. vscode_file)
    elseif os.host() == "macosx" then
        -- TODO: install vscode on macosx
    end
end

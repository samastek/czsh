# Install-CustomPowerShell.ps1
# PowerShell customization script

#############################################################################################
###################### PARAMETERS #######################
#############################################################################################

param (
    [switch]$CopyHistory = $false,
    [switch]$NonInteractive = $true,
    [switch]$InstallPoshOpenAI = $false
)

# Import utility functions
. (Join-Path $PSScriptRoot "Utils.ps1")

#############################################################################################
###################### VARIABLES #######################
#############################################################################################

# Base configuration paths
$ConfigRoot = Join-Path $env:USERPROFILE ".config"
$CustomPSFolder = Join-Path $ConfigRoot "cposh"
$OhMyPoshFolder = Join-Path $CustomPSFolder "oh-my-posh"
$CustomModulesPath = Join-Path $CustomPSFolder "Modules"
$CustomThemesPath = Join-Path $CustomPSFolder "Themes"
$CustomScriptsPath = Join-Path $CustomPSFolder "Scripts"
$CustomBinPath = Join-Path $CustomPSFolder "bin"

# Repository URLs
$OhMyPoshRepoUrl = "https://github.com/JanDeDobbeleer/oh-my-posh.git"
$FzfRepoUrl = "https://github.com/junegunn/fzf.git"
$LazyDockerRepoUrl = "https://github.com/jesseduffield/lazydocker.git"

# Installation paths
$FzfInstallPath = Join-Path $CustomPSFolder "fzf"
$LazyDockerInstallPath = Join-Path $CustomPSFolder "lazydocker"

# Plugin mapping (modules to install)
$ModulesToInstall = @{
    "PSReadLine" = "Latest"
    "posh-git" = "Latest"
    "Terminal-Icons" = "Latest"
    "PSFzf" = "Latest"
    "z" = "Latest"
    "CompletionPredictor" = "Latest"
}

# Additional module repos
$AdditionalModuleRepos = @{
    "forgit" = "https://github.com/wfxr/forgit.git"
}

# Font files to download
$NerdFonts = @(
    @{
        Name = "HackNerdFont-Regular.ttf"
        Url = "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"
    },
    @{
        Name = "RobotoMonoNerdFont-Regular.ttf"
        Url = "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf"
    },
    @{
        Name = "DejaVuSansMNerdFont-Regular.ttf"
        Url = "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf"
    }
)

#############################################################################################
###################### FUNCTIONS #######################
#############################################################################################

function Test-Prerequisites {
    $missingPrereqs = @()
    $prerequisites = @("git", "curl", "pwsh")
    
    foreach ($prereq in $prerequisites) {
        if (-not (Get-Command $prereq -ErrorAction SilentlyContinue)) {
            $missingPrereqs += $prereq
        }
    }
    
    return $missingPrereqs
}

function Install-MissingPrerequisites {
    param (
        [string[]]$MissingPackages
    )
    
    if ($MissingPackages.Count -eq 0) {
        return
    }
    
    LogInfo "Installing missing prerequisites: $($MissingPackages -join ', ')"
    
    # Try to use winget if available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        foreach ($package in $MissingPackages) {
            LogProgress "Installing $package using winget..."
            winget install --id $package --accept-source-agreements --accept-package-agreements
        }
    }
    # Fallback to chocolatey if available
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        foreach ($package in $MissingPackages) {
            LogProgress "Installing $package using chocolatey..."
            choco install $package -y
        }
    }
    else {
        LogError "No package manager found. Please install the following packages manually: $($MissingPackages -join ', ')"
        exit 1
    }
}

function Backup-ExistingProfile {
    $profilePath = $PROFILE.CurrentUserAllHosts
    
    if (Test-Path $profilePath) {
        $backupPath = "$profilePath-backup-$(Get-Date -Format 'yyyy-MM-dd')"
        Copy-Item -Path $profilePath -Destination $backupPath -Force
        LogInfo "Backed up existing profile to $backupPath"
    }
}

function Install-PowerShellModules {
    LogInfo "Installing PowerShell modules..."
    
    # Ensure PSGallery is trusted
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        LogInfo "Set PSGallery as a trusted repository"
    }
    
    # Install modules from PSGallery
    foreach ($moduleName in $ModulesToInstall.Keys) {
        $version = $ModulesToInstall[$moduleName]
        
        try {
            if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                LogProgress "Installing $moduleName module..."
                if ($version -eq "Latest") {
                    Install-Module -Name $moduleName -Scope CurrentUser -Force
                }
                else {
                    Install-Module -Name $moduleName -Scope CurrentUser -RequiredVersion $version -Force
                }
                LogInfo "✅ $moduleName module installed"
            }
            else {
                LogInfo "✅ $moduleName module is already installed"
            }
        }
        catch {
            LogError "Failed to install $moduleName module: $_"
        }
    }
    
    # Install modules from git repositories
    foreach ($moduleName in $AdditionalModuleRepos.Keys) {
        $repoUrl = $AdditionalModuleRepos[$moduleName]
        $modulePath = Join-Path $CustomModulesPath $moduleName
        
        if (Test-Path $modulePath) {
            LogInfo "✅ $moduleName is already installed"
            git -C $modulePath pull
        }
        else {
            LogProgress "Installing $moduleName..."
            git clone --depth=1 $repoUrl $modulePath
            LogInfo "✅ $moduleName installed"
        }
    }
}

function Install-OhMyPosh {
    LogInfo "Installing Oh My Posh..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install JanDeDobbeleer.OhMyPosh -s winget
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install oh-my-posh -y
    }
    else {
        # Fallback to direct installation
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
    }
    
    # Download themes
    if (-not (Test-Path $CustomThemesPath)) {
        New-Item -Path $CustomThemesPath -ItemType Directory -Force | Out-Null
    }
    
    # Download a few popular themes
    $themesToDownload = @("jandedobbeleer", "powerlevel10k_rainbow", "agnoster", "atomic", "paradox")
    foreach ($theme in $themesToDownload) {
        $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.json"
        $themePath = Join-Path $CustomThemesPath "$theme.omp.json"
        
        if (-not (Test-Path $themePath)) {
            LogProgress "Downloading $theme theme..."
            Invoke-WebRequest -Uri $themeUrl -OutFile $themePath
        }
    }
    
    LogInfo "✅ Oh My Posh installed with themes"
}

function Install-NerdFonts {
    LogInfo "Installing Nerd Fonts..."
    
    $fontsFolder = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (-not (Test-Path $fontsFolder)) {
        New-Item -Path $fontsFolder -ItemType Directory -Force | Out-Null
    }
    
    foreach ($font in $NerdFonts) {
        $fontPath = Join-Path $fontsFolder $font.Name
        
        if (-not (Test-Path $fontPath)) {
            LogProgress "Downloading $($font.Name)..."
            Invoke-WebRequest -Uri $font.Url -OutFile $fontPath
            
            # Register the font for Windows
            $objShell = New-Object -ComObject Shell.Application
            $objFolder = $objShell.Namespace($fontsFolder)
            $objFolder.CopyHere($fontPath, 0x10)
            
            LogInfo "✅ $($font.Name) installed"
        }
        else {
            LogInfo "✅ $($font.Name) is already installed"
        }
    }
}

function Install-Fzf {
    LogInfo "Installing fzf..."
    
    if (-not (Test-Path $FzfInstallPath)) {
        git clone --depth 1 $FzfRepoUrl $FzfInstallPath
        
        # Run fzf installer
        Set-Location $FzfInstallPath
        & "$FzfInstallPath\install.ps1" --all --key-bindings --completion --no-update-rc
        Set-Location $PSScriptRoot
        
        LogInfo "✅ fzf installed"
    }
    else {
        LogInfo "✅ fzf is already installed"
        git -C $FzfInstallPath pull
    }
}

function Install-LazyDocker {
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        LogWarning "Go is not installed. Skipping LazyDocker installation."
        return
    }
    
    LogInfo "Installing LazyDocker..."
    
    if (-not (Test-Path $LazyDockerInstallPath)) {
        git clone --depth 1 $LazyDockerRepoUrl $LazyDockerInstallPath
        
        # Build LazyDocker
        Set-Location $LazyDockerInstallPath
        go install
        Set-Location $PSScriptRoot
        
        LogInfo "✅ LazyDocker installed"
    }
    else {
        LogInfo "✅ LazyDocker is already installed"
        git -C $LazyDockerInstallPath pull
        Set-Location $LazyDockerInstallPath
        go install
        Set-Location $PSScriptRoot
    }
}

function Install-TodoTxt {
    LogInfo "Installing todo.txt-cli..."
    
    $todoPath = Join-Path $CustomPSFolder "todo"
    $todoBinPath = Join-Path $CustomBinPath "todo.ps1"
    
    if (-not (Test-Path $todoPath)) {
        New-Item -Path $todoPath -ItemType Directory -Force | Out-Null
        
        # Download todo.txt
        $todoZipUrl = "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.zip"
        $todoZipPath = Join-Path $env:TEMP "todo.zip"
        
        Invoke-WebRequest -Uri $todoZipUrl -OutFile $todoZipPath
        Expand-Archive -Path $todoZipPath -DestinationPath $todoPath -Force
        Remove-Item $todoZipPath
        
        # Create PowerShell wrapper
        $todoScript = @"
#!/usr/bin/env pwsh
`$todoPath = Join-Path `"$todoPath`" "todo.sh"
if (Get-Command bash -ErrorAction SilentlyContinue) {
    bash `"`$todoPath`" `$args
} else {
    Write-Error "bash is required to run todo.txt-cli"
}
"@
        
        Set-Content -Path $todoBinPath -Value $todoScript
        
        # Copy config
        Copy-Item -Path (Join-Path $todoPath "todo.cfg") -Destination (Join-Path $env:USERPROFILE ".todo.cfg") -Force
        
        LogInfo "✅ todo.txt-cli installed"
    }
    else {
        LogInfo "✅ todo.txt-cli is already installed"
    }
}

function Setup-PoshOpenAI {
    LogInfo "Setting up PowerShell OpenAI integration..."
    
    $poshOpenAIModulePath = Join-Path $CustomModulesPath "PoshOpenAI"
    
    if (-not (Test-Path $poshOpenAIModulePath)) {
        New-Item -Path $poshOpenAIModulePath -ItemType Directory -Force | Out-Null
        
        # Create basic OpenAI wrapper module
        $poshOpenAIScript = @"
# PoshOpenAI.psm1
function Invoke-AICommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0, ValueFromPipeline = `$true)]
        [string]`$Prompt,
        
        [Parameter()]
        [string]`$ApiKey = `$(Get-Content -Path (Join-Path `$env:USERPROFILE ".config/posh_openai.ini") -ErrorAction SilentlyContinue | Where-Object { `$_ -match "api_key=" } | ForEach-Object { `$_.Split('=')[1].Trim() })
    )
    
    if (-not `$ApiKey) {
        Write-Error "API key not found. Please set one in ~/.config/posh_openai.ini"
        return
    }
    
    `$headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer `$ApiKey"
    }
    
    `$body = @{
        model = "gpt-4"
        messages = @(
            @{
                role = "user"
                content = `$Prompt
            }
        )
        temperature = 0.7
    } | ConvertTo-Json
    
    try {
        `$response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers `$headers -Body `$body
        return `$response.choices[0].message.content
    }
    catch {
        Write-Error "API request failed: `$_"
    }
}

Export-ModuleMember -Function Invoke-AICommand
"@
        
        Set-Content -Path (Join-Path $poshOpenAIModulePath "PoshOpenAI.psm1") -Value $poshOpenAIScript
        
        # Create module manifest
        New-ModuleManifest -Path (Join-Path $poshOpenAIModulePath "PoshOpenAI.psd1") `
            -RootModule "PoshOpenAI.psm1" `
            -Author "CustomPowerShell" `
            -CompanyName "User" `
            -Description "OpenAI integration for PowerShell" `
            -PowerShellVersion "5.1" `
            -FunctionsToExport @("Invoke-AICommand")
        
        # Create config file template
        $configContent = @"
[openai]
api_key=TOBEREPLEACED
"@
        
        $configPath = Join-Path $ConfigRoot "posh_openai.ini"
        Set-Content -Path $configPath -Value $configContent
        
        # Get API key from user
        $apiKey = Read-Host "Enter your OpenAI API key" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
        $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        (Get-Content $configPath) -replace "TOBEREPLEACED", $plainApiKey | Set-Content $configPath
        
        LogInfo "✅ PowerShell OpenAI integration set up"
    }
    else {
        LogInfo "✅ PowerShell OpenAI integration is already set up"
    }
}

function Copy-BashHistory {
    if ($CopyHistory) {
        LogInfo "Copying bash history to PowerShell history..."
        
        $bashHistoryPath = Join-Path $env:USERPROFILE ".bash_history"
        $pwshHistoryPath = (Get-PSReadlineOption).HistorySavePath
        
        if (Test-Path $bashHistoryPath) {
            # Simple conversion - bash history to PowerShell history format
            $bashHistory = Get-Content $bashHistoryPath
            $pwshHistory = foreach ($line in $bashHistory) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $line
                }
            }
            
            # Append to PowerShell history
            $pwshHistory | Add-Content -Path $pwshHistoryPath
            LogInfo "✅ Bash history copied to PowerShell history"
        }
        else {
            LogWarning "Bash history file not found"
        }
    }
    else {
        LogWarning "Not copying bash history to PowerShell history, as -CopyHistory is not supplied"
    }
}

function Create-ProfileScript {
    LogInfo "Creating PowerShell profile..."
    
    $profileDir = Split-Path $PROFILE.CurrentUserAllHosts -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    $profileContent = @"
# PowerShell Profile
# Generated by CustomPowerShell install script

# Add custom paths to PATH
`$env:PATH = "`$env:PATH;$CustomBinPath;$FzfInstallPath;$CustomScriptsPath;C:\Program Files\Git\bin"

# Import modules
Import-Module posh-git
Import-Module Terminal-Icons
Import-Module PSReadLine
Import-Module z


# PSReadLine configuration
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward


# Custom aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name g -Value git
Set-Alias -Name ld -Value lazydocker
Set-Alias -Name touch -Value New-Item

# Load custom scripts
Get-ChildItem -Path "$CustomPSFolder\zshrc\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . `$_.FullName }

# Custom prompt (optional alternative to Oh My Posh)
function prompt {
    `$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = [Security.Principal.WindowsPrincipal] `$identity
    `$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    `$prefix = if (`$principal.IsInRole(`$adminRole)) { "[ADMIN] " } else { "" }
    `$path = `$executionContext.SessionState.Path.CurrentLocation.Path
    `$userPrompt = if (`$env:COMPUTERNAME) { "`$env:USERNAME@`$env:COMPUTERNAME" } else { "`$env:USERNAME" }
    
    Write-Host ""
    Write-Host "`$prefix`$userPrompt" -NoNewline -ForegroundColor Blue
    Write-Host " " -NoNewline
    Write-Host "`$path" -NoNewline -ForegroundColor Yellow
    Write-Host " " -NoNewline
    
    # Git status if in a repo
    `$gitStatus = Get-GitStatus -ErrorAction SilentlyContinue
    if (`$gitStatus) {
        Write-Host "[" -NoNewline
        Write-Host "`$(`$gitStatus.Branch)" -NoNewline -ForegroundColor Cyan
        Write-Host "]" -NoNewline
    }
    
    return "`n▶ "
}

# Use Oh My Posh by default (comment this line to use the custom prompt above)
"@
    
    # Add PoshOpenAI module import if installed
    if ($InstallPoshOpenAI) {
        $profileContent += @"

# Import PoshOpenAI module
Import-Module PoshOpenAI
"@
    }
    
    Set-Content -Path $PROFILE.CurrentUserAllHosts -Value $profileContent
    LogInfo "✅ PowerShell profile created at $($PROFILE.CurrentUserAllHosts)"
}

function Finish-Installation {
    LogInfo "Installation complete!"
    
    if ($NonInteractive) {
        LogInfo "Installation complete. Start a new PowerShell session to load the configuration."
    }
    else {
        LogInfo "Reloading PowerShell profile..."
        try {
            . $PROFILE.CurrentUserAllHosts
            LogInfo "PowerShell profile loaded successfully."
        }
        catch {
            LogError "Failed to load PowerShell profile: $_"
            LogInfo "Please start a new PowerShell session to apply changes."
        }
    }
    
    LogInfo "To customize further, place your PowerShell scripts in $CustomPSFolder\zshrc\"
}

#############################################################################################
###################### MAIN SCRIPT #######################
#############################################################################################

# Create banner
Write-Host "`n===== Custom PowerShell Environment Setup =====`n" -ForegroundColor Cyan

# Check for missing prerequisites
$missingPrereqs = Test-Prerequisites
if ($missingPrereqs.Count -gt 0) {
    Install-MissingPrerequisites -MissingPackages $missingPrereqs
}

# Create directory structure
$directories = @(
    $CustomPSFolder,
    $CustomModulesPath,
    $CustomThemesPath,
    $CustomScriptsPath,
    $CustomBinPath,
    (Join-Path $CustomPSFolder "zshrc")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Backup existing profile
Backup-ExistingProfile

# Install components
Install-PowerShellModules
Install-OhMyPosh
Install-NerdFonts
Install-Fzf

# Install LazyDocker if Go is available
if (Get-Command go -ErrorAction SilentlyContinue) {
    Install-LazyDocker
}
else {
    LogWarning "Go not found. Skipping LazyDocker installation."
}

Install-TodoTxt

# Set up OpenAI integration if requested
if ($InstallPoshOpenAI) {
    Setup-PoshOpenAI
}

# Copy bash history if requested
Copy-BashHistory

Create-ProfileScript

# Finish installation
Finish-Installation
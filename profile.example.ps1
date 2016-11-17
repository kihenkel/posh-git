Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-git module from current directory
Import-Module .\posh-git

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
# Import-Module posh-git


# Set up a simple prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    $BackgroundColor = [ConsoleColor]::DarkGray
    $InputSymbol = [char]0x258c

    $IndexOfFirstSlash = $pwd.ProviderPath.IndexOf("\")
    $IndexOfLastSlash = $pwd.ProviderPath.LastIndexOf("\")
    $ShortProviderPath = ""

    if($IndexOfFirstSlash -eq $IndexOfLastSlash) {
      $ShortProviderPath = $pwd.ProviderPath
    } else {
      $ShortProviderPath = $pwd.ProviderPath.Substring(0, $IndexOfFirstSlash + 1) + "..." + $pwd.ProviderPath.Substring($IndexOfLastSlash)
    }
    
    $FancyProviderPath = "$($InputSymbol)$($ShortProviderPath)"

    Write-Host $FancyProviderPath -nonewline -BackgroundColor $BackgroundColor

    Write-VcsStatus -BackgroundColor $BackgroundColor

    Write-Host " " -nonewline -BackgroundColor $BackgroundColor

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "$($InputSymbol)"
}

Pop-Location

Start-SshAgent -Quiet

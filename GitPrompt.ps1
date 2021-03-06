# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$DefaultBackgroundColor = [ConsoleColor]::DarkGray

$global:GitPromptSettings = New-Object PSObject -Property @{
    DefaultForegroundColor                      = $Host.UI.RawUI.ForegroundColor

    BeforeText                                  = ' ['
    BeforeForegroundColor                       = [ConsoleColor]::Yellow
    BeforeBackgroundColor                       = $DefaultBackgroundColor
    
    DelimText                                   = ' | '
    DelimForegroundColor                        = [ConsoleColor]::Yellow
    DelimBackgroundColor                        = $DefaultBackgroundColor
	
	IndexBracketColor							= [ConsoleColor]::Yellow

    AfterText                                   = ']'
    AfterForegroundColor                        = [ConsoleColor]::Yellow
    AfterBackgroundColor                        = $DefaultBackgroundColor

    LocalDefaultStatusSymbol                    = $null
    LocalDefaultStatusForegroundColor           = [ConsoleColor]::DarkGreen
    LocalDefaultStatusForegroundBrightColor     = [ConsoleColor]::Green
    LocalDefaultStatusBackgroundColor           = $DefaultBackgroundColor
    
    LocalWorkingStatusSymbol                    = '!'
    LocalWorkingStatusForegroundColor           = [ConsoleColor]::DarkRed
    LocalWorkingStatusForegroundBrightColor     = [ConsoleColor]::Red
    LocalWorkingStatusBackgroundColor           = $DefaultBackgroundColor
    
    LocalStagedStatusSymbol                     = '~'
    LocalStagedStatusForegroundColor            = [ConsoleColor]::Cyan
    LocalStagedStatusBackgroundColor            = $DefaultBackgroundColor

    BranchUntrackedSymbol                       = [char]0x2260 # durchgestrichen
    BranchForegroundColor                       = [ConsoleColor]::Cyan
    BranchBackgroundColor                       = $DefaultBackgroundColor

    BranchIdenticalStatusToSymbol               = [char]0x263b # Smiley
    BranchIdenticalStatusToForegroundColor      = [ConsoleColor]::Cyan
    BranchIdenticalStatusToBackgroundColor      = $DefaultBackgroundColor
    
    BranchAheadStatusSymbol                     = [char]0x2191 # Up arrow
    BranchAheadStatusForegroundColor            = [ConsoleColor]::Green
    BranchAheadStatusBackgroundColor            = $DefaultBackgroundColor
    
    BranchBehindStatusSymbol                    = [char]0x2193 # Down arrow
    BranchBehindStatusForegroundColor           = [ConsoleColor]::Red
    BranchBehindStatusBackgroundColor           = $DefaultBackgroundColor
    
    BranchBehindAndAheadStatusSymbol            = [char]0x2195 # Up & Down arrow
    BranchBehindAndAheadStatusForegroundColor   = [ConsoleColor]::Yellow
    BranchBehindAndAheadStatusBackgroundColor   = $DefaultBackgroundColor

    BeforeIndexText                             = ""
    BeforeIndexForegroundColor                  = [ConsoleColor]::DarkGreen
    BeforeIndexForegroundBrightColor            = [ConsoleColor]::Green
    BeforeIndexBackgroundColor                  = $DefaultBackgroundColor

    IndexForegroundColor                        = [ConsoleColor]::DarkGreen
    IndexForegroundBrightColor                  = [ConsoleColor]::Green
    IndexBackgroundColor                        = $DefaultBackgroundColor

    WorkingForegroundColor                      = [ConsoleColor]::DarkRed
    WorkingForegroundBrightColor                = [ConsoleColor]::Red
    WorkingBackgroundColor                      = $DefaultBackgroundColor

    EnableStashStatus         = $false
    BeforeStashText           = ' {'
    BeforeStashBackgroundColor = $DefaultBackgroundColor
    BeforeStashForegroundColor = [ConsoleColor]::Red
    AfterStashText            = '}'
    AfterStashBackgroundColor = $DefaultBackgroundColor
    AfterStashForegroundColor = [ConsoleColor]::Red
    StashBackgroundColor      = $DefaultBackgroundColor
    StashForegroundColor      = [ConsoleColor]::Red

    ShowStatusWhenZero                          = $true

    AutoRefreshIndex                            = $true

    EnablePromptStatus                          = !$Global:GitMissing
    EnableFileStatus                            = $true
    RepositoriesInWhichToDisableFileStatus      = @( ) # Array of repository paths
    DescribeStyle                               = ''

    EnableWindowTitle                           = 'Check24 git ~ '

    Debug                                       = $false
}

$WindowTitleSupported = $true
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Format-BranchName($branchName){
    if ($branchName -match "\/?([A-Z]+-[0-9]+)") {
      $branchName = $matches[1]
    }

    return $branchName
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor

        $branchStatusSymbol          = $null
        $branchStatusBackgroundColor = $s.BranchBackgroundColor
        $branchStatusForegroundColor = $s.BranchForegroundColor

        if (!$status.Upstream) {
            $branchStatusSymbol          = $s.BranchUntrackedSymbol
        } elseif ($status.BehindBy -eq 0 -and $status.AheadBy -eq 0) {
            # We are aligned with remote
            $branchStatusSymbol          = $s.BranchIdenticalStatusToSymbol
            $branchStatusBackgroundColor = $s.BranchIdenticalStatusToBackgroundColor
            $branchStatusForegroundColor = $s.BranchIdenticalStatusToForegroundColor
        } elseif ($status.BehindBy -ge 1 -and $status.AheadBy -ge 1) {
            # We are both behind and ahead of remote
            $branchStatusSymbol          = $s.BranchBehindAndAheadStatusSymbol
            $branchStatusBackgroundColor = $s.BranchBehindAndAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindAndAheadStatusForegroundColor
        } elseif ($status.BehindBy -ge 1) {
            # We are behind remote
            $branchStatusSymbol          = $s.BranchBehindStatusSymbol
            $branchStatusBackgroundColor = $s.BranchBehindStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindStatusForegroundColor
        } elseif ($status.AheadBy -ge 1) {
            # We are ahead of remote
            $branchStatusSymbol          = $s.BranchAheadStatusSymbol
            $branchStatusBackgroundColor = $s.BranchAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchAheadStatusForegroundColor
        } else {
            # This condition should not be possible but defaulting the variables to be safe
            $branchStatusSymbol          = "?"
        }

        Write-Prompt (Format-BranchName($status.Branch)) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor
        
        if ($branchStatusSymbol) {
            Write-Prompt  (" {0}" -f $branchStatusSymbol) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor
        }

        if($s.EnableFileStatus -and $status.HasIndex) {
			Write-Prompt " ("  -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.IndexBracketColor
			$totalIndexChangeCount = $status.Index.Added.Count + $status.Index.Modified.Count + $status.Index.Deleted.Count
			Write-Prompt "$($totalIndexChangeCount)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor

            if ($status.Index.Unmerged) {
                Write-Prompt " !$($status.Index.Unmerged.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            } else {
				Write-Prompt ")"  -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.IndexBracketColor
			}
        } elseif ($s.EnableFileStatus -and $status.HasWorking) {
			Write-Prompt " ("  -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.IndexBracketColor
		}

        if($s.EnableFileStatus -and $status.HasWorking) {
			$totalWorkingChangeCount = $status.Working.Added.Count + $status.Working.Modified.Count + $status.Working.Deleted.Count
			Write-Prompt "$($totalWorkingChangeCount)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor

            if ($status.Working.Unmerged) {
                Write-Prompt " !$($status.Working.Unmerged.Count)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
			Write-Prompt ")"  -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.IndexBracketColor
        }
        
        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
             Write-Prompt $s.BeforeStashText -BackgroundColor $s.BeforeStashBackgroundColor -ForegroundColor $s.BeforeStashForegroundColor
             Write-Prompt $status.StashCount -BackgroundColor $s.StashBackgroundColor -ForegroundColor $s.StashForegroundColor
             Write-Prompt $s.AfterStashText -BackgroundColor $s.AfterStashBackgroundColor -ForegroundColor $s.AfterStashForegroundColor
        }

        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$script:adminHeader$prefix$repoName [$($status.Branch)]"
        }
    } elseif ( $Global:PreviousWindowTitle ) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
    }
}

if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}
$s = $global:GitPromptSettings

# Override some of the normal colors if the background color is set to the default DarkMagenta.
if ($Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) { 
    $s.LocalDefaultStatusForegroundColor    = $s.LocalDefaultStatusForegroundBrightColor
    $s.LocalWorkingStatusForegroundColor    = $s.LocalWorkingStatusForegroundBrightColor
    
    $s.BeforeIndexForegroundColor           = $s.BeforeIndexForegroundBrightColor 
    $s.IndexForegroundColor                 = $s.IndexForegroundBrightColor 

    $s.WorkingForegroundColor               = $s.WorkingForegroundBrightColor 
}

function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}
$Global:VcsPromptStatuses += $PoshGitVcsPrompt
$ExecutionContext.SessionState.Module.OnRemove = { $Global:VcsPromptStatuses = $Global:VcsPromptStatuses | ? { $_ -ne $PoshGitVcsPrompt} }
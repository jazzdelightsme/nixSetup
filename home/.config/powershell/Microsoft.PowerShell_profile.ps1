
Set-StrictMode -Version Latest

# Who doesn't want to see hidden and system files? Nobody, that's who.
$PSDefaultParameterValues = @{ 'Get-ChildItem:Force' = $true }

if( !(($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -ne 'Win32NT')) )
{
    # TODO: why doesn't it show up for me on linux?
    Import-Module TabExpansionPlusPlus
}

<#
if( ($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Win32NT') )
{
    # I've created directory junctions so that Windows PowerShell module directories will
    # also be on the PSModulePath search path in PowerShell Core. However, sometimes this
    # can cause problems, like with a pwsh-native module being hidden behind a Windows
    # PowerShell module, and not working right.
    #
    # So let's attempt to put pwsh-specific paths first on the PSModulePath.

    $modPaths = ($env:PSModulePath).Split( ';' )

    $newPaths = @( $modPaths | ? { $_ -match    "[/\\]pwsh[/\\]" } )
    $newPaths +=   $modPaths | ? { $_ -notmatch "[/\\]pwsh[/\\]" }

    $env:PSModulePath = [string]::Join( ';', $newPaths )
}
#>

$env:GIT_EDITOR='gvim'


# Avoid errors with Invoke-WebRequest:
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if( [System.Environment]::Is64BitOperatingSystem -and
    ![System.Environment]::Is64BitProcess )
{
    # Add the 64-bit dir so that PSReadLine can be found. (They Won't-Fixed the bug to
    # make PSReadLine available on x86.)
    Write-Host "Adding native ProgramFiles PowerShell module dir to `$env:PSModulePath." -Fore Cyan
    $env:PSModulePath="$($env:PSModulePath);C:\Program Files\WindowsPowerShell\Modules"
}


Import-Module PSReadLine

# Turn off new validation behavior:
#Set-PSReadlineKeyHandler -Key Enter -Function AcceptLine

Set-PSReadlineOption -EditMode Vi
Set-PSReadlineOption -ViModeIndicator Cursor
$env:VISUAL='vim'

# SaveAtExit not working: https://github.com/lzybkr/PSReadLine/issues/262
#Set-PSReadlineOption -HistorySaveStyle SaveAtExit
Set-PSReadlineOption -HistorySaveStyle SaveIncrementally
if( $Host.Name -eq 'ColorConsoleHost' )
{
    # DbgShell
    Set-PSReadlineOption -HistorySavePath $Home\Documents\WindowsPowerShell\ps_history_dbgshell
}
elseif( ($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -ne 'Win32NT') )
{
    # TODO: better way to handle container awareness?
    #Set-PSReadlineOption -HistorySavePath /mnt/c/temp/ps_history_docker
}
else
{
    Set-PSReadlineOption -HistorySavePath $Home\Documents\WindowsPowerShell\ps_history
}

# N.B. The "Shift" in the chord does not seem to work anymore... but specifying
# a capital 'V' (instead of lowercase 'v') is what actually gets me what I
# want. C.f. https://github.com/lzybkr/PSReadLine/issues/755
Set-PSReadlineKeyHandler -ViMode Command -Chord Shift+V -Function CaptureScreen

# Let's borrow some settings from -EditMode Windows
Set-PSReadlineKeyHandler -Function CopyOrCancelLine -Chord Ctrl+c
Set-PSReadlineKeyHandler -Function Copy             -Chord Ctrl+C

Set-PSReadlineKeyHandler -Function HistorySearchBackward -Chord F8
Set-PSReadlineKeyHandler -Function HistorySearchForward  -Chord Shift+F8


Set-PSReadlineKeyHandler -Chord Shift+LeftArrow       -Function SelectBackwardChar     # Adjust the current selection to include the previous character
Set-PSReadlineKeyHandler -Chord Shift+RightArrow      -Function SelectForwardChar      # Adjust the current selection to include the next character
Set-PSReadlineKeyHandler -Chord Ctrl+Shift+LeftArrow  -Function SelectBackwardWord     # Adjust the current selection to include the previous word
Set-PSReadlineKeyHandler -Chord Ctrl+Shift+RightArrow -Function SelectNextWord         # Adjust the current selection to include the next word


# Bookmarks!
# These functions are defined later in this profile
Set-PSReadlineKeyHandler -ViMode Command -Chord m -ScriptBlock {
    param( $key, $arg )

    Write-Host "key is: $key" -fore cyan
    Write-Host "arg is: $arg" -fore cyan
    #Set-Mark $arg
    todo
}

# TODO: This is pretty hacky. Some things I would have liked from PSReadLine:
#    * a way to clear only the portion of the console screen beyond the current buffer (to clean up my debugging printfs, for example, or to clean up the prompty stuff.  Or maybe it would be nice to just have access to the _statusBuffer somehow?
#
# This marks stuff is an alternative to Jason's Ctrl+Shift+j/Ctrl+j functions: http://blogs.technet.com/b/heyscriptingguy/archive/2014/06/20/a-better-powershell-console-with-custom-psreadline-functions.aspx
Set-PSReadlineKeyHandler -ViMode Command -Chord "'" -ScriptBlock {
    param( $key, $arg )

    #Write-Host "`nAvailable marks:`n" -Fore Cyan
    #Get-Mark | Out-String | Write-Host -Fore Magenta
    #Write-Host "`nJump to mark: " -Fore Cyan

    $mark = ''

    do
    {
        $key = [Console]::ReadKey( $false )
        if( $key.Key -eq [ConsoleKey]::Escape )
        {
            break
        }
        elseif( $key.Key -eq [ConsoleKey]::Enter )
        {
            Restore-LocationFromMark $mark.Trim()
            break
        }
        else
        {
            $mark = $mark + $key.KeyChar
            $numMatches = (@(Get-Mark "$($mark)*")).Count
            #Write-Host -fore yellow "It's: $($key.Key) ($($key.KeyChar)) mark so far: $mark ($numMatches)"
            if( $numMatches -eq 1 )
            {
                Restore-LocationFromMark $mark.Trim()
                break
            }
            else
            {
                #Write-Host "(numMatches: $numMatches)" -Fore DarkMagenta
            }
        }
    } while( $true )

    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


Set-Alias fh Format-Hex

$global:razProfile = "$($env:init)\razzle_profile_stuff.ps1"
if( (Test-Path $razProfile) )
{
    . $razProfile
}


function beep()
{
    [console]::Beep( 261, 500 )
}


function gvim( $path )
{
    if( ($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -ne 'Win32NT') )
    {
        $gvim = which gvim
    }
    else
    {
        $gvim = 'gvim.exe'
    }

    if( $path )
    {
        # Unfortunately, Convert-Path et al blow chunks if the path doesn't
        # exist. So if you want to start a new file, this won't work.
        #$path = Convert-Path $path
        $path = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath( $path )
        & $gvim $path $args
    }
    else
    {
        & $gvim
    }
}

function gvl( [string] $stuff )
{
    if( ($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -ne 'Win32NT') )
    {
        throw "tbd"
    }
    #
    # Sometimes error messages use parentheses, so we want to be able to handle stuff
    # like:
    #
    #    gvl c:\path\to\something\myFile.cs(107)
    #
    # Or:
    #
    #    gvl c:\path\to\something\myFile.cs(107,37)
    #
    # GvimLauncher.exe can handle that, but the parentheses cause PowerShell parsing to
    # happen, so we may need to undo that.
    #
    if( $args.count -gt 0 )
    {
        if( $args[ 0 ] -is [object[]] )
        {
            $stuff = $stuff + ':' + $args[ 0 ][ 0 ].ToString()
        }
        else
        {
            $stuff = $stuff + ':' + $args[ 0 ].ToString()
        }
    }

    # like /mnt/m/src/WucEffectsStaging/headers/public/amd64chk/internal/sdk/inc/ucrt/vcruntime.h:83:1:
    if( $stuff -and $stuff.StartsWith( '/mnt/' ) )
    {
        $stuff = ($stuff[ 5 ] + ":" + $stuff.Substring( '/mnt/X'.Length )).Replace( '/', '\' )
    }

    if( $stuff )
    {
        C:\Tools\GvimLauncher.exe $stuff
    }
    else
    {
        gvim
    }
}

function Show-Error
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false, Position = 0, ValueFromPipeline = $true )]
           [System.Management.Automation.ErrorRecord] $ErrorRecord )

    process
    {
        try
        {
            if( !$ErrorRecord )
            {
                if( 0 -eq $global:Error.Count )
                {
                    return
                }

                $thing = $global:Error[ 0 ]

                #
                # $thing might not be an ErrorRecord...
                #

                if( $thing -is [System.Management.Automation.ErrorRecord] )
                {
                    $ErrorRecord = $thing
                }
                elseif( $thing -is [System.Management.Automation.IContainsErrorRecord] )
                {
                    "(Error is an $($thing.GetType().FullName), but contains an ErrorRecord)"
                    $ErrorRecord = $thing.ErrorRecord
                }
                else
                {
                    Write-Warning "The thing I got from `$global:Error is not an ErrorRecord..."
                    Write-Warning "(it's a $($thing.GetType().FullName))"
                    $thing | Format-List * -Force
                    return
                }
            }

            # It's convenient to store the error we looked at in the global variable $e.
            # But we don't "own" that... so we'll only set it if it hasn't already been
            # set (unless it's been set by us).
            $e_var = Get-Variable 'e' -ErrorAction Ignore
            if( ($null -eq $e_var) -or
                (($e_var.Value -ne $null) -and
                 (0 -ne $e_var.Value.PSObject.Properties.Match( 'AddedByShowError').Count)))
            {
                $global:e = $ErrorRecord
                Add-Member -InputObject $global:e `
                           -MemberType 'NoteProperty' `
                           -Name 'AddedByShowError' `
                           -Value $true `
                           -Force # overwrite if we're re-doing one
            }

            $ErrorRecord | Format-List * -Force
            $ErrorRecord.InvocationInfo | Format-List *
            $Exception = $ErrorRecord.Exception
            for( $i = 0; $Exception; $i++, ($Exception = $Exception.InnerException) )
            {   "$i" * 80
                "ExceptionType : $($Exception.GetType().FullName)"
                $Exception | Format-List * -Force
            }
        }
        finally { }
    }
}
Set-Alias ser Show-Error


<# The old implementation used a hashtable, which had some problems around value-type
keys--it required reference equality for boxed integers, which made it a pain to use.
So the new implementation uses a generic dictionary with a strongly-typed key.

function CreateIndex
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
           [object[]] $InputObject,

           [Parameter( Mandatory = $true, Position = 1 )]
           [string] $IndexProperty
         )

    begin
    {
        $ht = @{ }
    }

    end
    {
        Write-Output -NoEnumerate $ht
    }

    process
    {
        try
        {
            foreach( $obj in $InputObject )
            {
                $key = $obj.$IndexProperty
                if( !$ht.ContainsKey( $key ) )
                {
                    $null = $ht.Add( $key, (New-Object 'System.Collections.ArrayList') )
                }

                $null = $ht[ $key ].Add( $obj )
            }
        }
        finally { }
    }
} # end CreateIndex
#>


<#
.SYNOPSIS
    Given a set of objects and a property name, creates a dictionary, where the keys are the unique values of the specified property on the input objects, and the values are ArrayLists that contain objects with the corresponding values.
#>
function CreateIndex
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
           [object[]] $InputObject,

           [Parameter( Mandatory = $true, Position = 1 )]
           [string] $IndexProperty,

           [Parameter( Mandatory = $false )]
           [object] $ExistingDictionary
         )

    begin
    {
        $dict = $ExistingDictionary
    }

    end
    {
        Write-Output -NoEnumerate $dict
    }

    process
    {
        try
        {
            foreach( $obj in $InputObject )
            {
                if( $null -eq $dict )
                {
                    $t = [type]::GetType( 'System.Collections.Generic.Dictionary`2' )

                    $firstIndexProperty = $obj.$IndexProperty

                    if( $null -eq $firstIndexProperty )
                    {
                        throw "Can't have null keys."
                    }

                    $keyType = $firstIndexProperty.GetType()
                    $valType = [System.Collections.ArrayList]

                    $t = $t.MakeGenericType( @( $keyType, $valType ) )

                    $dict = $t.GetConstructor( [type]::EmptyTypes ).Invoke( @() )
                }

                $key = $obj.$IndexProperty
                if( !$dict.ContainsKey( $key ) )
                {
                    $null = $dict.Add( $key, (New-Object 'System.Collections.ArrayList') )
                }

                $null = $dict[ $key ].Add( $obj )
            }
        }
        finally { }
    }
} # end CreateIndex



function .. { pushd .. }
function ... { pushd ..\.. }
function .... { pushd ..\..\.. }
function ..... { pushd ..\..\..\.. }
function ...... { pushd ..\..\..\..\.. }
function ....... { pushd ..\..\..\..\..\.. }
function ........ { pushd ..\..\..\..\..\..\.. }
Set-Alias go Push-Location
Set-Alias back Pop-Location
#Set-Alias l Get-ChildItem

if( ($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -ne 'Win32NT') )
{
    function l { ls -lha --color $args }
}
else
{
    function l { ls.exe -l $args | sdpager.exe -c -p } # gives color and paging
}


function Count
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false, ValueFromPipeline = $true )]
           [object[]] $Item
         )

    begin { [int] $total = 0 }
    process
    {
        if( $Item ) { $total = $total + $Item.Length }
    }
    end { $total }
}


function q { exit }


if( ($PSVersionTable.PSEdition -ne 'Core') -or ($PSVersionTable.Platform -eq 'Win32NT') )
{
    function GLOBAL:mklink
    {
        & cmd.exe /c mklink $args
    }

    function GLOBAL:CmdRmdir
    {
        foreach( $arg in $args )
        {
            if( $arg -imatch '^[a-z]:\\?$' )
            {
                throw 'Really? If so, use Format-Volume instead.'
            }
        }

        & cmd.exe /c rmdir $args
    }


    function Find-InSource
    {
        findstr /spinc:"$args" *.c *.cs *.cxx *.cpp *.h *.hxx *.hpp *.idl *.wxs *.wix *.wxi *.ps1 *.psm1 *.psd1 *.psfmt *.inl *.w *.md *.pm *.pl
    }
    Set-Alias fs Find-InSource

    function Find-InWhatever
    {
        findstr /spinc:"$($args[0])" $args[1..($args.Length - 1)]
    }
    Set-Alias f Find-InWhatever


    function Find-InSourceRegex
    {
        findstr /sprinc:"$args" *.c *.cs *.cxx *.cpp *.h *.hxx *.hpp *.idl *.wxs *.wix *.wxi *.ps1 *.psm1 *.psd1 *.psfmt *.inl *.w *.md *.pm *.pl
    }
    Set-Alias fsr Find-InSourceRegex


    function Find-File( [string] $Pattern )
    {
        Get-ChildItem -Recurse | where Fullname -match $Pattern | select -ExpandProperty FullName
    }
    Set-Alias ff Find-File

    function bc3
    {
        if( [Environment]::Is64BitOperatingSystem )
        {
            & "C:\Program Files (x86)\Beyond Compare 3\BComp.exe" $args
        }
        else
        {
            & "C:\Program Files\Beyond Compare 3\BComp.exe" $args
        }
    }


    function bc4
    {
        & "C:\Program Files\Beyond Compare 4\BComp.exe" $args
    }


    function vimrc { gvim "c:\vim\_vimrc" @args }

}


function Reset-Colors
{
    "$([char]0x1b)[0m"
}



function Set-WindowTitle()
{
    $host.ui.RawUI.WindowTitle = [String]::Join( ' ', $args )
}
Set-Alias 'title' 'Set-WindowTitle' -Scope Global


function ConvertTo-Base64
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
           [string] $String
         )
    process
    {
        try
        {
            [Convert]::ToBase64String( [Text.Encoding]::Unicode.GetBytes( $String ) )
        }
        finally { }
    }
} # end ConvertTo-Base64


function ConvertFrom-Base64
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
           [string] $EncodedString
         )
    process
    {
        try
        {
            [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String( $EncodedString ) )
        }
        finally { }
    }
} # end ConvertFrom-Base64


<#
.SYNOPSIS
    Creates or sets a named "bookmark" for the current location.
#>
function Set-Mark
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true )]
           [AllowEmptyString()]
           [AllowNull()]
           [string] $Name,

           [Parameter( Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true )]
           [ValidateNotNullOrEmpty()]
           [string] $Path
         )

    begin { }
    end { }
    process
    {
        try
        {
            if( !$Path )
            {
                $location = Get-Location
                $Path = $location.ProviderPath
                if( $location.Provider.Name -ne 'FileSystem' )
                {
                    # Provider-qualified for non-filesystem paths. We do this only for
                    # non-fs paths to improve interoperability with cmd.exe.
                    $Path = "$($location.Provider)::$($location.ProviderPath)"
                }
            }

            Set-Content -Path "Env:\mark_$($Name)" -Value $Path
        }
        finally { }
    }
} # end Set-Mark

Set-Alias m Set-Mark


<#
.SYNOPSIS
    Gets the path stored in the named "bookmark(s)".
#>
function Get-Mark
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false,
                       Position = 0,
                       ValueFromPipelineByPropertyName = $true,
                       ValueFromPipeline = $true )]
           [AllowEmptyString()]
           [AllowNull()]
           [string] $Name
         )

    begin { }
    end { }
    process
    {
        try
        {
            if( !$PSBoundParameters.ContainsKey( 'Name' ) )
            {
                $Name = '*'
            }

            $markPath = "Env:\mark_$($Name)"
            if( Test-Path $markPath )
            {
                Resolve-Path $markPath | ForEach-Object {

                    [PSCustomObject] @{
                        'Name' = $_.ProviderPath.Substring( 5 ) # skip the "mark_"
                        'Path' = (Get-Content -Path $_)
                    }
                } | Sort-Object -Property Name
            }
            else
            {
                if( ![System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Name ) )
                {
                    Write-Error "No such mark(s): $Name"
                }
            }
        }
        finally { }
    }
} # end Get-Mark

# 'sm' for 'show marks'
Set-Alias sm Get-Mark


<#
.SYNOPSIS
    Removes the named "bookmark".
#>
function Remove-Mark
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true )]
           [AllowEmptyString()]
           [AllowNull()]
           [string] $Name
         )

    begin { }
    end { }
    process
    {
        try
        {
            Remove-Item "Env:\mark_$($Name)"
        }
        finally { }
    }
} # end Remove-Mark

function Clear-Marks { Remove-Mark '*' }

Set-Alias clearmarks Clear-Marks


<#
.SYNOPSIS
    Calls Push-Location with the path stored in the named "bookmark".
#>
function Restore-LocationFromMark
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0 )]
           [AllowEmptyString()]
           [AllowNull()]
           [string] $Name
         )

    begin { }
    end { }
    process
    {
        try
        {
            $markVal = Get-Mark $Name | Select -Last 1
            if( $markVal )
            {
                Push-Location $markVal.Path
            }
        }
        finally { }
    }
} # end Restore-LocationFromMark

if( $host.Name -ne 'ColorConsoleHost' ) # don't set 'g' if we are in DbgShell
{
    Set-Alias g Restore-LocationFromMark
}


# Tab completion for Mark functions
if( Get-Command Register-ArgumentCompleter -ea Ignore )
{
    Register-ArgumentCompleter -Command (Get-Command @( 'Get-Mark', 'Restore-LocationFromMark', 'Remove-Mark' )) `
                               -Parameter 'Name' `
                               -ScriptBlock {
        param( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter )

        (Get-Mark ($wordToComplete + '*')).Name
    }
}


<#
.SYNOPSIS
    Unloads then reloads a module. Note that this is really only effective for script modules, since .NET assemblies cannot be properly unloaded.
#>
function ReloadModule
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0 )]
           [string] $ModuleName,

           # Reloading modules doesn't seem to update format data.
           [Parameter( Mandatory = $false )]
           [switch] $UpdateFormatData
         )

    begin { }
    end { }
    process
    {
        try
        {
            $mi = Get-Module $ModuleName

            if( !$mi )
            {
                Write-Warning "The module $ModuleName is not loaded."
                return
            }

            $path = $mi.Path
            if( $path.EndsWith( 'psm1' ) )
            {
                $manifestPath = [System.IO.Path]::ChangeExtension( $path, '.psd1' )
                if( (Test-Path $manifestPath) )
                {
                    $path = $manifestPath
                }
            }

            Remove-Module $ModuleName

            Import-Module $path

            if( !$? )
            {
                # Perhaps someone added a typo to the module, and now it can't load.
                Write-Host "The module failed to load. Once you've fixed the errors, here is the command to load it:" -Fore Cyan
                Write-Host "Import-Module $path" -Fore Cyan
                return
            }

            if( $UpdateFormatData )
            {
                Update-FormatData
            }
        }
        finally { }
    }
} # end ReloadModule

Set-Alias remo ReloadModule

# Tab completion for ReloadModule
if( Get-Command Register-ArgumentCompleter -ea Ignore )
{
    Register-ArgumentCompleter -Command ReloadModule -Parameter 'ModuleName' -ScriptBlock {
        param( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter )

        (Get-Module ($wordToComplete + '*')).Name
    }
}


<#
.SYNOPSIS
    Gets the execution time for the specified command (or the last command, if none specified). Note that this is only useful for interactive use, as it operates on the command history (a al Get-History).
#>
function Get-CommandTime
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false, Position = 0 )]
           [int] $HistoryId
         )

    begin { }
    end { }
    process
    {
        try
        {
            if( 0 -eq $HistoryId )
            {
                $history = Get-History -Count 1 # gets the last item in history
            }
            else
            {
                if( $HistoryId -lt 0 )
                {
                    # Translate negative numbers a la other PS indexing. Note that history
                    # IDs are 1-based, but we don't +1 because by the time we get here,
                    # Get-CommandTime has already been added to the history.
                    $tmp = @( Get-History )
                    $history = $tmp[ ($tmp.Count + $HistoryId) ]
                }
                else
                {
                    $history = Get-History -Id $HistoryId
                }
            }

            $delta = $history.EndExecutionTime - $history.StartExecutionTime

            return $delta
        }
        finally { }
    }
} # end Get-CommandTime

Set-Alias gcmt Get-CommandTime


<#
.SYNOPSIS
    Makes sure each line ends with CRLF, not just LF. Also writes files back out as UTF8 with a BOM.
#>
function NormalizeLineEndings
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
           [string[]] $File,

           [Parameter( Mandatory = $false )]
           [switch] $Unix # Flip things: standardize on LF instead of CRLF
         )

    begin { }
    end { }

    process
    {
        try
        {
            $File | Resolve-Path | %{
                $path = $_

                if( (Test-Path -Type Leaf $path) )
                {
                    Write-Verbose "Processing $path"

                    $text = [System.IO.File]::ReadAllText( $path )

                    # First we'll squish everything down to a single LF. Then we can safely
                    # expand all LFs to CRLFs.

                    $text = $text.Replace( "`r`n", "`n" )
                    if( !$Unix )
                    {
                        $text = $text.Replace( "`n", "`r`n" )
                    }

                    $enc = [System.Text.Utf8Encoding]::new( $false ) # no BOM
                    [System.IO.File]::WriteAllText( $path, $text, $enc )
                }
            }
        }
        finally { }
    }
} # end NormalizeLineEndings


function RightSizeConsoleWindow()
{
    [Console]::BufferWidth = [Console]::WindowWidth
}

# Hm, I can't actually keep the scope of these private to the script (seems we
# get dot-sourced)... so I'll just give these private-looking names.
$script:___origFgColor = [Console]::ForegroundColor
$script:___origBgColor = [Console]::BackgroundColor

function RightColorConsoleWindow()
{
    [Console]::ForegroundColor = ${___origFgColor}
    [Console]::BackgroundColor = ${___origBgColor}
}


<#
.SYNOPSIS
    Run a cmd.exe script and capture environment variable and current directory
    changes back into the powershell environment.

    Adapted from http://www.leeholmes.com/blog/NothingSolvesEverythingPowerShellAndOtherTechnologies.aspx
#>
function Invoke-CmdScript
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0 )]
           [string[]] $script,

           [Parameter( Mandatory = $false,
                       ValueFromPipeline = $false,
                       ValueFromRemainingArguments = $true,
                       ParameterSetName = "other" )]
           [string[]] $params
    );

    $environmentVariablesFile = [IO.Path]::GetTempFileName()
    $workingDirectoryFile = [IO.Path]::GetTempFileName()

    ## Store the output of cmd.exe.  We also ask cmd.exe to output
    ## the environment table after the batch file completes.  The same
    ## for the current directory.

    cmd /c " `"$script`" $params && set > `"$environmentVariablesFile`" && cd > `"$workingDirectoryFile`" "

    ## Clear the environment so that any removed values get removed
    Remove-Item env:*

    # In case razzle did a cd
    Get-Content $workingDirectoryFile | Set-Location

    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $environmentVariablesFile | Foreach-Object {
        if($_ -match "^([^=].*?)=(.*)$")
        {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }

    Remove-Item $environmentVariablesFile, $workingDirectoryFile
}


function Get-DbgShellDownloadCount
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false )]
           [switch] $AllReleases
         )

    process
    {
        try
        {
            $releases = (iwr -UseBasicParsing 'https://api.github.com/repos/Microsoft/DbgShell/releases').Content | ConvertFrom-Json

            if( !$AllReleases )
            {
                $releases = @( $releases[ 0 ] )
            }

            [int] $total = 0
            foreach( $release in $releases )
            {
                $total += ((iwr -UseBasicParsing ($release.assets_url)).Content | ConvertFrom-Json).download_count
            }

            return $total
        }
        finally { }
    }
}


function gs
{
    git status
}

function BackupWipChanges
{
    git commit -am "wip"         ; if( !$? ) { throw "git commit failed" }
    git push --force-with-lease  ; if( !$? ) { throw "git push failed" }
    git reset HEAD^              ; if( !$? ) { throw "git reset failed" }
}

function glo
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false, Position = 0 )]
           [int] $NumberOfChanges = 30
         )
    begin { }
    end { }
    process
    {
        try
        {
            git log --oneline -n $NumberOfChanges
        }
        finally { }
    }
}


function Get-MyDwmProcessId
{
    (Get-Process 'DWM' | where SessionId -eq (Get-Process -Id $pid).SessionId).Id
}


function Debug-MyDwm
{
    C:\Debuggers\windbg.exe -noredirect -g -G -server tcp:port=42942:43000 -p (Get-MyDwmProcessId)
}


<#
.SYNOPSIS
    Gets a StringComparison enum value appropriate for comparing paths on the OS platform.
.OUTPUTS
    [System.StringComparison]
#>
function Get-PathStringComparison
{
    [CmdletBinding()]
    param()

    # Taken from posh-git's Utils.ps1.

    # File system paths are case-sensitive on Linux and case-insensitive on Windows and macOS
    if( ($PSVersionTable.PSVersion.Major -ge 6) -and $IsLinux )
    {
        return [System.StringComparison]::Ordinal
    }
    else
    {
        return [System.StringComparison]::OrdinalIgnoreCase
    }
}



function Test-Administrator
{
    [CmdletBinding()]
    param()

    try
    {
        # Taken from posh-git's Utils.ps1.

        # PowerShell 5.x only runs on Windows so use .NET types to check.
        # Or if we are on v6 or higher, check the $IsWindows pre-defined variable.
        if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
            $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
            return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        # Must be Linux or OSX, so use the id util. Root has userid of 0.
        return 0 -eq (id -u)
    }
    finally { }
}


<#
.SYNOPSIS
    Gets the entries in $env:PSModulePath.
#>
function Get-PSModulePath {
    # Taken from posh-git's Utils.ps1.
    return $env:PSModulePath -split ([System.IO.Path]::PathSeparator)
}


<#
.SYNOPSIS
    Returns information reported by "git status", but structured.
#>
function Get-GitStatus
{
    [CmdletBinding( DefaultParameterSetName = 'None' )]
    param( [Parameter( Mandatory = $false, ParameterSetName = 'NoUntrackedFilesParamSet' )]
           [switch] $NoUntrackedFiles,

           [Parameter( Mandatory = $false, ParameterSetName = 'AllUntrackedFilesParamSet' )]
           [switch] $AllUntrackedFiles
         )

    begin
    {
        try
        {
            # Cribbed from posh-git's GitUtils.ps1.

            function GetUniquePaths( $pathCollections )
            {
                $hash = New-Object System.Collections.Specialized.OrderedDictionary

                foreach( $pathCollection in $pathCollections )
                {
                    foreach( $path in $pathCollection )
                    {
                        $hash[ $path ] = 1
                    }
                }

                $hash.Keys
            }

            [string] $branch = $null
            [string] $upstream = $null
            [int] $aheadBy = 0
            [int] $behindBy = 0
            [bool] $gone = $false
            $indexAdded    = [System.Collections.Generic.List[string]]::new()
            $indexModified = [System.Collections.Generic.List[string]]::new()
            $indexDeleted  = [System.Collections.Generic.List[string]]::new()
            $indexUnmerged = [System.Collections.Generic.List[string]]::new()
            $filesAdded    = [System.Collections.Generic.List[string]]::new()
            $filesModified = [System.Collections.Generic.List[string]]::new()
            $filesDeleted  = [System.Collections.Generic.List[string]]::new()
            $filesUnmerged = [System.Collections.Generic.List[string]]::new()

            if( $NoUntrackedFiles )      { $untrackedOpt = '-uno' }
            elseif( $AllUntrackedFiles ) { $untrackedOpt = '-uall' }
            else                         { $untrackedOpt = '-unormal' }

            $status = git -c core.quotepath=false -c color.status=false status $untrackedOpt --porcelain=v1 --branch 2>$null

            switch -regex ($status)
            {
                '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {

                    switch( $matches[ 'index' ] )
                    {
                        'A' { $null = $indexAdded.Add(    $matches[ 'path1' ]); break }
                        'M' { $null = $indexModified.Add( $matches[ 'path1' ]); break }
                        'R' { $null = $indexModified.Add( $matches[ 'path1' ]); break }
                        'C' { $null = $indexModified.Add( $matches[ 'path1' ]); break }
                        'D' { $null = $indexDeleted.Add(  $matches[ 'path1' ]); break }
                        'U' { $null = $indexUnmerged.Add( $matches[ 'path1' ]); break }
                    }
                    switch( $matches[ 'working' ] )
                    {
                        '?' { $null = $filesAdded.Add(    $matches[ 'path1' ]); break }
                        'A' { $null = $filesAdded.Add(    $matches[ 'path1' ]); break }
                        'M' { $null = $filesModified.Add( $matches[ 'path1' ]); break }
                        'D' { $null = $filesDeleted.Add(  $matches[ 'path1' ]); break }
                        'U' { $null = $filesUnmerged.Add( $matches[ 'path1' ]); break }
                    }
                    continue
                } # end file entry case

                '^## (?<branch>\S+?)(?:\.\.\.(?<upstream>\S+))?(?: \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?(?<gone>gone)?\])?$' {

                    $branch   = $matches[ 'branch' ]
                    $upstream = $matches[ 'upstream' ]
                    $gone     = $matches[ 'gone' ] -eq 'gone'
                    $aheadBy  = [int] $matches[ 'ahead' ]
                    $behindBy = [int] $matches[ 'behind' ]

                    continue
                } # end branch info case

                '^## Initial commit on (?<branch>\S+)$' {

                    $branch = $matches[ 'branch' ]

                    continue
                } # end initial commit case
            } # end switch( $status )

            $workingTree = [PSCustomObject] @{
                All       = @( GetUniquePaths $filesAdded, $filesModified, $filesDeleted, $filesUnmerged )
                Added     = $filesAdded
                Modified  = $filesModified
                Deleted   = $filesDeleted
                Unmerged  = $filesUnmerged
            }

            $stagingArea = [PSCustomObject] @{
                All       = @( GetUniquePaths $indexAdded, $indexModified, $indexDeleted, $indexUnmerged )
                Added     = $indexAdded
                Modified  = $indexModified
                Deleted   = $indexDeleted
                Unmerged  = $indexUnmerged
            }

            $result = [PSCustomObject] @{
                Branch          = $branch
                Upstream        = $upstream
                UpstreamGone    = $gone
                AheadBy         = $aheadBy
                BehindBy        = $behindBy
                WorkingTree     = $workingTree
                StagingArea     = $stagingArea
                HasUntracked    = [bool] $filesAdded
            }

            return $result
        }
        finally { }
    }
} # end Get-GitStatus


function ExtractFromZip( [string] $zipFile, [string] $entryName, [string] $destFile )
{
    $null = [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )
    $ZipArchive = [System.IO.Compression.ZipFile]::OpenRead( $zipFile )
    $zEntry = $ZipArchive.GetEntry( $entryName )
    $srcStream = $zEntry.Open()
    $destStream = New-Object "System.IO.FileStream" -ArgumentList( $destFile, [System.IO.FileMode]::Create )
    $srcStream.CopyTo( $destStream )
    $destStream.Dispose()
    $srcStream.Dispose()
}



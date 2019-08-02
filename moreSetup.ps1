[CmdletBinding()]
param()

try
{
    Set-StrictMode -Version Latest
    pushd ~

    if( 0 -ne (id -u) )
    {
        Write-Host "(relaunching as superuser)" -Fore Yellow

        sudo pwsh -ExecutionPolicy Bypass -NoProfile -Command "$PSScriptRoot\$($MyInvocation.MyCommand)" @PSBoundParameters

        return
    }
    elseif( !(Test-Path Variable:\ScriptRoot) )
    {
        $ScriptRoot = $PSScriptRoot
    }

    if( !$ScriptRoot )
    {
        throw "unexpected: don't know what my script root is"
    }

    if( !(Test-Path Env:\SUDO_USER) )
    {
        throw "unexpected: should have SUDO_USER env var"
    }

    Write-Host "Continuing setup..." -Fore Cyan

    # Let's create these files as the normal user.
    #
    # Unfortunately when we use a ScriptBlock as a parameter to pwsh like this, we lose
    # $PSScriptRoot, so we'll have to pass that in.
    sudo -u $env:SUDO_USER pwsh -ExecutionPolicy Bypass -NoProfile -Command {

        [CmdletBinding()]
        param( [Parameter( Mandatory = $true, Position = 0 )]
               [string] $ScriptRoot
             )

        Set-StrictMode -Version Latest

        # TODO: maybe we should make these files links, so we can easily commit any
        # changes to them?

        $stuff = @( '.vimrc'
                    '.gvimrc'
                    '.config/powershell'
                    '.gitconfig'
                    '.inputrc'
                    '.Xresources'
                    '.profile'
                    '.bashrc'
                  )

        foreach( $thing in $stuff )
        {
            $src = Join-Path $ScriptRoot 'home' $thing
            $dst = $thing

            if( (Test-Path $dst) )
            {
                if( (Test-Path $dst -PathType Container) )
                {
                    $diff = diff -r $src $dst
                }
                else
                {
                    $diff = cmp $src $dst
                }

                if( $diff )
                {
                    Write-Host "(diff) " -Fore Yello -NoNewline
                    Write-host "Already exists: $dst" -Fore DarkCyan
                    Write-Host "   To compare: bcompare $src ~/$dst" -Fore DarkYellow
                }
                else
                {
                    Write-Host "(same) " -Fore DarkGreen -NoNewline
                    Write-host "Already exists: $dst" -Fore DarkCyan
                }
                continue
            }

            Write-Host "Copying $thing ..." -Fore Cyan

            if( (Test-Path $src -Type Container) )
            {
                $dst = Split-Path $dst
                Copy-Item $src $dst -Recurse
            }
            else
            {
                Copy-Item $src $dst
            }
        }


        $vimPs1Path = './.vim/pack/vim-ps1/start/vim-ps1'

        if( !(Test-Path $vimPs1Path) )
        {
            Write-Host 'Cloning vim-ps1 (vim PowerShell stuff)' -Fore Cyan
            $vimPs1Url = 'https://github.com/PProvost/vim-ps1.git'
            git clone $vimPs1Url $vimPs1Path
        }

    } -args $ScriptRoot


    if( !(which git-cola) )
    {
        Write-Host "Installing git-cola..." -Fore cyan

        # The version of the git-cola package in Ubuntu 18.04 is fairly old, so per the
        # github page, we're using this PPA:
        # https://launchpad.net/~pavreh/+archive/ubuntu/git-cola
        add-apt-repository -y ppa:pavreh/git-cola
        apt-get update
        apt-get install -y --show-progress git-cola
    }
    else
    {
        Write-Host '(already have git-cola)' -Fore DarkCyan
    }

    if( !(which bcompare) )
    {
        Write-Host "Installing Beyond Compare..." -Fore Cyan

        apt-get install -y --show-progress gdebi-core
        wget --show-progress http://www.scootersoftware.com/bcompare-4.2.9.23626_amd64.deb
        gdebi -n bcompare-4.2.9.23626_amd64.deb
    }
    else
    {
        Write-Host '(already have bcompare)' -Fore DarkCyan
    }

    if( !(which gitk) )
    {
        Write-Host "Installing gitk" -Fore Cyan
        apt-get install -y --show-progress gitk
    }
    else
    {
        Write-Host '(already have gitk)' -Fore DarkCyan
    }

    if( !(fc-list | grep '/hack/') )
    {
        Write-Host "Installing Hack font" -Fore Cyan
        apt-get install -y fonts-hack-ttf
    }
    else
    {
        Write-Host '(already have hack font)' -Fore DarkCyan
    }

    if( !(which java) )
    {
        Write-Host "Installing java" -Fore Cyan
        apt-get install -y --show-progress default-jre
    }
    else
    {
        Write-Host '(already have java)' -Fore DarkCyan
    }

    # I don't really need ruby, but brew does, and their script installer does not seem to
    # be able to install it.
    if( !(which ruby) )
    {
        Write-Host "Installing ruby" -Fore Cyan
        apt-get install -y --show-progress ruby
    }
    else
    {
        Write-Host '(already have ruby)' -Fore DarkCyan
    }

    # Can't just run "which brew" to detect brew, because root does not have it in the
    # PATH (By Design).
    if( !(Test-Path /home/linuxbrew/.linuxbrew/bin/brew) )
    {
        Write-Host "Installing brew" -Fore Cyan

        # some pre-reqs
        apt-get install -y --show-progress build-essential file

        sudo -u $env:SUDO_USER pwsh -ExecutionPolicy Bypass -NoProfile -Command {

            [CmdletBinding()]
            param( [Parameter( Mandatory = $true, Position = 0 )]
                   [string] $ScriptRoot
                 )

            Set-StrictMode -Version Latest

            # I cannot for the life of me figure out why "sh -c $script" does not work,
            # but "$script | sh" does (when called from pwsh; it works fine in bash).
            $script = curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh
            $script | sh
            write-host "pretending it succeeded" -fore magenta -back darkgreen
            if( !$? )
            {
                Write-Error "Uh-oh; did the brew install shell script fail?"
            }
            else
            {
                $shEnvVars = /home/linuxbrew/.linuxbrew/bin/brew shellenv

                # nevermind about the following line; I put this stuff, pre-canned into .profile
                #$shEnvVars >> ~/.profile

                # let's get the env vars locally, too
                $shEnvVars.Replace( "export ", "`$env:" ).
                           Replace( "`$PATH", "`$env:PATH" ).
                           Replace( "`$MANPATH", "`$env:MANPATH" ).
                           Replace( "`$INFOPATH", "`$env:INFOPATH" ) | Invoke-Expression
            }
        } -args $ScriptRoot
    }
    else
    {
        Write-Host '(already have brew)' -Fore DarkCyan
    }

    # Brew-installed stuff.
    if( (Test-Path /home/linuxbrew/.linuxbrew/bin/brew) )
    {
        sudo -u $env:SUDO_USER pwsh -ExecutionPolicy Bypass -NoProfile -Command {

            [CmdletBinding()]
            param( [Parameter( Mandatory = $true, Position = 0 )]
                   [string] $ScriptRoot
                 )

            Set-StrictMode -Version Latest

            # We probably need to load up the environment variables.
            $shEnvVars = /home/linuxbrew/.linuxbrew/bin/brew shellenv

            $shEnvVars.Replace( "export ", "`$env:" ).
                       Replace( "`$PATH", "`$env:PATH" ).
                       Replace( "`$MANPATH", "`$env:MANPATH" ).
                       Replace( "`$INFOPATH", "`$env:INFOPATH" ) | Invoke-Expression

            if( !(which brew) )
            {
                Write-Error "Misconfiguration? Where's Brew?"
                return
            }

            if( !(which git-credential-manager) )
            {
                Write-Host "Installing git-credential-manager" -Fore Cyan


                Write-Host 'Updating brew... (this can take a while)' -Fore Cyan
                brew update

                Write-Host '[brew] installing git-credential-manager' -Fore Cyan
                brew install git-credential-manager

                git-credential-manager install
            }
            else
            {
                Write-Host '(already have git-credential-manager)' -Fore DarkCyan
            }
        } -args $ScriptRoot
    }

    Write-Host "Done." -Fore Green
}
finally
{
    popd
}


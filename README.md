# Powershell Scripts & One-liners
This is a collection of one-liners and scripts I've created or collected.
It is very much a work in progress.

Original authors are credited where their code was used.

## PowerShell Profile

To make the best use of this repo, copy the contents of `profile.ps1` in this repo to the [appropriate PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles).

I generally just use `$PROFILE`:
- On Windows `$PROFILE` = `$Home\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- On Mac `$PROFILE` = `~/.config/powershell/Microsoft.Powershell_profile.ps1`
- On Linux `$PROFILE` = `~/.config/powershell/Microsoft.Powershell_profile.ps1`

`$PROFILE` is the "Current User, Current Host" which means the console you are running in. The other profiles mentioned in the [full documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles) are more for scheduled tasks or running scripts via your RMM.

## .gitignore
.gitignore goes in the root of your git repo. It tells git to ignore any file with the listed pattern. 

Check the .gitignore file itself for the most up to date ignores, but in general this repo ignores:  
1. `*.secret`
2. `*.secure`
3. `*.ignore`
4. `*.json`

Exceptions can be made with the `!` meaning "not." One exception I am using is `!*example.json` so something like `config-example.json` will still appear in the repo but `config-example.json.secure` would not becauase of the `.secure`.

## Functions
I created a `functions` folder to hold some code that is used repeatedly.

If you are using the `profiles.ps1` from this repo, it will automatically import all of the functions in the `$functionsPath` directory that is defined at the top of `profiles.ps1`.

## JSON Config Files and Keybase.

### JSON Config Files
I have started using JSON files to hold settings for these script so that I can keep them generic.  
Generally, don't put anything like a password in a plain text JSON file.  

See the GPG section below for how I handle encrypting secure configs.


### GPG
**GPG decryption is NOT for running unattended scripts.**

I use [GPG](https://gpgtools.org) to encrypt some of my JSON config files. I use the `.secret` extension for this.  

I have begun adding a function to some scripts, where if the config ends in `.secret` e.g., `syncro.json.secret`, then the script will assume it is encrypted with Keybase and will try to decrypt it using Keybase.  

With GPG installed and in my environment's PATH variable (it is by default), I can run `& gpg --decrypt $secretsPath | ConvertFrom-Json -Depth 100` and GPG will decrypt the file using my private key.
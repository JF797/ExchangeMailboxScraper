# Script file for grabbing mailbox details for ExchangeOnline mailboxes

# Created by JF797 on 07/11/2022

# Currently grabs data from user mailboxes, and distribution groups
# Credentials are required, and will be created if aren't present.
# Credentials should be in line with admin account linked to Office365 for business account.
# If you have your own credentials already, please make sure they are stored with a secure password under the filename 'credentials.xml' in this directory.

function createCredentials {

    $credUser = Read-Host -Prompt "Please enter the username"
    $credPass = Read-Host -AsSecureString -Prompt "Please enter the password"
    $credUser, $credPass | Export-Clixml -Path .\credentials.xml
    $Script:loginCreds = Import-Clixml -path .\credentials.xml
    Write-Host "Credentials have been created and imported to the script"
    Clear-Host

}

function checkForCredentials {

    write-host "Checking for present credential file"
    $Script:credentials = @(Get-ChildItem -path .\credentials.xml -ErrorAction SilentlyContinue)
    Write-Host $credentials
    if (!$credentials) {
        write-host "no credentials present, please create from menu"
        pause
    }
    else {
        Write-Host "saved credentials found"
        pause
        Clear-host
    }
}

function clearCredentialsInFile {

    Write-Host "Checking first if file exists"
    if (!$credentials) {
        Write-Host "There are no credentials in place to remove"
        pause
    }
    else {
        Remove-Item -Path .\credentials.xml -Force
        Write-Host "Credentials have been removed"
        pause
    }

}    

# Mailboxes

function grabMailboxes {

    write-host "Grabbing mailboxes"

    $mailboxResults = @()
    $mailboxes = Get-Mailbox -ResultSize unlimited
    $totalMailboxes = $mailboxes.count
    $j = 1
    $mailboxes | ForEach-Object {
        Write-Progress -Activity "Processing $_.DislpayName" -Status "$j out of $totalMailboxes completed"
        $mailbox = $_
        $mailboxResults += New-Object psobject -Property @{
            Name = $mailbox.DisplayName
            EmailAddress = $mailbox.PrimarySmtpAddress
            OtherAddresses = $mailbox.EmailAddresses
            DateCreated = $mailbox.WhenCreated
        }
        $j++
    }
    $mailboxResults | Export-Csv ".\All-Mailboxes.csv" -NoTypeInformation -Encoding UTF8

} 

# Distribution lists

function grabDistributionLists {

    Write-Host "Grabbing distribution lists"

    $Result=@()
    $groups = Get-DistributionGroup -ResultSize Unlimited
    $totalmbx = $groups.Count
    $i = 1
    $groups | ForEach-Object {
    Write-Progress -activity "Processing $_.DisplayName" -status "$i out of $totalmbx completed"
    $group = $_
    Get-DistributionGroupMember -Identity $group.Name -ResultSize Unlimited | ForEach-Object {
    $member = $_
    $Result += New-Object PSObject -property @{
    GroupName = $group.DisplayName
    Member = $member.Name
    EmailAddress = $member.PrimarySMTPAddress
    RecipientType= $member.RecipientType
    }}
    $i++
    }
    $Result | Export-CSV ".\All-Distribution-Lists.csv" -NoTypeInformation -Encoding UTF8

}


function mainMenu {

    Clear-Host
    Write-Host """Please select from the following options:
    1.) I already have credentials in the directory, start scan.
    2.) Create new credentials file.
    3.) Delete credentials file in place.
    X.) Exit script"""

    $menuOption = Read-Host
    
    if ($menuOption -eq "1") {
        write-host "you selected 1"
        # start scan (haven't done this properly yet)
    }
    
    # If the user's option is '2', they can make their own XML file containing the login credentials.
    # We first need to actually check if there are any credentials present, so we don't duplicate work.
    elseif ($menuOption -eq "2") {
        write-host "you selected 2"
        # If there are no credentials present
        # This checks the global varialbe of $credentials, since it's already been created, and evaluates the next step.
        if (!$credentials) {
            write-host "You're right! There are no credentials, let's make you some"
            pause
            createCredentials
            Write-Host "returning to main menu"
            pause
            mainMenu
        }
        # If there are already credentials, it just goes back to the menu
        else {
            Write-Host "saved credentials found, there is no need to create new ones"
            pause
            mainMenu
        }
    } 

    elseif ($menuOption -eq "3") {
        clearCredentialsInFile
        Write-Host "returning to main menu"
        pause
        mainMenu
    }
    elseif ($menuOption -eq "x") {
        write-host "Closing script"
        Exit-PSSession
    }
    else {
        write-host "Input invalid, please try again"
        pause
        mainMenu
    }
}

function main {
    checkForCredentials
    Clear-Host
    mainMenu
    #checkForCredentials
    #clearCredentialsInFile

}

main


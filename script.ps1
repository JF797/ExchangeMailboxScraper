# Script file for grabbing mailbox details for ExchangeOnline mailboxes

# Created by JF797 on 07/11/2022

# Currently grabs data from user mailboxes, and distribution groups
# Credentials are required, and will be created if aren't present.
# Credentials should be in line with admin account linked to Office365 for business account.
# If you have your own credentials already, please make sure they are stored with a secure password under the filename 'credentials.xml' in this directory.


# Function to restart script
# Needed to apply changes to directory when dealing with files

function restartScript {
    Write-Host "The script will now restart."
    pause
    Clear-Host
    .\script.ps1

}

# Function to create user credentials to then be saved in file
# Credentials are stored in secure XML file using Microsoft 'Secure String' function
# Once exported as an object-like variable, it's then reimported to be used as normal

function createCredentials {

    $credUser = Read-Host -Prompt "Please enter the username"
    addSuffix
    $credPass = Read-Host -AsSecureString -Prompt "Please enter the password"
    $credUser, $credPass | Export-Clixml -Path .\credentials.xml
    $Script:loginCreds = Import-Clixml -path .\credentials.xml
    Write-Host "Credentials have been created and imported to the script"
    Clear-Host

}

# Widely used function to check if there are credentials present in directory.
# If no 'credentials.xml' file is present, the function will return with false.
# This could be implemented as a function with a parameter as it's called more than once with only 2 outcomes.

function checkForCredentials {

    write-host "Checking for present credential file"
    $Script:credentials = @(Get-ChildItem -path .\credentials.xml -ErrorAction SilentlyContinue)
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

# Clear credentials from local directory.
# Essentially just deletes the file that holds the XML details for the user login.
# Need to restart script to allow directory to update.

function clearCredentialsInFile {

    Write-Host "Checking first if file exists"
    if (!$credentials) {
        Write-Host "There are no credentials in place to remove"
        pause
    }
    else {
        Remove-Item -Path .\credentials.xml -Force
        Write-Host "Credentials have been removed"
        restartScript
    }

}    

# Grab all info for account mailboxes under Exhchange.
# Loops through each instance of a user and appends data to an array which will then be exported to a CSV file

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

# Grab all info for Distribution Lists and groups.
# Loops through each instance of a group and appends data to an array which will then be exported to a CSV file
# There is then a second, nested loop that will go through the group and add the details of each specific user in this group.

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

# Function that will check the added username variable. If this doesn't contain the domain suffix then it will be added with user input.
# However, if the user has already added an account with their suffix, then it just returns nothing.
# This is required as the sign in using 'connect exchangeonline' requires a full sign in information for Office365.
# This could be implemented better to be able to detect if users have entered either a username with the @, or with the .co* suffix, and work accordingly.

function addSuffix {

    if ($credUser.Contains("@") -and $credUser.Contains(".co")) {
        return
    }
    else {
        write-host "It looks like you have entered a short username."
        Write-Host "You must make sure this is the full domain username."
        write-host "pleae add the domain you are in (please ensure to add .com/.co.uk) (e.g. 'microsoft.com')"
        $domain = Read-Host ">>>"
        $credUser = $credUser+ "@" + $domain
    }
    write-host "Thank you."
    Write-Host "username is now:" $credUser
}

# Main menu function that the user will start at. 
# User options are distribed in function.
# User has option to add credentials if they don't exist, and remove if they do.
# User can also exit.

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
            restartScript
            #mainMenu
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

}

main


# Still need to actually implement option 1 result!! (scanning and exporting)

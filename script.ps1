function createCredentials {

    $credUser = Read-Host -Prompt "Please enter the username"
    $credPass = Read-Host -AsSecureString -Prompt "Please enter the password"
    $credUser, $credPass | Export-Clixml -Path .\credentials.xml
    $loginCreds = Import-Clixml -path .\credentials.xml
    Clear-Host

}

function checkForCredentials {

    write-host "Checking for present credential file"
    $credentials = @(Get-ChildItem -path .\credentials.xml -ErrorAction SilentlyContinue)
    Write-Host $credentials
    if (!$credentials) {
        write-host "no credentials present, please create"
        pause
        Clear-Host
        createCredentials
    }
    else {
        Write-Host "saved credentials found"
        pause
        Clear-host
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

function main {
    Clear-Host
    checkForCredentials

}

main
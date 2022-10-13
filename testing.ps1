# testing

$username = "test@test.com"

function addSuffix {

    if ($username.Contains("@") -and $username.Contains(".co")) {
        return
    }
    else {
        write-host "It looks like you have entered a short username."
        Write-Host "You must make sure this is the full domain username."
        write-host "pleae add the domain you are in (please ensure to add .com/.co.uk) (e.g. 'microsoft.com')"
        $domain = Read-Host ">>>"
        $username = $username + "@" + $domain
    }
    write-host "Thank you."
    Write-Host "username is now:" $username
}


addSuffix($username)
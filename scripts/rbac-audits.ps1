param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [string]$OutputFile = "../exports"
)
Write-Host "=====LayiCorp RBAC Audit Script=====" -ForegroundColor Cyan

# Ensure Az modules are avialable
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Error "Az module not found. Install with: Install-Module Az -Scope CurrentUser"
    exit 1
}

Import-Module Az.Accounts
Import-Module Az.Resources

# Ensure output folder exists
$fullOutputPath = Resolve-Path -Path $OutputFolder -ErrorAction SilentlyContinue
if (-not $fullOutputPath) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    $fullOutputPath = Resolve-Path -Path $OutputFolder
}

write-Host "Output will be saved to: $fullOutputPath" -ForegroundColor Yellow

# Connect if needed
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "No Azure context found. Running Connect-AzAccount." -ForegroundColor Yellow
    Connect-AzAccount | Out-Null
}

#Select subscription
Write-Host "Selecting subscription: $SubscriptionId" -ForegroundColor Yellow
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# Get all role assignmentsin the subscription
Write-Host "Retrieving role assignments..." -ForegroundColor Yellow
$assignments = Get-AzRoleAssignment

if (-not $assignments) {
    Write-Host "No role assignments found in this subscription $SubscriptionId" -ForegroundColor Red
    exit 0
}   


###### Export All Role Assignments #####

$allRbac = $assignments | Select-Object `
    DisplayName,
    SignInName,
    ObjectId,
    ObjectType,
    RoleDefinitionName,
    Scope,
    CanDelegate

    $allPath = Join-Path $fullOutputPath "rbac-assignments.csv"
    $allRbac | Export-Csv -Path $allPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported all role assignments to: $allPath" -ForegroundColor Green


    ##### High-Privilege Role Assignments Only #####

    $highPrivRoles = @(
        "Owner",
        "Contributor",
        "User Access Administrator",
        "Security Admin",
        "Global Administrator",
        "Privileged Role Administrator"
    )
    
    $highPriv =$allRbac | Where-Object {
         $highPrivRoles -contains $_.RoleDefinitionName 
        }

    $highPrivPath = Join-Path $fullOutputPath "rbac-high-privileged.csv"
    $highPriv | Export-Csv -Path $highPrivPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported high-privilege assignments to: $highPrivPath" -ForegroundColor Green


    ##### Direct User assignments Only #####
    $directUsers = $allRbac | Where-Object {
        $_.ObjectType -eq "User"
    }

    $directUsersPath = Join-Path $fullOutputPath "rbac-direct-users.csv"
    $directUsers | Export-Csv -Path $directUsersPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported direct user assignments to: $directUsersPath" -ForegroundColor Green

    ##### Guest Users (UserType= Guest) With Roles #####
    Write-Host "Resolving guest users..." -ForegroundColor Yellow
    $guestUsers = Get-AzADUser -Filter "userType eq 'Guest'" -All $true

    if ($guestUsers) {
        $guestIds = $guestUsers.Id
        $guestAssignments = $allRbac | Where-Object {
           ($_.ObjectType -eq "User") -and ($guestIds -contains $_.ObjectId)
        }

        ### Join Some User Properties
        $guestlookup = @{}
        foreach ($g in $guestUsers) {
            $guestlookup[$g.Id] = $g
        }

        $guestReport = $guestAssignments | ForEach-Object {
            $user = $guestlookup[$_.ObjectId]
            [PSCustomObject]@{
                DisplayName = $_.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                RoleDefinitionName = $_.RoleDefinitionName
                Scope = $_.Scope
                ObjectId = $_.ObjectId
            }
        }

        $guestPath = Join-Path $fullOutputPath "rbac-guests.csv"
        $guestReport | Export-Csv -Path $guestPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported guest user assignments to: $guestPath" -ForegroundColor
    }
    else {
        
        Write-Host "No guest users found in the directory." -ForegroundColor Yellow
    }
Write-Host "========RBAC audit completed.========" -ForegroundColor Cyan
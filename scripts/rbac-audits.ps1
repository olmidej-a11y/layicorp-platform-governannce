param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    # Default to ../exports relative to this script
    [string]$OutputFolder = "$PSScriptRoot/../exports"
)

Write-Host "===== LayiCorp RBAC Audit Script =====" -ForegroundColor Cyan

# Ensure Az modules are available
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Error "Az module not found. Install with: Install-Module Az -Scope CurrentUser"
    exit 1
}

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

# Ensure output folder exists
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}
$fullOutputPath = (Resolve-Path -Path $OutputFolder).Path

Write-Host "Output will be saved to: $fullOutputPath" -ForegroundColor Yellow

# Connect if needed
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "No Azure context found. Running Connect-AzAccount." -ForegroundColor Yellow
    Connect-AzAccount | Out-Null
}

# Select subscription
Write-Host "Selecting subscription: $SubscriptionId" -ForegroundColor Yellow
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# Get all role assignments in the subscription
Write-Host "Retrieving role assignments..." -ForegroundColor Yellow
$assignments = Get-AzRoleAssignment

if (-not $assignments) {
    Write-Host "No role assignments found in this subscription $SubscriptionId" -ForegroundColor Red
    Write-Host "======== RBAC audit completed (no data). ========" -ForegroundColor Cyan
    exit 0
}

######### Export All Role Assignments #########

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

######### High-Privilege Role Assignments Only #########

$highPrivRoles = @(
    "Owner",
    "Contributor",
    "User Access Administrator",
    "Security Admin",
    "Global Administrator",
    "Privileged Role Administrator"
)

$highPriv = $allRbac | Where-Object {
    $highPrivRoles -contains $_.RoleDefinitionName
}

$highPrivPath = Join-Path $fullOutputPath "rbac-high-privileged.csv"
$highPriv | Export-Csv -Path $highPrivPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported high-privilege assignments to: $highPrivPath" -ForegroundColor Green

######### Direct User Assignments Only #########

$directUsers = $allRbac | Where-Object {
    $_.ObjectType -eq "User"
}

$directUsersPath = Join-Path $fullOutputPath "rbac-direct-users.csv"
$directUsers | Export-Csv -Path $directUsersPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported direct user assignments to: $directUsersPath" -ForegroundColor Green

######### Guest Users (B2B) with Roles #########
# detect guests by UPN pattern (#EXT#).

Write-Host "Resolving guest user assignments (B2B #EXT# accounts)..." -ForegroundColor Yellow

$guestAssignments = $allRbac | Where-Object {
    $_.ObjectType -eq "User" -and $_.SignInName -like "*#EXT#*"
}

if ($guestAssignments) {
    $guestPath = Join-Path $fullOutputPath "rbac-guests.csv"
    $guestAssignments | Export-Csv -Path $guestPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported guest user assignments to: $guestPath" -ForegroundColor Green
} else {
    Write-Host "No guest user assignments found in this subscription." -ForegroundColor Yellow
}

Write-Host "======== RBAC audit completed. ========" -ForegroundColor Cyan

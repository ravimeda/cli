<#
.SYNOPSIS
    Retrieves the latest commit SHA and the corresponding package Id for the specified branch of CLI. 
    This retrieval is achieved by downloading the latest.version file, which contains the commit SHA and package Id info.
    If retrieval succeeds, then the commit is set as a VSTS Task Variable named $CliCommitSha, and similarly package Id is set as $CliPackageId.
.PARAMETER $Branch
    Name of the CLI branch.
.PARAMETER $Filename
    Name of the file that contains latest version info i.e. commit SHA and package Id.
    If not specified, then the default value is latest.version
.PARAMETER $UrlPrefix
    URL prefix for $Filename.
    If not specified, then the default value is https://dotnetcli.blob.core.windows.net/dotnet/Sdk
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Branch,
    [string]$Filename="latest.version",
    [string]$UrlPrefix="https://dotnetcli.blob.core.windows.net/dotnet/Sdk"
)

function Get-VersionInfo
{
    Write-Host "Attempting to retrieve latest version info from $latestVersionUrl"
    $retries = 3
    $retryCount = 1
    $oldEap = $ErrorActionPreference

    while ($retryCount -le 3)
    {
        $ErrorActionPreference = "Stop"

        try
        {
            return (Invoke-WebRequest -Uri "$latestVersionUrl" -UseBasicParsing).Content.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)
        }
        catch
        {
            Sleep -Seconds (Get-Random -minimum 3 -maximum 10)
            Write-Host "Exception occurred while attempting to get latest version info from $latestVersionUrl. $_"
            Write-Host "Retry $retryCount of $retries"
        }
        finally
        {
            $ErrorActionPreference = $oldEap
        }

        $retryCount++
    }
}

$latestVersionUrl = "$UrlPrefix/$Branch/$Filename"
$latestVersionContent = Get-VersionInfo

if (-not [string]::IsNullOrWhiteSpace($latestVersionContent) -and $latestVersionContent.Length -eq 2)
{
    $CliCommitSha = $latestVersionContent[0]
    $CliPackageId = $latestVersionContent[1]

    Write-Host "##vso[task.setvariable variable=$CliCommitSha;]$CliCommitSha"
    Write-Host "##vso[task.setvariable variable=$CliPackageId;]$CliPackageId"

    Write-Host "The latest commit SHA in CLI $Branch is $CliCommitSha"
    Write-Host "The latest package Id in CLI $Branch is $CliPackageId"
}
else
{
    Write-Error "Unable to get latest version info from $latestVersionUrl"
}

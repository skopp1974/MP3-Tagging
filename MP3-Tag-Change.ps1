[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false,Position=1)]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    #[string]$path="I:\songs\Saahasam Swaasaga Saagipo (2016)",
    [string]$path,
    [Parameter(Mandatory=$false,Position=2)]
    [switch]$FolderAsAlbum=$true,
    
    [Parameter(Mandatory=$False,Position=3)]
    [string]$FileNameDelimiter=$null
)

Function Select-FolderDialog
{
    param([string]$Description="Select Folder",[string]$SelectedPath="F:\")

 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
     Out-Null     

   $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.SelectedPath = $SelectedPath
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()
        If ($Show -eq "OK")
        {
            Return $objForm.SelectedPath
        }
        Else
        {
            $ret = "Operation cancelled by user."
            throw $ret
        }
}

if(!$path)
{
    try
    {
        $path = Select-FolderDialog
        #Remove ReadOnly attribute
        dir $path -r *.* | % { $_.fullname } | % { attrib -r $_ }
    } catch
    {
        Write-Host $_
        return
    }
}

if(!$FolderAsAlbum)
{
    $FileNameDelimiter      = "-"
}

#Import 3rd party module "MPTAG" for editing Media attributes.
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$MPTagPath = $PSScriptRoot + "\MPTag"
Import-Module $MPTagPath

<#
Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
[void]$FolderBrowser.ShowDialog()
$path = $FolderBrowser.SelectedPath
#>

$files = ""

## Update Album name with Directory Name
Write-Host "Getting files from $($path)..."
$files = Get-ChildItem -Path $path -Filter *.mp3 -Recurse | Where-Object { $_.Attributes -ne "Directory"}


foreach ($file in $files) 
{
    write-host -ForegroundColor Green "Tagging file $file ..."
    $MediaInfo = Get-MediaInfo $file.FullName
    
    #if (!$MediaInfo.Album)
    #{
        if($FolderAsAlbum)
        {
            Write-Host -ForegroundColor Cyan "No Album Name for [$($file.FullName)]]"
            $AlbumName = $file.Directory # Get the containing folder and set as Album Name
            $tmp = $AlbumName.Name.split(" ")
            $AlbumName = ""
            foreach($_ in $tmp)
            {
                if(!($_.Contains("kbps") -or $_.Contains("Kbps") -or $_.Contains("-"))) # -or $_.Contains("[") -or $_.Contains("]")))
                {
                    $AlbumName += $_ + " "
                }
            }
        } else
        {
            $AlbumName = $file.Name.Split($FileNameDelimiter)[0]
        }

        $AlbumName = $AlbumName.Trim()
        Write-Host -ForegroundColor Cyan "    - New Album Name for [$($file.FullName)] Setting as [$($AlbumName)]"
        $MediaInfo.Album = $AlbumName
        $MediaInfo.Save()
    #}
    
    Write-Host -ForegroundColor Yellow "Album: [$($MediaInfo.Album)] File: [$($file)]"

}

#Update File Name with delimiter as Album Name




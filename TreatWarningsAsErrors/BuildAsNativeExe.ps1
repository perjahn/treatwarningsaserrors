Set-StrictMode -v latest
$ErrorActionPreference = "Stop"

function Main()
{
    if (Test-Path nuget.config.AsNativeExe)
    {
        ren nuget.config.AsNativeExe nuget.config
    }
    AddPackageReference "TreatWarningsAsErrors.csproj" "Microsoft.DotNet.ILCompiler" "1.0.0-alpha-*"

    if (Test-Path bin)
    {
        Write-Host ("Deleting folder: bin")
        rd -Recurse -Force bin
    }
    if (Test-Path obj)
    {
        Write-Host ("Deleting folder: obj")
        rd -Recurse -Force obj
    }

    dotnet publish -c Release -r win-x64

    [string] $outfile = "bin\Release\netcoreapp2.2\win-x64\native\TreatWarningsAsErrors.exe"
    if (Test-Path $outfile)
    {
        Write-Host ("The file is here: " + $outfile) -f Green
    }
    else
    {
        Write-Host ("Couldn't find outfile: " + $outfile) -f Red
    }

    RemovePackageReference "TreatWarningsAsErrors.csproj" "Microsoft.DotNet.ILCompiler" "1.0.0-alpha-*"
    ren nuget.config nuget.config.AsNativeExe
}

function AddPackageReference([string] $filename, [string] $include, [string] $version)
{
    [xml] $xml = Get-Content $filename

    if (!($xml.DocumentElement.ItemGroup.PackageReference | ? { $_.Attributes["Include"].Value -eq $include -and $_.Attributes["Version"].Value -eq $version }))
    {
        Write-Host ("Adding reference: '" + $include + "', '" + $version + "'")
        $packageReference = $xml.CreateElement("PackageReference")
        $packageReference.SetAttribute("Include", $include)
        $packageReference.SetAttribute("Version", $version)
        $xml.DocumentElement.ItemGroup.AppendChild($packageReference) | Out-Null

        SaveXml $filename $xml
    }
}

function RemovePackageReference([string] $filename, [string] $include, [string] $version)
{
    [xml] $xml = Get-Content $filename

    [bool] $modified = $false
    $xml.DocumentElement.ItemGroup.PackageReference | ? { $_.Attributes["Include"].Value -eq $include -and $_.Attributes["Version"].Value -eq $version } | % {
        Write-Host ("Removing reference: '" + $include + "', '" + $version + "'")
        $_.ParentNode.RemoveChild($_) | Out-Null
        $modified = $true
    }
    if ($modified)
    {
        SaveXml $filename $xml
    }
}

function SaveXml([string] $filename, $xml)
{
    Write-Host ("Saving project file: '" + $filename + "'")
    [Xml.XmlWriterSettings] $settings = New-Object Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = New-Object Text.UTF8Encoding($false)
    $settings.OmitXmlDeclaration = $true
    $writer = [Xml.XmlWriter]::Create($filename, $settings)
    $xml.Save($writer)
    $writer.Dispose()
}

Main

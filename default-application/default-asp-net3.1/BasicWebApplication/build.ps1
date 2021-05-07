Remove-Item -Path .\..\..\..\dist -Recurse

dotnet publish BasicWebApplication.csproj --configuration release --output .\bin\Release\netcoreapp3.1\publish

$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
Set-Alias 7zip $7zipPath

$ApplicationSource = ".\bin\Release\netcoreapp3.1\publish\*"
$PackageTarget = ".\..\..\..\dist\deployment-package.zip"

7zip a -mx=1 $PackageTarget $ApplicationSource


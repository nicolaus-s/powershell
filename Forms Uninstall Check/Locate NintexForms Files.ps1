asnp *sh*

$formscoresol = Get-SPSolution -Identity 96555725-43da-4b5d-bdcb-65d389de3e3e
if ($formscoresol.Deployed -eq $true) {
Write-Host "Nintex Forms Core solution is deployed."
}

$formssol = Get-SPSolution -Identity a1a07f85-b9a7-44bf-bb64-c04fa8f931fc
if ($formssol.Deployed -eq $true) {
Write-Host "Nintex Forms solution is deployed."
}

$features = Get-SPFeature | ? {$_.DisplayName -Like "*NintexForms*"}
if ($features.Length -gt 0) {
Write-Host "Nintex Forms features are still activated:"
foreach ($f in $features) {
Write-Host $f.DisplayName " - " $f.Id
}
}

[System.Xml.XmlDocument]$file = new-object System.Xml.XmlDocument
$file.load("manifest.xml")

$xml= $file.SelectNodes('//Solution/*')
foreach ($node in $xml) {
  switch ($node.Name)
{
    Assemblies {"
    ----- Checking Assemblies -----
    ";
    $switchnode = $file.SelectNodes('//Solution/Assemblies/Assembly');
    $gac = gci -Path C:\Windows\Microsoft.NET\assembly\GAC_MSIL\ -Filter Nintex* -Recurse
    foreach ($s in $switchnode){
    $thisfile = $gac | ? {$_.Name -eq $s.Location}
    if ($thisfile.Exists -eq $true) {
    Write-Host $s.Location "exists in" $thisfile.Directory
    }
    }
    Break}

    RootFiles {"
    ----- Checking Root Files -----
    ";
    $switchnode = $file.SelectNodes('//Solution/RootFiles/RootFile');
    foreach ($s in $switchnode){
    $path =  "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\" + $s.Location
    $thisfile = gci -Path $path
    if ($thisfile.Exists -eq $true) {
    Write-Host $s.Location "exists in" $thisfile.Directory
    }
    }
    Break}

    TemplateFiles {"
    ----- Checking Template Files -----
    ";
    $switchnode = $file.SelectNodes('//Solution/TemplateFiles/TemplateFile');
    foreach ($s in $switchnode){
    $path =  "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\TEMPLATE\" + $s.Location
    $thisfile = gci -Path $path -recurse
    if ($thisfile.Exists -eq $true) {
    Write-Host $s.Location "exists in" $thisfile.Directory
    }
    }
    Break}
}
}

Write-Host "
Review the output above. Press any key to close this window.
"
Read-Host
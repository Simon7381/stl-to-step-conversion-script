##################################################################
#### Update this variable, no touchy anything else. ##############
#### Set to a specific path to override auto-detection. ##########
$freeCadCmdPathOverride = $null
##################################################################
#### FreeCAD past/present/future versions currently. #############
$freecadVersions = @("1.2", "1.1", "1.0")
##################################################################
$freeCadCmdPath = $null

if ($null -ne $freeCadCmdPathOverride) {
    $freeCadCmdPath = $freeCadCmdPathOverride
}
else {
    foreach ($version in $freecadVersions) {
        $path = "C:\Program Files\FreeCAD $version\bin\freecadcmd.exe"
        if (Test-Path -Path $path) {
            $freeCadCmdPath = $path
            break
        }
    }
}

if ($null -eq $freeCadCmdPath) {
    Write-Error "Could not find freecadcmd.exe in standard installation paths for versions 1.2, 1.1, or 1.0. Please set `$freeCadCmdPathOverride."
    exit 1
}
##################################################################
### no touchy touchy below this line unless you know what you're
### doing pls
### 
###      .-""""""-.
###    .'  \\  //  '.
###   /   O      O   \
###  :                :
###  |                |
###  :       __       :
###   \  .-"`  `"-.  /
###    '.          .'
###      '-......-'

if ($psISE) {
    # Get the full path of the file open in the current active tab
    $currentFilePath = [System.IO.Path]::GetDirectoryName($psISE.CurrentFile.FullPath)
}
else {
    # Get the full path of the script being executed
    $currentFilePath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

if ($currentFilePath -eq $null) {
    Write-Error "Could not determine the current file path. Please ensure you are running this script in a valid PowerShell environment."
    exit 1
}

# The paths should end with a backslash
$inputPath = "$currentFilePath\input\"
$outputPath = "$currentFilePath\output\"

$pythonScript = "$currentFilePath\convert.py"
if (-not (Test-Path -Path $inputPath)) {
    Write-Error "Input path does not exist: $inputPath"
    exit 1
}

$stlFiles = [System.Collections.ArrayList]@(
    (Get-ChildItem -Path $inputPath -Filter '*.stl' -File -Recurse).Name
)

$stepFiles = Get-ChildItem -Path $outputPath -Filter *.step | Select-Object -ExpandProperty Name

foreach ($stepFile in $stepFiles) {

    $matchingFile = $stepFile.Replace(".step", ".stl")

    if ($matchingFile -in $stlFiles) {
        $stlFiles.Remove($matchingFile)
        Write-Host "Found .step file for $matchingFile, will not reprocess."
    }
    else {
        # Do nothing.
    }
}

foreach ($file in $stlFiles) {
    Write-Output "Unmatched STL: $($file)"
    $inputFilePath = $inputPath + $file
    $outputFilePath = $outputPath + $file.Replace(".stl", ".step")
    & $freeCadCmdPath "$pythonScript" "$inputFilePath" "$outputFilePath"
}

Write-Output "All conversions completed!"
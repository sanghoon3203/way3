param (
    [string]$InputPath,
    [string]$OutputDir,
    [string]$Prefix
)

# Determine processed files
$filesToProcess = @()

if (Test-Path -Path $InputPath -PathType Container) {
    Write-Host "Processing directory: $InputPath"
    $filesToProcess = Get-ChildItem -Path $InputPath -Filter *.md | Sort-Object Name
}
else {
    Write-Host "Processing single file: $InputPath"
    $filesToProcess = @(Get-Item -Path $InputPath)
}

if ($filesToProcess.Count -eq 0) {
    Write-Error "No markdown files found in input path."
    exit
}

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$nodeCounter = 1
$currentBg = $null

foreach ($file in $filesToProcess) {
    Write-Host "Reading file: $($file.Name)"
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $scenes = $content -split '---'

    foreach ($scene in $scenes) {
        $lines = $scene -split "`r`n|`r|`n"
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            # Location Parsing
            if ($line -match '\*\*.*Location.*:\s*(.*)\*\*') {
                $rawBg = $matches[1].Trim()
                if ($rawBg -match '\((.*?)\)') {
                    $currentBg = $matches[1]
                }
                else {
                    $currentBg = $rawBg
                }
                continue
            }

            # Skip Headers/Comments
            if ($line.StartsWith('#') -or $line.StartsWith('**')) { continue }

            $characterId = "Narrator"
            $text = $line
            
            # Dialogue Parsing: Name: "Text"
            if ($line -match '^([^:]+):\s*"(.*)"$') {
                $characterId = $matches[1].Trim()
                if ($matches[2]) {
                    $text = $matches[2].Trim()
                }
                else {
                    # Handle cases where regex might capture incorrectly if format is off, 
                    # but typically Group 2 is the text.
                    $text = "" 
                }
                
                # Remove (Action) from name
                $characterId = $characterId -replace '\(.*\)', ''
                $characterId = $characterId.Trim()
            }
            elseif ($line -match '^"(.*)"$') {
                $text = $matches[1].Trim()
            }

            $nodeId = "{0}_{1:D3}" -f $Prefix, $nodeCounter
            $nextNodeId = "{0}_{1:D3}" -f $Prefix, ($nodeCounter + 1)

            $json = @{
                node_id           = $nodeId
                background_image  = $currentBg
                character_id      = $characterId
                character_sprite  = $null
                dialogue_text     = $text
                dialogue_sound_id = $null
                sound_effect      = $null
                next_node_id      = $nextNodeId
            }

            $jsonContent = $json | ConvertTo-Json -Depth 2
            $outFile = Join-Path -Path $OutputDir -ChildPath "$nodeId.json"
            
            # PowerShell 5.1/Core encoding differences handling
            # Using [IO.File] for consistent UTF-8 no BOM
            [System.IO.File]::WriteAllText($outFile, $jsonContent, [System.Text.Encoding]::UTF8)
            
            $nodeCounter++
        }
    }
}

# Fix last node
$lastNodeId = "{0}_{1:D3}" -f $Prefix, ($nodeCounter - 1)
$lastFile = Join-Path -Path $OutputDir -ChildPath "$lastNodeId.json"
if (Test-Path $lastFile) {
    $json = Get-Content -Path $lastFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $json.next_node_id = $null
    $jsonContent = $json | ConvertTo-Json -Depth 2
    [System.IO.File]::WriteAllText($lastFile, $jsonContent, [System.Text.Encoding]::UTF8)
}

Write-Host "Generated $($nodeCounter - 1) nodes in $OutputDir from $($filesToProcess.Count) files."

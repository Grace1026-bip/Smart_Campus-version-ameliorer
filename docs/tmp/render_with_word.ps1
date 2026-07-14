$ErrorActionPreference = 'Stop'
$relativeInput = if ($args.Count -gt 0) { $args[0] } else { 'output\Monographie_Smart_Faculty.docx' }
$inputPath = (Resolve-Path -LiteralPath $relativeInput).Path
$outputDir = Join-Path (Get-Location) 'tmp\qa_word'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$pdfPath = Join-Path $outputDir (([IO.Path]::GetFileNameWithoutExtension($inputPath)) + '.pdf')
$logPath = Join-Path $outputDir 'word_export.log'
"start $(Get-Date -Format o)" | Set-Content -LiteralPath $logPath

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$word.AutomationSecurity = 3
$word.Options.UpdateLinksAtOpen = $false
try {
    "word-created" | Add-Content -LiteralPath $logPath
    $doc = $word.Documents.Open($inputPath, $false, $true)
    try {
        "document-opened" | Add-Content -LiteralPath $logPath
        $doc.SaveAs2($pdfPath, 17)
        "pdf-exported" | Add-Content -LiteralPath $logPath
    }
    finally {
        $doc.Close($false)
    }
}
finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
Write-Output $pdfPath

$ErrorActionPreference = 'Stop'
$inputPath = (Resolve-Path -LiteralPath 'output\Monographie_Smart_Faculty.docx').Path
$outputPath = Join-Path (Get-Location) 'tmp\word_page_stats.txt'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $doc = $word.Documents.Open($inputPath, $false, $true)
    try {
        $doc.Repaginate()
        $pages = $doc.ComputeStatistics(2)
        "PAGES=$pages" | Set-Content -LiteralPath $outputPath -Encoding UTF8
        foreach ($para in $doc.Paragraphs) {
            $styleName = [string]$para.Range.Style.NameLocal
            if ($styleName -match 'Titre|Heading') {
                $text = ($para.Range.Text -replace '[\r\a]', '').Trim()
                if ($text) {
                    $page = $para.Range.Information(3)
                    "PAGE=$page`tSTYLE=$styleName`tTEXT=$text" | Add-Content -LiteralPath $outputPath -Encoding UTF8
                }
            }
        }
    }
    finally {
        $doc.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
}
finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
Get-Content -LiteralPath $outputPath -Encoding UTF8

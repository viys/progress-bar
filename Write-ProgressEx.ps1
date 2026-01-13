Install-Module -Name Write-ProgressEx

# $total = 100

# for ($i = 1; $i -le $total; $i++) {
#     Write-ProgressEx `
#         -Activity "写入 Flash" `
#         -Status "已写入 $i / $total" `
#         -Current $i `
#         -Total $total
#     Start-Sleep -Milliseconds 100
# }

# Write-ProgressEx -Completed

function Get-AddressFromLine {
    param(
        [string]$Line
    )

    if ($Line -match '\bat address\s+0x([0-9A-Fa-f]+)\b') {
        return [Convert]::ToInt64($Matches[1], 16)
    }

    return $null
}

$exe  = "Cmd_download_tool.exe"
$args = @("1", "B85", "wf", "0", "-i", ".\MERGEN.bin")

# 假设你已知总写入大小（字节）：
$totalBytes = (Get-Item .\MERGEN.bin).Length   # 例子：512KB（你说“总大小你会告诉我”）

$currentAddr = $null

& $exe @args 2>&1 | ForEach-Object {
    $line = $_.ToString()
    $currentAddr = Get-AddressFromLine -Line $line
    Write-ProgressEx -Activity "Write flash" -Status "$currentAddr / $totalBytes" -Current $currentAddr -Total $totalBytes
}

Write-ProgressEx -Completed


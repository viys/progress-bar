Install-Module -Name Write-ProgressEx

$total = 100

for ($i = 1; $i -le $total; $i++) {
    Write-ProgressEx `
        -Activity "写入 Flash" `
        -Status "已写入 $i / $total" `
        -Current $i `
        -Total $total
    Start-Sleep -Milliseconds 100
}

Write-ProgressEx -Completed

function New-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1,[int64]::MaxValue)]
        [int64]$Total,

        [string]$Activity = "Processing",

        [int]$Id = 1,

        [switch]$ShowETA
    )

    # 状态
    $state = [pscustomobject]@{
        Total    = $Total
        Current  = 0
        Activity = $Activity
        Id       = $Id
        StartTime = Get-Date
        ShowETA  = [bool]$ShowETA
    }

    # 把“更新进度”的逻辑做成闭包，保证 Step/Set 里能调用到
    $update = {
        param($s)

        if ($s.Current -gt $s.Total) { $s.Current = $s.Total }
        if ($s.Current -lt 0) { $s.Current = 0 }

        $percent = [int](($s.Current * 100) / $s.Total)

        $status = "$($s.Current) / $($s.Total)"
        if ($s.ShowETA) {
            $elapsed = (Get-Date) - $s.StartTime
            $rate = if ($elapsed.TotalSeconds -gt 0 -and $s.Current -gt 0) { $s.Current / $elapsed.TotalSeconds } else { 0 }
            $etaSeconds = if ($rate -gt 0) { ($s.Total - $s.Current) / $rate } else { $null }
            $etaText = if ($null -ne $etaSeconds) {
                [TimeSpan]::FromSeconds([math]::Max(0, [int][math]::Ceiling($etaSeconds))).ToString()
            } else {
                "--:--:--"
            }
            $status = "$status  ETA: $etaText"
        }

        Write-Progress `
            -Id $s.Id `
            -Activity $s.Activity `
            -Status $status `
            -PercentComplete $percent
    }.GetNewClosure()

    # 相对推进：+Delta
    $state | Add-Member -MemberType ScriptMethod -Name Step -Value {
        param([Parameter(Mandatory)][int64]$Delta)

        $this.Current += $Delta
        $update.Invoke($this)
    }.GetNewClosure()

    # 绝对设置：Current = Value（你要的“直接到 512”）
    $state | Add-Member -MemberType ScriptMethod -Name Set -Value {
        param([Parameter(Mandatory)][int64]$Value)

        $this.Current = $Value
        $update.Invoke($this)
    }.GetNewClosure()

    # 可选：重置到 0
    $state | Add-Member -MemberType ScriptMethod -Name Reset -Value {
        $this.Current = 0
        $this.StartTime = Get-Date
        $update.Invoke($this)
    }.GetNewClosure()

    # 完成：清掉进度条
    $state | Add-Member -MemberType ScriptMethod -Name Complete -Value {
        Write-Progress -Id $this.Id -Activity $this.Activity -Completed
    }.GetNewClosure()

    return $state
}

# ===== Demo =====
$progress = New-ProgressBar -Total 1000 -Activity "Flash 写入" -Id 1 -ShowETA
$total = 1000
for ($i = 1; $i -le $total; $i++) {
    $progress.Step(1)
    Start-Sleep -Milliseconds 1
}

$progress.Step(128)   # 128
Start-Sleep -Milliseconds 200
$progress.Step(128)   # 256
Start-Sleep -Milliseconds 200

$progress.Set(512)    # 直接跳到 512
Start-Sleep -Milliseconds 200

$progress.Step(100)   # 612
Start-Sleep -Milliseconds 200

$progress.Complete()

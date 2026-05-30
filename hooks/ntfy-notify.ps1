# PowerShell script for Windows users without bash
# This is a fallback implementation for the notification hook

param()

# Read configuration
$configFile = "$env:USERPROFILE\.claude\plugins\claude-notify-plugin\config"
if (Test-Path $configFile) {
    Get-Content $configFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

# Check if notifications are disabled
if ($env:NTFY_ENABLED -eq "false") {
    exit 0
}

# Validate required configuration
if (-not $env:NTFY_TOPIC) {
    Write-Error "Error: NTFY_TOPIC not configured. Run /notify:setup first."
    exit 1
}

# Check notification method
$useCurl = $false
if (-not (Get-Command ntfy -ErrorAction SilentlyContinue)) {
    if (Get-Command curl -ErrorAction SilentlyContinue) {
        $useCurl = $true
    } else {
        Write-Error "Error: Neither ntfy CLI nor curl is installed."
        Write-Error "Install ntfy: scoop install ntfy or choco install ntfy"
        exit 1
    }
}

# Detect if terminal is in foreground
function Test-TerminalForeground {
    if (-not $env:NTFY_TERMINAL_CHECK -or $env:NTFY_TERMINAL_CHECK -eq "true") {
        try {
            Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32 {
                [DllImport("user32.dll")]
                public static extern IntPtr GetForegroundWindow();
                [DllImport("user32.dll", SetLastError=true)]
                public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
            }
"@
            $hwnd = [Win32]::GetForegroundWindow()
            $sb = New-Object System.Text.StringBuilder(256)
            [Win32]::GetWindowText($hwnd, $sb, 256) | Out-Null
            $activeWindow = $sb.ToString().ToLower()

            $terminalPatterns = @("*terminal*", "*windows terminal*", "*powershell*", "*cmd*", "*git bash*", "*wsl*", "*alacritty*", "*kitty*", "*wezterm*", "*ghostty*", "*hyper*")
            foreach ($pattern in $terminalPatterns) {
                if ($activeWindow -like $pattern) {
                    return $true
                }
            }
        } catch {
            # Cannot detect, assume not in foreground
            return $false
        }
    }
    return $false
}

# Skip if terminal is in foreground
if (Test-TerminalForeground) {
    exit 0
}

# Read stdin
$input = [Console]::In.ReadToEnd()

# Parse event type
$eventType = ""
try {
    $json = $input | ConvertFrom-Json
    $eventType = $json.hook_event_name
} catch {
    # Invalid JSON
    exit 1
}

# Get project name
$projectName = Split-Path -Leaf (Get-Location)

# Replace variables in template
function Replace-Variables($template) {
    return $template -replace '\{project_name\}', $projectName
}

# Send notification
function Send-Notification($title, $message, $priority, $tags) {
    if ($useCurl) {
        $url = "$($env:NTFY_HOST -replace '/$', '')/$($env:NTFY_TOPIC)"
        if (-not $env:NTFY_HOST) {
            $url = "https://ntfy.sh/$($env:NTFY_TOPIC)"
        }

        $headers = @{
            "Title" = $title
            "Priority" = $priority
        }
        if ($tags) {
            $headers["Tags"] = $tags
        }
        if ($env:NTFY_TOKEN) {
            $headers["Authorization"] = "Bearer $($env:NTFY_TOKEN)"
        }

        # Send notification (background job)
        Start-Job -ScriptBlock {
            param($url, $headers, $message)
            Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $message
        } -ArgumentList $url, $headers, $message | Out-Null
    } else {
        $args = @("publish", "--title", $title, "--priority", $priority, "--quiet")
        if ($tags) {
            $args += @("--tags", $tags)
        }
        if ($env:NTFY_HOST) {
            $args += @("--config", "default-host: $($env:NTFY_HOST)")
        }
        $args += @("-m", $message, $env:NTFY_TOPIC)

        # Send notification (background job)
        Start-Job -ScriptBlock {
            param($args)
            & ntfy @args
        } -ArgumentList (,$args) | Out-Null
    }
}

# Process event
switch ($eventType) {
    "PermissionRequest" {
        $toolName = ""
        try {
            $json = $input | ConvertFrom-Json
            $toolName = $json.tool_name
        } catch {}

        $titleTemplate = if ($env:NTFY_PERMISSION_TITLE) { $env:NTFY_PERMISSION_TITLE } else { "Claude 需要审批" }
        $bodyTemplate = if ($env:NTFY_PERMISSION_BODY) { $env:NTFY_PERMISSION_BODY } else { "{tool_name}" }

        $title = Replace-Variables $titleTemplate
        $body = Replace-Variables $bodyTemplate
        $body = $body -replace '\{tool_name\}', $toolName

        Send-Notification $title $body "4" "bell"
    }
    "Stop" {
        $message = ""
        try {
            $json = $input | ConvertFrom-Json
            $msg = $json.last_assistant_message
            if ($msg) {
                $message = $msg.Substring(0, [Math]::Min(100, $msg.Length))
            }
        } catch {}

        $titleTemplate = if ($env:NTFY_STOP_TITLE) { $env:NTFY_STOP_TITLE } else { "Claude 已停止" }
        $bodyTemplate = if ($env:NTFY_STOP_BODY) { $env:NTFY_STOP_BODY } else { "{message}" }

        $title = Replace-Variables $titleTemplate
        $body = Replace-Variables $bodyTemplate
        $body = $body -replace '\{message\}', $message

        Send-Notification $title $body "3" "check"
    }
}

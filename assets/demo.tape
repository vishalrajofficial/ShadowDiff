Output shadowdiff-demo.gif

Set Shell "powershell"
Set FontSize 14
Set Width 1100
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set WindowBar Colorful

Type "Clear-Host"
Enter
Sleep 500ms

Type "# 1. Inspect live health & telemetry on cloud demo (Fly.io)"
Enter
Sleep 1s

Type "curl.exe -s https://shadowdiff.fly.dev/healthz"
Enter
Sleep 2s

Type "# 2. Run CI/CD 'Shadow Gating' CLI before deployment (shadowdiff gate)"
Enter
Sleep 1.2s

Type "./bin/shadowdiff.exe gate -dashboard-url=https://shadowdiff.fly.dev -duration=2s -min-parity=60.0 -min-requests=10 -max-drifts=50 -allow-n-plus-one -allow-db-drift"
Enter
Sleep 4.5s

Type "# 3. Query real-time 3-Way Diffy noise cancellation & SQL mutation stats"
Enter
Sleep 1.2s

Type "curl.exe -s https://shadowdiff.fly.dev/api/stats"
Enter
Sleep 3s

Sleep 2s

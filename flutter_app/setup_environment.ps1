Write-Host "Setting up MolConvert Pro Environment..." -ForegroundColor Cyan

# 1. Check for Flutter
if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    Write-Host "Flutter is already installed." -ForegroundColor Green
} else {
    Write-Host "Flutter not found. Attempting to install via Winget..." -ForegroundColor Yellow
    try {
        winget install --id Google.Flutter -e --source winget
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Flutter installed successfully. You may need to restart your terminal." -ForegroundColor Green
            # Refresh env vars for this session if possible, but usually requires restart
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } else {
            Write-Error "Winget installation failed. Please install Flutter manually from https://docs.flutter.dev/get-started/install/windows"
            exit 1
        }
    } catch {
        Write-Error "Winget not found or failed. Please install Flutter manually."
        exit 1
    }
}

# 2. Check for Dart (usually comes with Flutter)
if (-not (Get-Command "dart" -ErrorAction SilentlyContinue)) {
    Write-Warning "Dart command not found. It should be in the Flutter bin directory."
}

# 3. Install Project Dependencies
Write-Host "Installing project dependencies..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
} else {
    Write-Error "Failed to install dependencies."
}

Write-Host "Setup Complete. To run the app, use: flutter run -d chrome" -ForegroundColor Cyan

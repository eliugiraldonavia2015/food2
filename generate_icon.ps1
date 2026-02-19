
Add-Type -AssemblyName System.Drawing

$sourcePath = "c:\Users\eliug\Documents\food2\ISOTIPO FOODTOOK BLANCO.png"
$destPath = "c:\Users\eliug\Documents\food2\food\Assets.xcassets\AppIcon.appiconset\AppIcon_Magenta.png"

# Load the source image
$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

# Create a new bitmap with the same dimensions
$finalImage = New-Object System.Drawing.Bitmap($sourceImage.Width, $sourceImage.Height)
$graphics = [System.Drawing.Graphics]::FromImage($finalImage)

# Define the background color (Brand Pink: R244, G37, B123)
$bgColor = [System.Drawing.Color]::FromArgb(255, 244, 37, 123)
$brush = New-Object System.Drawing.SolidBrush($bgColor)

# Fill the background
$graphics.FillRectangle($brush, 0, 0, $finalImage.Width, $finalImage.Height)

# Draw the source image on top
$graphics.DrawImage($sourceImage, 0, 0, $sourceImage.Width, $sourceImage.Height)

# Save the result
$finalImage.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Cleanup
$graphics.Dispose()
$brush.Dispose()
$finalImage.Dispose()
$sourceImage.Dispose()

Write-Host "Icon created successfully at $destPath"

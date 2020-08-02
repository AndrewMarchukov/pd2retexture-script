# !!!!!!!!! Launch only in units(textures) directory !!!!!!!!!!
# set image magick exe, mparallel.exe
Set-PSDebug -Trace 1
cmd.exe /c 'set magick="C:\Program Files\ImageMagick-7.0.10-Q16-HDRI\magick.exe"'
cmd.exe /c 'set MParallel="E:\pd2extract\TOOLS\MParallel.exe"'
$env:magick = 'C:\Program Files\ImageMagick-7.0.10-Q16-HDRI\magick.exe'
$env:MParallel = 'E:\pd2extract\TOOLS\MParallel.exe'

$env:MParallel
$env:magick

# Remove all non texture files and shit
Get-ChildItem -Recurse * -Include *.* -Exclude  *_df.texture,*.ps1 | Remove-Item
Get-ChildItem -Directory -Recurse * -Include cubemaps | Remove-item

# Rename texture to dds
Get-ChildItem -Recurse *.texture | Rename-Item -NewName { $_.Name -replace '.texture','.dds' }

# Converting dds to png or use another converter and delete dds
# without parallel - cmd.exe /c "FOR /R %f IN (*.dds) DO "%magick%" mogrify -format png "%f""
cmd.exe /c 'dir *.dds /s /b | %MParallel%  --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -format png \"{{0}}\""'

# Remove dds
Get-ChildItem -Recurse * -Include *.dds | Remove-Item

# Create alpha folder
MKDIR alpha

# Extract alpha layer to alpha folder
# without parallel - cmd.exe /c "FOR /R %f IN (*.png) DO %magick% mogrify -path alpha "%f" -alpha extract "%f""
cmd.exe /c 'dir *.png /s /b | %MParallel%  --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -path alpha \"{{0}}\" -alpha extract \"{{0}}\""'


# Move alpha current folder on above folder
Move-Item -Path ./alpha -Destination ..

# Remove png alpha layer
# without parallel - cmd.exe /c "FOR /R %f IN (*.png) DO magick mogrify -alpha off "%f""
cmd.exe /c 'dir *.png /s /b | %MParallel% --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -alpha off  \"{{0}}\""'

# Manual convert png textures and alpha layer into GIGAPIXEL or something else and go next steps, converted PNG suffix should be ".giga" something like Filename.giga.png
read-host "Now you need convert all PNG into units and alpha folders with you hands and gigapixel ai, converted PNG suffix should be .giga and press ENTER to continue..."
read-host "Sure?... press ENTER"
read-host "OK press ENTER last time"

# Remove all png exclude .giga and replace file names to png without .giga
Get-ChildItem *.png -Exclude  *.giga.png -Recurse | Remove-Item
Get-ChildItem -Recurse *.giga.png | Rename-Item  -NewName { $_.Name -replace '.giga.png','.png' }
cd ..;cd alpha;Get-ChildItem *.png -Exclude  *.giga.png -Recurse | Remove-Item;Get-ChildItem -Recurse *.giga.png | Rename-Item  -NewName { $_.Name -replace '.giga.png','.png' };cd ..;cd units

# Search and set alpha folder and add to path environment variable
cmd.exe /c 'cd .. && FOR /F "tokens=* USEBACKQ" %F IN (`"dir /ad /b | findstr -i  "alpha""`) DO (set "alphadir=%~dpnxF") && cd units'
cd ..;$env:alphadir = Get-ChildItem -Directory -Recurse -Include alpha | % { $_.FullName };cd units
cmd.exe /c "ECHO %alphadir%"
$env:alphadir

read-host "press ENTER if alpha directroy correctly set < IF NOT! SET IT! >"
read-host "press ENTER last time"

# Conver RGB alpha layer to grayscale
# without parallel -  cmd.exe /c "FOR /R %f IN (*.png) DO %magick% mogrify -colorspace Gray "%f""
cmd.exe /c 'dir *.png /s /b | %MParallel% --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -colorspace Gray \"%alphadir%\{{0:N}}.png\""'

# Collecting with each other alpha and rgb layers
# without parallel - cmd.exe /c "FOR /R %f IN (*.png) DO magick composite -compose CopyOpacity "%alphadir%\%~nf.png" "%f" "%f""
cmd.exe /c 'dir *.png /s /b | %MParallel% --ignore-exitcode --count=9 --stdin --no-split-lines --pattern="%magick% composite -compose CopyOpacity \"%alphadir%\{{0:N}}.png\" \"{{0}}\" \"{{0}}\""'

# Convert png to dds, nvtt work well
# without parallel -  cmd.exe /c "FOR /R %f IN (*.png) DO "C:\Program Files\NVIDIA Corporation\NVIDIA Texture Tools Exporter\nvtt_export.exe" -f bc3  -q 2 "%f"
cmd.exe /c 'dir *.png /s /b | %MParallel% --shell --ignore-exitcode --count=5 --stdin --no-split-lines --pattern="\"C:\Program Files\NVIDIA Corporation\NVIDIA Texture Tools Exporter\nvtt_export.exe\" -f bc3  -q 2 \"{{0}}\""'


# Rename dds to texture and delete png
Get-ChildItem -Recurse *.dds | Rename-Item -NewName { $_.Name -replace '.dds','.texture' }
Get-ChildItem -Recurse * -Include *.png | Remove-Item

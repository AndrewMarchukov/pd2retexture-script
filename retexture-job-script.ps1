# launch in units(textures) directory
# set image magick exe
cmd.exe /c 'set magick="C:\Program Files\ImageMagick-7.0.10-Q16-HDRI\magick.exe"'
cmd.exe /c 'set MParallel="E:\pd2extract\units\TOOLS\MParallel.exe"'
$env:magick = '"C:\Program Files\ImageMagick-7.0.10-Q16-HDRI\magick.exe"'
$env:MParallel = '"E:\pd2extract\units\TOOLS\MParallel.exe"'

$env:MParallel
$env:magick

# remove all non texture files and shit
Get-ChildItem -Recurse * -Include *.* -Exclude  *_df.texture | Remove-Item
Get-ChildItem -Directory -Recurse * -Include cubemaps | Remove-item

# rename texture to dds
Get-ChildItem -Recurse *.texture | Rename-Item -NewName { $_.Name -replace '.texture','.dds' }

# converting dds to png or use another converter and delete dds
cmd.exe /c "FOR /R %f IN (*.dds) DO %magick% mogrify -format png "%f""
Get-ChildItem -Recurse * -Include *.dds | Remove-Item

# extract png alpha layer
MKDIR alpha

# not parallel - cmd.exe /c "FOR /R %f IN (*.png) DO %magick% mogrify -path alpha "%f" -alpha extract "%f""
cmd.exe /c "dir *.png /s /b | %MParallel% --detached --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -path alpha \"{{0}}\" -alpha extract \"{{0}}\"""


# move alpha current folder on above folder
Move-Item -Path ./alpha -Destination ..

# remove png alpha layer
# not parallel - cmd.exe /c "FOR /R %f IN (*.png) DO magick mogrify -alpha off "%f""
cmd.exe /c "dir *.png /s /b | %MParallel% --ignore-exitcode --count=10 --stdin --no-split-lines --pattern="%magick% mogrify -alpha off  \"{{0}}\"""

# you need manual convert png textures and alpha layer into GIGAPIXEL or something else and go next steps, converted PNG suffix should be ".giga" something like Filename.giga.png
read-host "Now you need convert all PNG into units and alpha folders with you hands and gigapixel ai, converted PNG suffix should be .giga and press ENTER to continue..."
read-host "Sure?... press ENTER"
read-host "OK press ENTER last time"

# remove all png exclude .giga and replace file names to png without .giga
Get-ChildItem *.png -Exclude  *.giga.png -Recurse | Remove-Item
Get-ChildItem -Recurse *.giga.png | Rename-Item  -NewName { $_.Name -replace '.giga.png','.png' }

# collecting with each other alpha and rgb layers
cmd.exe /c 'cd .. && FOR /F "tokens=* USEBACKQ" %F IN (`"dir /ad /b | findstr -i  "alpha""`) DO (set "alphadir=%~dpnxF") && cd units'
cd ..;$env:alphadir = Get-ChildItem -Directory -Recurse -Include alpha | % { $_.FullName };cd units
cmd.exe /c "ECHO %alphadir%"
$env:alphadir

read-host "press ENTER if alpha directroy correctly set < IF NOT! SET IT! >"
read-host "press ENTER last time"
# not parallel - cmd.exe /c "FOR /R %f IN (*.png) DO magick composite -compose CopyOpacity "%alphadir%\%~nf.png" "%f" "%f""
cmd.exe /c "dir *.png /s /b | %MParallel% --ignore-exitcode --count=9 --stdin --no-split-lines --pattern="%magick% composite -compose CopyOpacity \"%alphadir%\{{0:N}}.png\" \"{{0}}\" \"{{0}}\"""

# convert png on dds, nvtt work well
# not parallel -  cmd.exe /c "FOR /R %f IN (*.png) DO "C:\Program Files\NVIDIA Corporation\NVIDIA Texture Tools Exporter\nvtt_export.exe" -f bc3  -q 2 "%f"
cmd.exe /c "dir *.png /s /b | %MParallel% --shell --detached --ignore-exitcode --count=5 --stdin --no-split-lines --pattern="\"C:\Program Files\NVIDIA Corporation\NVIDIA Texture Tools Exporter\nvtt_export.exe\" -f bc3  -q 2 \"{{0}}\"""


# rename dds to texture and delete png
Get-ChildItem -Recurse *.dds | Rename-Item -NewName { $_.Name -replace '.dds','.texture' }
Get-ChildItem -Recurse * -Include *.png | Remove-Item

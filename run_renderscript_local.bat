@echo off
set script="render_previews.ms"
set repo="X:\05_Benutzerordner\Jonas\rnd\material_library
set file="X:\05_Benutzerordner\Jonas\rnd\material_library\material_scene.max"


"C:\Program Files\Autodesk\3ds Max 2018\3dsmax" -silent -mip -q -batch -u MAXSCRIPT %script% %file%



sudo scoop bucket add versions
sudo scoop uninstall python38 -g
scoop cache rm *
scoop config MSIEXTRACT_USE_LESSMSI $true
sudo scoop install python38 -g

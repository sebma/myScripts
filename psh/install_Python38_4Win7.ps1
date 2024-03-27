sudo scoop bucket add versions
sudo scoop uninstall -g python38
scoop cache rm *
scoop config MSIEXTRACT_USE_LESSMSI $true
sudo scoop install -g python38

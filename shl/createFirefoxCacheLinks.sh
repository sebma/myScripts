#!/usr/bin/env bash

firefoxCacheDirname=cache2
cd $HOME/.mozilla/firefox/ && {
	firefoxProfileList=$(\ls -1d */ | grep -v Crash.Reports/)
	cd $HOME/.cache/mozilla/firefox && {
		for profile in $firefoxProfileList
		do
			cd $profile && {
				[ -d $firefoxCacheDirname ] && rm -fr $firefoxCacheDirname
				mkdir -p /tmp/`id -u`/${profile}$firefoxCacheDirname
				[ ! -L $firefoxCacheDirname ] && ln -s /tmp/`id -u`/${profile}$firefoxCacheDirname $firefoxCacheDirname
				cd ..
			}
		done
	}
}

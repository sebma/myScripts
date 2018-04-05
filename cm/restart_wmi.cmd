@rundll32 wbemupgd, UpgradeRepository
@net stop sharedaccess
@net stop winmgmt
@net start winmgmt
@net start sharedaccess
@net use p: /del && net use p: \\NASTIG003\DEF007_users$\X064304 /persistent:yes

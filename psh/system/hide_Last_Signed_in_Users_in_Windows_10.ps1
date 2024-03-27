# https://www.majorgeeks.com/content/page/how_to_hide_last_signed_in_users_in_windows_10.html

gpv HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -n dontdisplaylastusername

sp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -n dontdisplaylastusername -v 1

gpv HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -n dontdisplaylastusername

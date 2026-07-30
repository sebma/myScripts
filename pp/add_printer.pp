class customer::add_printer {
	if $::osfamily == 'RedHat' {
		package { 'cups':
			ensure => installed,
		}

		service { 'cups':
			ensure  => 'running',
			enable => true,
			require => Package['cups'],
			before => [
				Exec['remove-old-Old-Printer-printer'],
				Exec['add_printer'],
				Exec['set-My-Printer-as-default']
			]
		}

		package { ['samba-krb5-printing', 'samba-client', 'krb5-workstation']:
			ensure  => installed,
			require => Package['cups'],
		}

		exec { 'remove-old-Old-Printer-printer':
			command => ' /usr/sbin/lpadmin -x Old-Printer',
			onlyif  => ' /usr/bin/lpstat -p Old-Printer >/dev/null 2>&1',
		}

		exec { 'add_printer':
			command => '/usr/sbin/lpadmin -p "My-Printer" -v smb://printServer/My-Printer -m drv:///sample.drv/generic.ppd -o auth-info-required=negotiate -E',
			require => [Package['cups'], Package['samba-krb5-printing']],
			unless => "grep Old-Printer /etc/cups/printers.conf"
		}

		exec { 'set-My-Printer-as-default':
			command => ' /usr/sbin/lpadmin -d My-Printer',
			onlyif  => ' /usr/bin/lpstat -d My-Printer | /bin/grep "no .*default destination" -q',
		}
	}
}

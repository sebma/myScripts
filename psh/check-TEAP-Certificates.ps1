# vim: ft=ps1 noet:
ls Cert:\CurrentUser\My  | ? Subject -IMatch CN=.*media-participations.com | select Subject , Issuer , NotBefore , NotAfter | fl
ls Cert:\LocalMachine\My | ? Subject -IMatch CN=$env:COMPUTERNAME | select Subject , Issuer , NotBefore , NotAfter | fl

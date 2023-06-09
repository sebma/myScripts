#!/bin/sh

# Easy-RSA 3 -- A Shell-based CA Utility
#
# Copyright (C) 2018 by the Open-Source OpenVPN development community.
# A full list of contributors can be found on Github at:
#   https://github.com/OpenVPN/easy-rsa/graphs/contributors
#
# This code released under version 2 of the GNU GPL; see COPYING and the
# Licensing/ directory of this project for full licensing details.

# Help/usage output to stdout
usage() {
	# command help:
	print "
Easy-RSA 3 usage and overview

USAGE: easyrsa [options] COMMAND [command-options]

A list of commands is shown below. To get detailed usage and help for a
command, run:
  ./easyrsa help COMMAND

For a listing of options that can be supplied before the command, use:
  ./easyrsa help options

Here is the list of commands available with a short syntax reminder. Use the
'help' command above to get full usage details.

  init-pki [ cmd-opts ]
  build-ca [ cmd-opts ]
  gen-dh
  gen-req <file_name_base> [ cmd-opts ]
  sign-req <type> <file_name_base>
  build-client-full <file_name_base> [ cmd-opts ]
  build-server-full <file_name_base> [ cmd-opts ]
  build-serverClient-full <file_name_base> [ cmd-opts ]
  revoke <file_name_base> [ cmd-opts ]
  renew <file_name_base>
  revoke-renewed <file_name_base> [ cmd-opts ]
  rewind-renew <certificate_serial_number>
  rebuild <file_name_base> [ cmd-opts ]
  gen-crl
  update-db
  make-safe-ssl
  show-req <file_name_base> [ cmd-opts ]
  show-cert <file_name_base> [ cmd-opts ]
  show-ca [ cmd-opts ]
  show-crl
  show-expire <file_name_base> (Optional)
  show-revoke <file_name_base> (Optional)
  show-renew <file_name_base> (Optional)
  verify-cert <file_name_base>
  import-req <request_file_path> <short_name_base>
  export-p1 <file_name_base> [ cmd-opts ]
  export-p7 <file_name_base> [ cmd-opts ]
  export-p8 <file_name_base> [ cmd-opts ]
  export-p12 <file_name_base> [ cmd-opts ]
  set-pass  <file_name_base> [ cmd-opts ]
  upgrade <type>
"

	# collect/show dir status:
	text_only=1
	err_source="Not defined: vars autodetect failed and no value provided"
	work_dir="${EASYRSA:-$err_source}"
	pki_dir="${EASYRSA_PKI:-$err_source}"
	print "\
DIRECTORY STATUS (commands would take effect on these locations)
     EASYRSA: $work_dir
         PKI: $pki_dir
  x509-types: ${EASYRSA_EXT_DIR:-Missing or undefined}"

} # => usage()

# Detailed command help
# When called with no args, calls usage(), otherwise shows help for a command
# Please maintain strict indentation rules.
# Commands are TAB indented, while text is SPACE indented.
# 'case' indentation is minimalistic.
cmd_help() {
	unset -v text err_text opts text_only
	case "$1" in
	init-pki|clean-all)
		text="
* init-pki [ cmd-opts ]

      Removes & re-initializes the PKI directory for a new PKI"

		opts="
      * hard    - Recursively delete the PKI directory (default).
      * soft    - Keep the named PKI directory and PKI 'vars' file intact."
	;;
	build-ca)
		text="
* build-ca [ cmd-opts ]

      Creates a new CA"

		opts="
      * raw-ca  - ONLY use SSL binary to input CA password
        raw       (Equivalent to global option '--raw-ca')

      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')

      * subca   - Create an intermediate CA keypair and request
        intca     (default is a root CA)"
	;;
	gen-dh)
		text="
* gen-dh

      Generates DH (Diffie-Hellman) parameters"
	;;
	gen-req)
		text="
* gen-req <file_name_base> [ cmd-opts ]

      Generate a standalone private key and certificate signing request [CSR]

      This request is suitable for sending to a remote CA for signing."

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')
      * text    - Include certificate text in request"
	;;
	sign|sign-req)
		text="
* sign-req <type> <file_name_base>

      Sign a certificate request of the defined type. <type> must be a known type,
      such as: 'client', 'server', 'serverClient', or 'ca' (or a user-added type).
      All supported types are listed in the x509-types directory.

      This request file must exist in the reqs/ dir and have a .req file
      extension. See import-req below for importing reqs from other sources."
	;;
	build|build-client-full|build-server-full|build-serverClient-full)
		text="
* build-client-full <file_name_base> [ cmd-opts ]
* build-server-full <file_name_base> [ cmd-opts ]
* build-serverClient-full <file_name_base> [ cmd-opts ]

      Generate a keypair and sign locally for a client and/or server

      This mode uses the <file_name_base> as the X509 CN."

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')
      * inline  - Create an inline credentials file for this node"
	;;
	revoke)
		text="
* revoke <file_name_base> [reason]

      Revoke a certificate specified by the <file_name_base>,
      with an optional revocation reason which can be one of:
        unspecified
        keyCompromise
        CACompromise
        affiliationChanged
        superseded
        cessationOfOperation
        certificateHold"
	;;
	revoke-renewed)
		text="
* revoke-renewed <file_name_base> [reason]

      Revoke a *renewed* certificate specified by the <file_name_base>,
      with an optional revocation reason which can be one of:
        unspecified
        keyCompromise
        CACompromise
        affiliationChanged
        superseded
        cessationOfOperation
        certificateHold"
	;;
	rebuild)
		text="
* rebuild <file_name_base> [ cmd-opts ]

      Rebuild a certificate and key specified by <file_name_base>"

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')"
	;;
	renew)
		text="
* renew <file_name_base>

      Renew a certificate specified by <file_name_base>"
	;;
	rewind|rewind-renew)
		text="
* rewind-renew <certificate_serial_number>

      Rewind an EasyRSA version 3.0 'style' renewed certificate.
      Once 'rewind' has completed the certificate can be revoked
      by using: 'revoke-renewed <file_name_base> [reason]'

  * NOTE: This does NOT 'unrenew' or 'unrevoke' a certificate.
    Ref : https://github.com/OpenVPN/easy-rsa/issues/578"
	;;
	gen-crl)
		text="
* gen-crl

      Generate a certificate revocation list [CRL]"
	;;
	update-db)
		text="
* update-db

      Update the index.txt database

      This command will use the system time to update the status of
      issued certificates."
	;;
	make-safe-ssl)
		text="
* make-safe-ssl

      Generate a safe SSL config file"
	;;
	show-req|show-cert)
		text="
* show-req  <file_name_base> [ cmd-opts ]
* show-cert <file_name_base> [ cmd-opts ]

      Shows details of the req or cert referenced by <file_name_base>

      Human-readable output is shown, including any requested cert
      options when showing a request."

		opts="
      * full    - show full req/cert info, including pubkey/sig data"
	;;
	show-ca)
		text="
* show-ca [ cmd-opts ]

      Shows details of the Certificate Authority [CA] certificate

      Human-readable output is shown."

		opts="
      * full    - show full cert info, including pubkey/sig data"
	;;
	show-crl)
		text="
* show-crl

      Shows details of the current certificate revocation list (CRL)

      Human-readable output is shown."
	;;
	show-expire)
		text="
* show-expire [ <file_name_base> ]

      Shows details of *all* expiring certificates
      Use --renew-days=NN to extend the grace period (Default 90 days)
      Optionally, check *only* <file_name_base> certificate"
	;;
	show-revoke)
		text="
* show-revoke [ <file_name_base> ]

      Shows details of *all* revoked certificates.
      Optionally, check *only* <file_name_base> certificate"
	;;
	show-renew)
		text="
* show-renew [ <file_name_base> ]

      Shows details of renewed certificates, which have not been revoked
      Optionally, check *only* <file_name_base> certificate"
	;;
	verify|verify-cert)
		text="
* verify-cert <file_name_base> [ cmd-opts ]

      Verify certificate against CA

      Returns the current validity of the certificate."

		opts="
      * batch   - On failure to verify, return error (1) to caller"
	;;
	import-req)
		text="
* import-req <request_file_path> <short_name_base>

      Import a certificate request from a file

      This will copy the specified file into the reqs/ dir in
      preparation for signing.

      The <short_name_base> is the <file_name_base> to create.

      Example usage:
        import-req /some/where/bob_request.req bob"
	;;
	export-p12)
		text="
* export-p12 <file_name_base> [ cmd-opts ]

      Export a PKCS#12 file with the keypair,
      specified by <file_name_base>"

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')
      * noca    - Do not include the ca.crt file in the PKCS12 output
      * nokey   - Do not include the private key in the PKCS12 output
      * usefn   - Use <file_name_base> as friendly name"
	;;
	export-p7)
		text="
* export-p7 <file_name_base> [ cmd-opts ]

      Export a PKCS#7 file with the pubkey,
      specified by <file_name_base>"

		opts="
      * noca    - Do not include the ca.crt file in the PKCS7 output"
	;;
	export-p8)
		text="
* export-p8 <file_name_base> [ cmd-opts ]

      Export a PKCS#8 file with the private key,
      specified by <file_name_base>"

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')"
	;;
	export-p1)
		text="
* export-p1 <file_name_base> [ cmd-opts ]

      Export a PKCS#1 (RSA format) file with the pubkey,
      specified by <file_name_base>"

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')"
	;;
	set-pass|set-ed-pass|set-rsa-pass|set-ec-pass)
		text="
* set-pass <file_name_base> [ cmd-opts ]

      Set a new passphrase for the private key specified by <file_name_base>

  DEPRECATED: 'set-rsa-pass' and 'set-ec-pass'"

		opts="
      * nopass  - Do not encrypt the private key (default is encrypted)
                  (Equivalent to global option '--nopass|--no-pass')
      * file    - (Advanced) Treat the file as a raw path, not a short-name"
	;;
	upgrade)
		text="
* upgrade <type>

      Upgrade EasyRSA PKI and/or CA.

      Upgrade <type> must be one of:

      * pki - Upgrade EasyRSA v2.x PKI to EasyRSA v3.x PKI (includes CA below)
      * ca  - Upgrade EasyRSA v3.0.5 CA or older to EasyRSA v3.0.6 CA or later."
	;;
	altname|subjectaltname|san)
		text_only=1
		text="
* Option: --subject-alt-name=SAN_FORMAT_STRING

      This global option adds a subjectAltName to the request or issued
      certificate. It MUST be in a valid format accepted by openssl or
      req/cert generation will fail. Note that including multiple such names
      requires them to be comma-separated; further invocations of this
      option will REPLACE the value.

      Examples of the SAN_FORMAT_STRING shown below:

      * DNS:alternate.example.net
      * DNS:primary.example.net,DNS:alternate.example.net
      * IP:203.0.113.29
      * email:alternate@example.net"
	;;
	--days|days)
		text_only=1
		text="
* Option: --days=DAYS

      This global option is an alias for one of the following:
      * Expiry days for a new CA.
        eg: '--days=3650 build-ca'
      * Expiry days for new/renewed certificate.
        eg: '--days=1095 renew server'
      * Expiry days for certificate revokation list.
        eg: '--days=180 gen-crl'
      * Cutoff days for command: show-expire.
        eg: '--days=90 show-expire'"
	;;
	--req-cn|req-cn)
		text_only=1
		text="
* Option: --req-cn=NAME

      This specific option can set the CSR commonName.

      Can only be used in BATCH mode for the following commands:
      * To build a new CA [or Sub-CA]:
        eg: '--batch --req-cn=NAME build-ca [subca]'
      * To generate a certificate signing request:
        eg: '--batch --req-cn=NAME gen-req <file_name_base>'"
	;;
	opts|options)
		opt_usage
	;;
	"")
		usage ;;
	*)
		err_text="
  Unknown command: '$1' (try without commands for a list of commands)"
		easyrsa_error_exit=1
	esac

	if [ "$err_text" ]; then
		print "${err_text}${NL}"
	else
		# display the help text
		[ "$text" ] && print "$text"

		if [ "$text_only" ]; then
			: # ok - No opts message required
		else
			print "
Available command options [ cmd-opts ]:
${opts:-
      * No supported command options}"
		fi
	fi
} # => cmd_help()

# Options usage
opt_usage() {
	text_only=1
	print "
Easy-RSA Global Option Flags

The following options may be provided before the command. Options specified
at runtime override env-vars and any 'vars' file in use. Unless noted,
non-empty values to options are mandatory.

General options:

--version       : Prints EasyRSA version and build information
--batch         : Set automatic (no-prompts when possible) mode
--silent|-s     : Disable all warnings, notices and information
--sbatch        : Combined --silent and --batch operating mode
--silent-ssl|-S : Silence SSL output (Requires bach mode)

--no-pass       : Do not use passwords
                  Can not be used with --passin or --passout
--passin=ARG    : Set -passin ARG for openssl (eg: pass:xEasyRSAy)
--passout=ARG   : Set -passout ARG for openssl (eg: pass:xEasyRSAy)
--raw-ca        : Build CA with password via RAW SSL input

--vars=FILE     : Define a specific 'vars' file to use for Easy-RSA config
                  (Default vars file is in the EasyRSA PKI directory)
--pki-dir=DIR   : Declare the PKI directory
                  (Default PKI directory is sub-directory 'pki')

--ssl-conf=FILE : Define a specific OpenSSL config file for Easy-RSA to use
                  (Default config file is in the EasyRSA PKI directory)
--force-safe-ssl: Always generate a safe SSL config file
                  (Default: Generate Safe SSL config once per instance)
--no-safe-ssl   : OpenSSL Only: Do not use a safe SSL config file

--tmp-dir=DIR   : Declare the temporary directory
                  (Default temporary directory is the EasyRSA PKI directory)
--keep-tmp=NAME : Keep the original temporary session by name: NAME
                  NAME is a sub-directory of the dir declared by --tmp-dir
                  This option ALWAYS over-writes a sub-dir of the same name.

Certificate & Request options: (these impact cert/req field values)

--no-text       : Create certificates without human readable text
--days=#        : Sets the signing validity to the specified number of days
                  Also applies to renewal period. For details, see: 'help days'
--startdate=DATE: Sets the SSL option '-startdate' (Format 'YYYYMMDDhhmmssZ')
--enddate=DATE  : Sets the SSL option '-enddate' (Format 'YYYYMMDDhhmmssZ')

--digest=ALG    : Digest to use in the requests & certificates
--keysize=#     : Size in bits of keypair to generate (RSA Only)
--use-algo=ALG  : Crypto alg to use: choose rsa (default), ec or ed
--curve=NAME    : For elliptic curve, sets the named curve (Default: secp384r1)

--subca-len=#   : Path length of signed intermediate CA certificates
--copy-ext      : Copy included request X509 extensions (namely subjAltName)
--san|--subject-alt-name
                : Add a subjectAltName.
                  For more info and syntax, see: 'easyrsa help altname'

Distinguished Name mode:

--dn-mode=MODE  : Distinguished Name mode to use 'cn_only' (Default) or 'org'

--req-cn=NAME   : Set CSR commonName to NAME. For details, see: 'help req-cn'

  Distinguished Name Organizational options: (only used with '--dn-mode=org')
  --req-c=CC           : Country code (2-letters)
  --req-st=NAME        : State/Province
  --req-city=NAME      : City/Locality
  --req-org=NAME       : Organization
  --req-email=NAME     : Email addresses
  --req-ou=NAME        : Organizational Unit
  --req-serial=VALUE   : Entity serial number (Only used when declared)

Deprecated features:

--ns-cert             : Include deprecated Netscape extensions
--ns-comment=COMMENT  : Include deprecated Netscape comment (may be blank)"
} # => opt_usage()

# Wrapper around printf - clobber print since it's not POSIX anyway
# print() is used internally, so MUST NOT be silenced.
# shellcheck disable=SC1117
print() { printf "%s\n" "$*" || exit 1; }

# Exit fatally with a message to stderr
# present even with EASYRSA_BATCH as these are fatal problems
die() {
	print "
Easy-RSA error:

$1
"
	if [ "$error_info" ]; then
		print "${error_info}${NL}"
	fi

	show_host
	exit "${2:-1}"
} # => die()

# Necessary verbose warnings
# This is a debug function for status-reports and date
verbose() {
	[ "$EASYRSA_VERBOSE" ] || return 0
	printf '%s\n' "  > $*"
} # => verbose()

# non-fatal warning output
warn() {
	[ "$EASYRSA_SILENT" ] && return
	print "
WARNING
=======
$1
" 1>&2
} # => warn()

# informational notices to stdout
notice() {
	[ "$EASYRSA_SILENT" ] && return
	print "
Notice
------
$1"
} # => notice()

# Helpful information
information() {
	[ "$EASYRSA_SILENT" ] && return
	print "
* $1"
} # => information()

# intent confirmation helper func
# returns without prompting in EASYRSA_BATCH
confirm() {
	[ "$EASYRSA_BATCH" ] && return
	prompt="$1"
	value="$2"
	msg="$3"
	input=""
	print "\
$msg

Type the word '$value' to continue, or any other input to abort."
	printf %s "  $prompt"
	# shellcheck disable=SC2162 # read without -r will mangle backslashes
	read input
	printf '\n'
	[ "$input" = "$value" ] && return
	easyrsa_error_exit=1
	notice "Aborting without confirmation."
	cleanup 9
} # => confirm()

# Generate random hex
# Cannot use easyrsa-openssl() due to chicken vs egg,
# easyrsa_openssl() creates temp-files,
# which needs `openssl rand`.
# Redirect error-out, ignore complaints of missing config
easyrsa_random() {
	case "$1" in
	(*[!1234567890]*|0*|"") : ;; # invalid input
	(*)
		# Only return on success
		if "$EASYRSA_OPENSSL" rand -hex "$1" 2>/dev/null
		then
			return
		fi
	esac
	die "easyrsa_random failed"
} # => easyrsa_random()

# Create session directory atomically or fail
secure_session() {
	# Session is already defined
	[ "$secured_session" ] && \
		die "session overload"

	# temporary directory must exist
	if [ "$EASYRSA_TEMP_DIR" ] && \
		[ -d "$EASYRSA_TEMP_DIR" ]
	then
		: # ok
	else
		die "secure_session - Missing temporary directory:
* $EASYRSA_TEMP_DIR"
	fi

	for i in 1 2 3; do
		session="$(
			easyrsa_random 4
			)" || die "secure_session - session"
		secured_session="${EASYRSA_TEMP_DIR}/${session}"

		# atomic:
		if mkdir "$secured_session"; then
			# New session requires safe-ssl conf
			unset -v mktemp_counter \
				OPENSSL_CONF easyrsa_safe_ssl_conf \
				working_safe_ssl_conf
			verbose "\
secure_session: CREATED: $secured_session"
			return
		fi
	done
	die "secure_session failed"
} # => secure_session()

# Remove secure session
remove_secure_session() {
	if [ "${secured_session%/*}" ] && \
		[ -d "$secured_session" ]
	then
		# Always remove temp-session
		if rm -rf "$secured_session"; then
			verbose "\
remove_secure_session: DELETED: $secured_session"
			unset -v secured_session mktemp_counter \
				OPENSSL_CONF easyrsa_safe_ssl_conf \
				working_safe_ssl_conf
			return
		fi
	fi

	die "remove_secure_session: $secured_session"
} # => remove_secure_session()

# Create temp-file atomically or fail
# WARNING: Running easyrsa_openssl in a subshell
# will hide error message and verbose messages
# from easyrsa_mktemp()
easyrsa_mktemp() {
	[ "$#" = 1 ] || die "\
easyrsa_mktemp - input error"

	# session directory must exist
	[ "$secured_session" ] || die "\
easyrsa_mktemp - Temporary session undefined"

	# Update counter
	mktemp_counter="$(( mktemp_counter + 1 ))"

	# Assign internal temp-file name
	t="${secured_session}/temp.${mktemp_counter}"

	# Create shotfile
	for h in x y z; do
		shotfile="${t}.${h}"
		if [ -e "$shotfile" ]; then
			verbose "\
easyrsa_mktemp: shot-file EXISTS: $shotfile"
			continue
		else
			printf "" > "$shotfile" || die "\
easyrsa_mktemp: create shotfile failed (1) $1"

			# Create temp-file or die
			# subshells do not update mktemp_counter,
			# which is why this extension is required.
			# Current max required is 7 deep
			for i in 1 2 3 4 5 6 7 8 9 10; do
				want_tmp_file="${t}.${i}"
				if [ -e "$want_tmp_file" ]; then
					verbose "\
easyrsa_mktemp: temp-file EXISTS: $want_tmp_file"
					continue
				else
					# atomic:
					[ "$easyrsa_host_os" = win ] && {
						set -o noclobber
					}

					if mv "$shotfile" "$want_tmp_file"; then
						# Assign external temp-file name
						if force_set_var "$1" "$want_tmp_file"
						then
							verbose "\
easyrsa_mktemp: $1 temp-file OK: $want_tmp_file"
							[ "$easyrsa_host_os" = win ] && {
								set +o noclobber
							}
							unset -v want_tmp_file shotfile
							return
						else
							die "\
easyrsa_mktemp - force_set_var $1 failed"
						fi
					fi
				fi
			done
		fi
	done

	die "\
easyrsa_mktemp - failed for: $1 @ depth=$i
want_tmp_file: $want_tmp_file"
} # => easyrsa_mktemp()

# remove temp files and do terminal cleanups
cleanup() {
	if [ "${secured_session%/*}" ] && \
		[ -d "$secured_session" ]
	then
		# Remove temp-session or create temp-snapshot
		if [ "$EASYRSA_KEEP_TEMP" ]
		then
			# skip on black-listed directory names, with a warning
			if [ -e "$EASYRSA_TEMP_DIR/$EASYRSA_KEEP_TEMP" ]
			then
				warn "\
Prohibited value for --keep-tmp: '$EASYRSA_KEEP_TEMP'
Temporary session not preserved."
			else
				# create temp-snapshot
				keep_tmp="$EASYRSA_TEMP_DIR/tmp/$EASYRSA_KEEP_TEMP"
				mkdir -p "$keep_tmp"
				rm -rf "$keep_tmp"
				mv -f "$secured_session" "$keep_tmp"
				print "Temp session preserved: $keep_tmp"
			fi
		else
			# remove temp-session
			remove_secure_session || \
				die "cleanup - remove_secure_session"
		fi
	fi

	# Remove files when build_full()->sign_req() is interrupted
	[ "$error_build_full_cleanup" ] && \
		rm -f "$crt_out" "$req_out" "$key_out"

	# Restore files when renew is interrupted
	[ "$error_undo_renew_move" ] && renew_restore_move
	# Restore files when rebuild is interrupted
	[ "$error_undo_rebuild_move" ] && rebuild_restore_move

	# shellcheck disable=SC3040
	# In POSIX sh, set option [name] is undefined
	case "$prompt_restore" in
		0) : ;; # Not required
		1) [ -t 1 ] && stty echo ;;
		2) set -o echo ;;
		*) warn "prompt_restore: '$prompt_restore'"
	esac

	# Get a clean line
	[ "$EASYRSA_SILENT" ] || print

	# Clear traps
	trap - 0 1 2 3 6 15

	# Exit: Known errors:
	# -> confirm(): aborted
	# -> verify_cert(): verify failed --batch mode
	if [ "$easyrsa_error_exit" ]; then
		exit 1
	fi

	# Exit: SIGINT
	if [ "$1" = 2 ]; then
		kill -2 "$$"
	fi

	# Exit: Final Success
	if [ "$1" = ok ]; then
		# if there is no error
		# then 'cleanup ok' is called
		exit 0
	fi

	# Exit: Final Fail
	# if 'cleanup' is called without 'ok'
	# then an error occurred
	exit 1
} # => cleanup()

# Make a copy safe SSL config file
make_safe_ssl() {
	verify_pki_init
	EASYRSA_FORCE_SAFE_SSL=1
	easyrsa_openssl makesafeconf
	notice "\
Safe SSL config file created at:
* $EASYRSA_SAFE_CONF"
	verbose "\
make_safe_ssl: NEW SSL cnf file: $easyrsa_safe_ssl_conf"
} # => make_safe_ssl_copy()

# Escape hazardous characters
escape_hazard() {
	# Assign temp file
	easyrsa_vars_org=""
	easyrsa_mktemp easyrsa_vars_org || die \
		"escape_hazard - easyrsa_mktemp easyrsa_vars_org"

	# write org fields to org temp-file and escape '&' and '$'
	print "\
export EASYRSA_REQ_COUNTRY=\"$EASYRSA_REQ_COUNTRY\"
export EASYRSA_REQ_PROVINCE=\"$EASYRSA_REQ_PROVINCE\"
export EASYRSA_REQ_CITY=\"$EASYRSA_REQ_CITY\"
export EASYRSA_REQ_ORG=\"$EASYRSA_REQ_ORG\"
export EASYRSA_REQ_OU=\"$EASYRSA_REQ_OU\"
export EASYRSA_REQ_EMAIL=\"$EASYRSA_REQ_EMAIL\"
export EASYRSA_REQ_SERIAL=\"$EASYRSA_REQ_SERIAL\"
" | sed -e s\`'\&'\`'\\\&'\`g \
		-e s\`'\$'\`'\\\$'\`g \
			> "$easyrsa_vars_org" || die "\
escape_hazard - Failed to write temp-file"

	# Reload fields from fully escaped temp-file
	# shellcheck disable=SC1090 # can't follow ...
	(. "$easyrsa_vars_org") || die "\
escape_hazard - Failed to source temp-file"
	# shellcheck disable=SC1090 # can't follow ...
	. "$easyrsa_vars_org"
} # => escape_hazard()

# Replace environment variable names with current value
# and write to temp-file or return error from sed
easyrsa_rewrite_ssl_config () {
	# shellcheck disable=SC2016 # No expansion inside ''
	sed \
\
-e s\`'$dir'\`\
\""$EASYRSA_PKI"\"\`g \
\
-e s\`'$ENV::EASYRSA_PKI'\`\
\""$EASYRSA_PKI"\"\`g \
\
-e s\`'$ENV::EASYRSA_CERT_EXPIRE'\`\
\""$EASYRSA_CERT_EXPIRE"\"\`g \
\
-e s\`'$ENV::EASYRSA_CRL_DAYS'\`\
\""$EASYRSA_CRL_DAYS"\"\`g \
\
-e s\`'$ENV::EASYRSA_DIGEST'\`\
\""$EASYRSA_DIGEST"\"\`g \
\
-e s\`'$ENV::EASYRSA_KEY_SIZE'\`\
\""$EASYRSA_KEY_SIZE"\"\`g \
\
-e s\`'$ENV::EASYRSA_DN'\`\
\""$EASYRSA_DN"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_CN'\`\
\""$EASYRSA_REQ_CN"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_COUNTRY'\`\
\""$EASYRSA_REQ_COUNTRY"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_PROVINCE'\`\
\""$EASYRSA_REQ_PROVINCE"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_CITY'\`\
\""$EASYRSA_REQ_CITY"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_ORG'\`\
\""$EASYRSA_REQ_ORG"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_OU'\`\
\""$EASYRSA_REQ_OU"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_EMAIL'\`\
\""$EASYRSA_REQ_EMAIL"\"\`g \
\
-e s\`'$ENV::EASYRSA_REQ_SERIAL'\`\
\""$EASYRSA_REQ_SERIAL"\"\`g \
\
	"$EASYRSA_SSL_CONF" > "$easyrsa_safe_ssl_conf"
} # => easyrsa_rewrite_ssl_config()

# Easy-RSA meta-wrapper for SSL
# WARNING: Running easyrsa_openssl in a subshell
# will hide error message and verbose messages
easyrsa_openssl() {
	openssl_command="$1"; shift

	# Do not allow 'rand' here, see easyrsa_random()
	case "$openssl_command" in
		rand) die "easyrsa_openssl: Illegal SSL command: rand" ;;
		makesafeconf) require_safe_ssl_conf=1 ;;
		ca|req|srp|ts) has_config=1 ;;
		*) unset -v has_config
	esac

	# OpenSSL 1x genpkey does not support -config
	# OpenSSL 3x genpkey requires -config
	# LibreSSL passes the test without -config ..
	if [ "$openssl_command" = genpkey ] && \
		[ "$ssl_lib" = openssl ] && [ "$osslv_major" = 3 ]
	then
		has_config=1
	fi

	# Make LibreSSL safe config file from OpenSSL config file
	# $require_safe_ssl_conf is ALWAYS set by verify_ssl_lib()
	# Can be over-ruled for OpenSSL by option --no-safe-ssl
	if [ "$require_safe_ssl_conf" ] || \
		[ "$EASYRSA_FORCE_SAFE_SSL" ]
	then

		# Only create a new safe config,
		# if it has not been done before.
		# EASYRSA_FORCE_SAFE_SSL will always over-ride
		if  [ -z "$EASYRSA_FORCE_SAFE_SSL" ] && \
			[ "$working_safe_ssl_conf" ]
		then
			# ok - This has been done before
			# Set SAFE SSL conf to working SAFE SSL conf
			easyrsa_safe_ssl_conf="$working_safe_ssl_conf"
			verbose "\
easyrsa_openssl: escape_hazard SKIPPED"
			verbose "\
easyrsa_openssl: easyrsa_rewrite_ssl_config SKIPPED"
		else
			# Auto-escape hazardous characters:
			# '&' - Workaround 'sed' behavior
			# '$' - Workaround 'easyrsa' based limitation
			# This is required for all SSL libs, otherwise,
			# there are unacceptable differences in behavior
			escape_hazard || \
				die "easyrsa_openssl - escape_hazard failed"
			verbose "\
easyrsa_openssl: escape_hazard COMPLETED"

			# Assign easyrsa_safe_ssl_conf temp-file
			easyrsa_safe_ssl_conf=""
			easyrsa_mktemp easyrsa_safe_ssl_conf || die "\
easyrsa_openssl - easyrsa_mktemp easyrsa_safe_ssl_conf"

			# Write a safe SSL config temp-file
			if easyrsa_rewrite_ssl_config; then
				verbose "\
easyrsa_openssl: easyrsa_rewrite_ssl_config COMPLETED"
				# Save the the safe conf file-name
				working_safe_ssl_conf="$easyrsa_safe_ssl_conf"
				verbose "\
easyrsa_openssl: NEW SAFE SSL config: $easyrsa_safe_ssl_conf"
			else
				die "\
easyrsa_openssl - easyrsa_rewrite_ssl_config"
			fi
		fi

	else
		# Assign safe temp file as Original openssl-easyrsa.conf
		easyrsa_safe_ssl_conf="$EASYRSA_SSL_CONF"
		verbose "easyrsa_openssl: No SAFE SSL config"
	fi

	# VERIFY safe temp-file exists
	if [ -e "$easyrsa_safe_ssl_conf" ]; then
		verbose "\
easyrsa_openssl: Safe SSL conf OK: $easyrsa_safe_ssl_conf"
	else
		die "\
easyrsa_openssl - Safe SSL conf MISSING: $easyrsa_safe_ssl_conf"
	fi

	# set $OPENSSL_CONF - Use which-ever file is assigned above
	export OPENSSL_CONF="$easyrsa_safe_ssl_conf"

	# Execute command - Return on success
	if [ "$openssl_command" = "makesafeconf" ]; then
		# COPY temp-file to safessl-easyrsa.cnf
		cp -f "$easyrsa_safe_ssl_conf" "$EASYRSA_SAFE_CONF" && \
				return

	elif [ "$has_config" ]; then
		# Exec SSL with -config temp-file
		if [ "$EASYRSA_SILENT_SSL" ] && [ "$EASYRSA_BATCH" ]
		then
			"$EASYRSA_OPENSSL" "$openssl_command" \
				-config "$easyrsa_safe_ssl_conf" "$@" \
				2>/dev/null && \
					return
		else
			"$EASYRSA_OPENSSL" "$openssl_command" \
				-config "$easyrsa_safe_ssl_conf" "$@" && \
					return
		fi

	else
		# Exec SSL without -config temp-file
		if [ "$EASYRSA_SILENT_SSL" ] && [ "$EASYRSA_BATCH" ]
		then
			"$EASYRSA_OPENSSL" "$openssl_command" "$@" \
				2>/dev/null && \
					return
		else
			"$EASYRSA_OPENSSL" "$openssl_command" "$@" && \
					return
		fi
	fi

	# Always fail here
	die "\
easyrsa_openssl - Command has failed:
* $EASYRSA_OPENSSL $openssl_command \
${has_config:+-config $easyrsa_safe_ssl_conf }$*"
} # => easyrsa_openssl()

# Verify the SSL library is functional and establish version dependencies
verify_ssl_lib() {
	# Run once only
	[ "$EASYRSA_SSL_OK" ] && die "verify_ssl_lib - Overloaded"
	EASYRSA_SSL_OK=1

	# redirect std-err to ignore missing etc/ssl/openssl.cnf file
	val="$("$EASYRSA_OPENSSL" version 2>/dev/null)"

	# SSL lib name
	case "${val%% *}" in
		# OpenSSL does require a safe config-file for ampersand
		OpenSSL)
			ssl_lib=openssl
			if [ -z "$EASYRSA_NO_SAFE_SSL" ]; then
				require_safe_ssl_conf=1
			fi
		;;
		LibreSSL)
			ssl_lib=libressl
			require_safe_ssl_conf=1
			if [ "$EASYRSA_NO_SAFE_SSL" ]; then
				die "Cannot use '--no-safe-ssl' with LibreSSL"
			fi
		;;
		*)
			error_msg="$("$EASYRSA_OPENSSL" version 2>&1)"
			die "\
* OpenSSL must either exist in your PATH
  or be defined in your vars file.

Invalid SSL output for 'version':

$error_msg"
	esac

	# Set SSL version dependent $no_password option
	osslv_major="${val#* }"
	osslv_major="${osslv_major%%.*}"
	case "$osslv_major" in
		1) no_password='-nodes' ;;
		2) no_password='-nodes' ;;
		3)
			case "$ssl_lib" in
				openssl) no_password='-noenc' ;;
				libressl) no_password='-nodes' ;;
				*) die "Unsupported SSL library: $ssl_lib"
			esac
		;;
		*) die "Unsupported SSL library: $osslv_major"
	esac
	ssl_version="$val"
} # => verify_ssl_lib()

# Basic sanity-check of PKI init and complain if missing
verify_pki_init() {
	help_note="Run easyrsa without commands for usage and command help."

	# Check for defined EASYRSA_PKI
	[ "$EASYRSA_PKI" ] || die "\
EASYRSA_PKI env-var undefined"

	# check that the pki dir exists
	[ -d "$EASYRSA_PKI" ] || die "\
EASYRSA_PKI does not exist (perhaps you need to run init-pki)?
Expected to find the EASYRSA_PKI at: $EASYRSA_PKI
$help_note"

	# verify expected dirs present:
	for i in private reqs; do
		[ -d "$EASYRSA_PKI/$i" ] || die "\
Missing expected directory: $i (perhaps you need to run init-pki?)
$help_note"
	done
	unset -v help_note
} # => verify_pki_init()

# Verify core CA files present
verify_ca_init() {
	# First check the PKI has been initialized
	verify_pki_init

	help_note="Run without commands for usage and command help."

	# Verify expected files are present. Allow files to be regular files
	# (or symlinks), but also pipes, for flexibility with ca.key
	for i in ca.crt private/ca.key index.txt index.txt.attr serial; do
		if [ ! -f "$EASYRSA_PKI/$i" ] && [ ! -p "$EASYRSA_PKI/$i" ]; then
			[ "$1" = "test" ] && return 1
			die "\
Missing expected CA file: $i (perhaps you need to run build-ca?)
$help_note"
		fi
	done

	# When operating in 'test' mode, return success.
	# test callers don't care about CA-specific dir structure
	[ "$1" = "test" ] && return 0

	# verify expected CA-specific dirs:
	for i in issued certs_by_serial
	do
		[ -d "$EASYRSA_PKI/$i" ] || die "\
Missing expected CA dir: $i (perhaps you need to run build-ca?)
$help_note"
	done

	# explicitly return success for callers
	unset -v help_note
	return 0
} # => verify_ca_init()

# init-pki backend:
init_pki() {
	# Process command options
	reset="hard"
	while [ "$1" ]; do
		case "$1" in
			hard-reset|hard) reset="hard" ;;
			soft-reset|soft) reset="soft"; old_vars_true=1 ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# If EASYRSA_PKI exists, confirm before deletion
	if [ -e "$EASYRSA_PKI" ]; then
		confirm "Confirm removal: " "yes" "\
WARNING!!!

You are about to remove the EASYRSA_PKI at:
* $EASYRSA_PKI

and initialize a fresh PKI here."

		# now remove it:
		case "$reset" in
		hard)

			# Promote use of soft init
			confirm "Remove current 'vars' file? " yes "\
* SECOND WARNING!!!

* This will remove everything in your current PKI directory.
  To keep your current settings use 'init-pki soft' instead.
  Using 'init-pki soft' is recommended."

			# # # shellcheck disable=SC2115 # Use "${var:?}"
			rm -rf "$EASYRSA_PKI" || \
				die "init-pki hard reset failed."

			# If vars was in the old pki, it has been removed
			# If vars was somewhere else, it is user defined
			# Clear found_vars, we MUST not find pki/vars
			[ "$vars_in_pki" ] && unset -v found_vars
		;;
		soft)
		# There is no unit test for a soft reset
			for i in ca.crt crl.pem \
				issued private reqs inline revoked renewed \
				serial serial.old index.txt index.txt.old \
				index.txt.attr index.txt.attr.old \
				ecparams certs_by_serial
			do
				# # # shellcheck disable=SC2115 # Use "${var:?}"
				rm -rf "$EASYRSA_PKI/$i" || \
					die "init-pki soft reset failed."
			done
		;;
		*)
			die "Unknown reset type: $reset"
		esac
	fi

	# new dirs:
	for i in private reqs; do
		mkdir -p "$EASYRSA_PKI/$i" || \
			die "\
Failed to create PKI file structure (permissions?)"
	done

	# Install data-files into ALL new PKIs
	install_data_to_pki init-pki || \
		warn "\
Failed to install required data-files to PKI. (init)"

	notice "\
'init-pki' complete; you may now create a CA or requests.

Your newly created PKI dir is:
* $EASYRSA_PKI"

	# Installation information
	# if $no_new_vars then there are one or more known vars
	# which are not in the PKI. All further commands will fail
	# until vars is manually corrected
	[ "$no_new_vars" ] || information "\
Using Easy-RSA configuration: $vars"

	# For new PKIs , pki/vars was auto-created, show message
	if [ "$new_vars_true" ]; then
		information "\
IMPORTANT: \
Easy-RSA 'vars' template file has been created in your new PKI.
             \
Edit this 'vars' file to customise the settings for your PKI.
             \
To use a global vars file, use global option --vars=<YOUR_VARS>"

	elif [ "$user_vars_true" ] || [ "$old_vars_true" ] || \
		[ "$no_new_vars" ]
	then
		: # ok - User defined, old or no vars file exist
	else
		# Not in PKI and not user defined
		prefer_vars_in_pki_msg
	fi
	information "Using x509-types directory: $EASYRSA_EXT_DIR"
} # => init_pki()

# Must be used in two places, so made it a function
prefer_vars_in_pki_msg() {
	information "\
The preferred location for 'vars' is within the PKI folder.
  To silence this message move your 'vars' file to your PKI
  or declare your 'vars' file with option: --vars=<FILE>"
} # => prefer_vars_in_pki_msg()

# Copy data-files from various sources
install_data_to_pki() {
#
# Explicitly find and optionally copy data-files to the PKI.
# During 'init-pki' this is the new default.
# During all other functions these requirements are tested for
# and files will be copied to the PKI, if they do not already
# exist there.
#
# One reason for this is to make packaging work.

	context="$1"
	shift

	# Set required sources
	vars_file='vars'
	vars_file_example='vars.example'
	ssl_cnf_file='openssl-easyrsa.cnf'
	x509_types_dir='x509-types'

	# "$EASYRSA_PKI" - Preferred
	# "$EASYRSA" - Old default and Windows
	# "$PWD" - Usually the same as above, avoid
	# "${0%/*}" - Usually the same as above, avoid
	# '/usr/local/share/easy-rsa' - Default user installed
	# '/usr/share/easy-rsa' - Default system installed
	# Room for more..
	# '/etc/easy-rsa' - Last resort

	# Find and optionally copy data-files, in specific order
	for area in \
		"$EASYRSA_PKI" \
		"$EASYRSA" \
		"$PWD" \
		"${0%/*}" \
		'/usr/local/share/easy-rsa' \
		'/usr/share/easy-rsa' \
		'/etc/easy-rsa' \
		# EOL
	do
		if [ "$context" = x509-types-only ]; then
			# Find x509-types ONLY
			# Declare in preferred order, first wins
			# beaten by command line.
			[ -e "${area}/${x509_types_dir}" ] && set_var \
				EASYRSA_EXT_DIR "${area}/${x509_types_dir}"
		else
			# Find x509-types ALSO
			# Declare in preferred order, first wins
			# beaten by command line.
			[ -e "${area}/${x509_types_dir}" ] && set_var \
				EASYRSA_EXT_DIR "${area}/${x509_types_dir}"

			# Find other files - Omitting "$vars_file"
			for source in \
				"$vars_file_example" \
				"$ssl_cnf_file" \
				# EOL
			do
				# Find each item
				[ -e "${area}/${source}" ] || continue

				# If source does not exist in PKI then copy it
				if [ -e "${EASYRSA_PKI}/${source}" ]; then
					continue
				else
					cp "${area}/${source}" "$EASYRSA_PKI" || die \
						"Failed to copy to PKI: ${area}/${source}"
				fi
			done
		fi
	done

	# Short circuit for x509-types-only
	if [ "$context" = x509-types-only ]; then
		verbose "install_data_to_pki: x509-types-only COMPLETED"
		return
	fi

	# Create PKI/vars from PKI/example
	unset -v new_vars_true
	if [ "$found_vars" ] || [ "$user_vars_true" ] || \
		[ "$no_new_vars" ]
	then
		: # ok - Do not make a PKI/vars if another vars exists
	else
		case "$context" in
		init-pki)
			# Only create for 'init-pki', if one does not exist
			# 'init-pki soft' should have it's own 'vars' file
			if [ -e "${EASYRSA_PKI}/${vars_file_example}" ] && \
				[ ! -e "${EASYRSA_PKI}/${vars_file}" ]
			then
				# Failure means that no vars will exist and
				# 'cp' will generate an error message
				# This is not a fatal error
				cp "${EASYRSA_PKI}/${vars_file_example}" \
					"${EASYRSA_PKI}/${vars_file}" && \
						new_vars_true=1
			fi

			# Use set_var to set vars, do not clobber $vars
			set_var vars "${EASYRSA_PKI}/${vars_file}"
		;;
		vars-setup)
			: ;; # No change to current 'vars' required
		x509-types-only)
			die "install_data_to_pki - unexpected context" ;;
		'')
			die "install_data_to_pki - unspecified context" ;;
		*)
			die "install_data_to_pki - unknown context: $context"
		esac
	fi

	# Check PKI is updated - Omit unnecessary checks
	[ -e "${EASYRSA_PKI}/${ssl_cnf_file}" ] || \
		die "install_data_to_pki - Missing: '$ssl_cnf_file'"
	[ -d "$EASYRSA_EXT_DIR" ] || \
		die "install_data_to_pki - Missing: '$x509_types_dir'"
	verbose "install_data_to_pki: $context COMPLETED"

} # => install_data_to_pki ()

# Disable terminal echo, if possible, otherwise warn
hide_read_pass()
{
	# 3040 - In POSIX sh, set option [name] is undefined
	# 3045 - In POSIX sh, some-command-with-flag is undefined
	# shellcheck disable=SC3040,SC3045
	if stty -echo 2>/dev/null; then
		prompt_restore=1
		read -r "$@"
		stty echo
	elif (set +o echo 2>/dev/null); then
		prompt_restore=2
		set +o echo
		read -r "$@"
		set -o echo
	elif (echo | read -r -s 2>/dev/null) ; then
		read -r -s "$@"
	else
		warn "\
Could not disable echo. Password will be shown on screen!"
		read -r "$@"
	fi
	prompt_restore=0
	return 0
} # => hide_read_pass()

# Get passphrase
get_passphrase() {
	t="$1"; shift || die "password malfunction"
	while :; do
		r=""
		printf '\n%s' "$*"
		hide_read_pass r

		if [ "${#r}" -lt 4 ]; then
			printf '\n%s\n' \
				"Passphrase must be at least 4 characters!"
		else
			force_set_var "$t" "$r" || die "Passphrase error!"
			unset -v r t
			print
			return 0
		fi
	done
} # => get_passphrase()

# build-ca backend:
build_ca() {
	cipher="-aes256"
	unset -v sub_ca ssl_batch date_stamp x509 error_info
	while [ "$1" ]; do
		case "$1" in
			intca|subca) sub_ca=1 ;;
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			raw-ca|raw) EASYRSA_RAW_CA=1 ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# Verify PKI has been initialised
	verify_pki_init

	out_key="$EASYRSA_PKI/private/ca.key"
	# setup for an intermediate CA
	if [ "$sub_ca" ]; then
		# Generate a CSR
		out_file="$EASYRSA_PKI/reqs/ca.req"
	else
		# Generate a certificate
		out_file="$EASYRSA_PKI/ca.crt"
		date_stamp=1
		x509=1
	fi

	# RAW mode must take priority
	if [ "$EASYRSA_RAW_CA" ]; then
		unset -v EASYRSA_NO_PASS EASYRSA_PASSOUT EASYRSA_PASSIN
		verbose "build-ca: CA password RAW method"
	else
		# If encrypted then create the CA key with AES256 cipher
		if [ "$EASYRSA_NO_PASS" ]; then
			unset -v cipher
		else
			unset -v no_password
		fi
	fi

	# Test for existing CA, and complain if already present
	if verify_ca_init test; then
		die "\
Unable to create a CA as you already seem to have one set up.
If you intended to start a new CA, run init-pki first."
	fi

	# If a private key exists, an intermediate ca was created
	# but not signed.
	# Notify user and require a signed ca.crt or a init-pki:
	if [ -f "$out_key" ]; then
		die "\
A CA private key exists but no ca.crt is found in your PKI:
$EASYRSA_PKI
Refusing to create a new CA as this would overwrite your
current CA. To start a new CA, run init-pki first."
	fi

	# Cert type must exist under the EASYRSA_EXT_DIR
	[ -e "$EASYRSA_EXT_DIR/ca" ] || die "\
Missing X509-type 'ca'"
	[ -e "$EASYRSA_EXT_DIR/COMMON" ] || die "\
Missing X509-type 'COMMON'"

	# create necessary dirs:
	err_msg="\
Unable to create necessary PKI files (permissions?)"
	for i in issued inline certs_by_serial \
		revoked/certs_by_serial revoked/private_by_serial \
		revoked/reqs_by_serial
	do
		mkdir -p "$EASYRSA_PKI/$i" || die "$err_msg"
	done

	# create necessary files:
	printf "" > \
		"$EASYRSA_PKI/index.txt" || die "$err_msg"
	printf '%s\n' 'unique_subject = no' \
		> "$EASYRSA_PKI/index.txt.attr" || die "$err_msg"
	printf '%s\n' "01" \
		> "$EASYRSA_PKI/serial" || die "$err_msg"
	unset -v err_msg

	# Set ssl batch mode, as required
	# --req-cn must be used with --batch,
	# otherwise use default
	if [ "$EASYRSA_BATCH" ]; then
		ssl_batch=1
	else
		export EASYRSA_REQ_CN=ChangeMe
	fi

	# Default CA commonName
	if [ "$EASYRSA_REQ_CN" = ChangeMe ]; then
		if [ "$sub_ca" ]; then
			export EASYRSA_REQ_CN="Easy-RSA Sub-CA"
		else
			export EASYRSA_REQ_CN="Easy-RSA CA"
		fi
	fi

	# Check for insert-marker in ssl config file
	if [ "$EASYRSA_EXTRA_EXTS" ]; then
		if ! grep -q '^#%CA_X509_TYPES_EXTRA_EXTS%' \
			"$EASYRSA_SSL_CONF"
		then
			die "\
This openssl config file does \
not support X509-type 'ca'.
* $EASYRSA_SSL_CONF

Please update 'openssl-easyrsa.cnf' \
to the latest Easy-RSA release."
		fi
	fi

	# Assign cert and key temp files
	out_key_tmp=""
	easyrsa_mktemp out_key_tmp || \
		die "build_ca - easyrsa_mktemp out_key_tmp"
	out_file_tmp=""
	easyrsa_mktemp out_file_tmp || \
		die "build_ca - easyrsa_mktemp out_file_tmp"

	# Get passphrase from user if necessary
	if [ "$EASYRSA_RAW_CA" ]
	then
		# Passphrase will be provided
		confirm "
       Accept ?  " yes "\
Raw CA mode
===========

  CA password must be input THREE times:

    1. Set the password.
    2. Confirm the password.
    3. Use the password. (Create the Root CA)"

	elif [ "$EASYRSA_NO_PASS" ]
	then
		: # No passphrase required

	elif [ "$EASYRSA_PASSOUT" ] && [ "$EASYRSA_PASSIN" ]
	then
		: # passphrase defined
		# Both --passout and --passin
		# must be defined for a CA with a password

	else
		# Assign passphrase vars
		# Heed shellcheck SC2154
		p=""
		q=""

		# Get passphrase p
		get_passphrase p \
			"Enter New CA Key Passphrase: "

		# Confirm passphrase q
		get_passphrase q \
			"Confirm New CA Key Passphrase: "

		# Validate passphrase
		if [ "$p" ] && [ "$p" = "$q" ]; then
			# CA password via temp-files
			in_key_pass_tmp=""
			easyrsa_mktemp in_key_pass_tmp || \
				die "build_ca - in_key_pass_tmp"
			out_key_pass_tmp=""
			easyrsa_mktemp out_key_pass_tmp || \
				die "build_ca - out_key_pass_tmp"
			printf "%s" "$p" > "$in_key_pass_tmp" || \
				die "in_key_pass_tmp: write"
			printf "%s" "$p" > "$out_key_pass_tmp" || \
				die "out_key_pass_tmp: write"
			unset -v p q
		else
			unset -v p q
			die "Passphrases do not match!"
		fi
	fi

	# Assign tmp-file for config
	conf_tmp=""
	easyrsa_mktemp conf_tmp || \
		die "build_ca - easyrsa_mktemp conf_tmp"

	# Assign awkscript to insert EASYRSA_EXTRA_EXTS
	# shellcheck disable=SC2016 # vars don't expand in ''
	awkscript='\
{if ( match($0, "^#%CA_X509_TYPES_EXTRA_EXTS%") )
	{ while ( getline<"/dev/stdin" ) {print} next }
 {print}
}'

	# Insert x509-types COMMON and 'ca' and EASYRSA_EXTRA_EXTS
	{
		cat "$EASYRSA_EXT_DIR/ca" "$EASYRSA_EXT_DIR/COMMON"
		[ "$EASYRSA_EXTRA_EXTS" ] && print "$EASYRSA_EXTRA_EXTS"
	} | \
		awk "$awkscript" "$EASYRSA_SSL_CONF" \
		> "$conf_tmp" \
			|| die "Copying X509_TYPES to config file failed"
	# Use this new SSL config for the rest of this function
	EASYRSA_SSL_CONF="$conf_tmp"

	# Generate CA Key
	if [ "$EASYRSA_RAW_CA" ]; then
		case "$EASYRSA_ALGO" in
		rsa)
			if easyrsa_openssl genpkey \
				-algorithm "$EASYRSA_ALGO" \
				-pkeyopt \
					rsa_keygen_bits:"$EASYRSA_ALGO_PARAMS" \
				-out "$out_key_tmp" \
				${cipher:+ "$cipher"}
			then
				: # ok
			else
				die "Failed create CA private key"
			fi
		;;
		ec)
			if easyrsa_openssl genpkey \
				-paramfile "$EASYRSA_ALGO_PARAMS" \
				-out "$out_key_tmp" \
				${cipher:+ "$cipher"}
			then
				: # ok
			else
				die "Failed create CA private key"
			fi
		;;
		ed)
			if easyrsa_openssl genpkey \
				-algorithm "$EASYRSA_CURVE" \
				-out "$out_key_tmp" \
				${cipher:+ "$cipher"}
			then
				: # ok
			else
				die "Failed create CA private key"
			fi
		;;
		*)	die "Unknown algorithm: $EASYRSA_ALGO"
		esac

		verbose "\
build_ca: CA key password created via RAW"

	else
		case "$EASYRSA_ALGO" in
		rsa)
		easyrsa_openssl genpkey \
			-algorithm "$EASYRSA_ALGO" \
			-pkeyopt rsa_keygen_bits:"$EASYRSA_ALGO_PARAMS" \
			-out "$out_key_tmp" \
			${cipher:+ "$cipher"} \
			${EASYRSA_PASSOUT:+ -pass "$EASYRSA_PASSOUT"} \
			${out_key_pass_tmp:+ -pass file:"$out_key_pass_tmp"} \
				|| die "Failed create CA private key"
		;;
		ec)
		easyrsa_openssl genpkey \
			-paramfile "$EASYRSA_ALGO_PARAMS" \
			-out "$out_key_tmp" \
			${cipher:+ "$cipher"} \
			${EASYRSA_PASSOUT:+ -pass "$EASYRSA_PASSOUT"} \
			${out_key_pass_tmp:+ -pass file:"$out_key_pass_tmp"} \
				|| die "Failed create CA private key"
		;;
		ed)
		easyrsa_openssl genpkey \
			-algorithm "$EASYRSA_CURVE" \
			-out "$out_key_tmp" \
			${cipher:+ "$cipher"} \
			${EASYRSA_PASSOUT:+ -pass "$EASYRSA_PASSOUT"} \
			${out_key_pass_tmp:+ -pass file:"$out_key_pass_tmp"} \
				|| die "Failed create CA private key"
		;;
		*)	die "Unknown algorithm: $EASYRSA_ALGO"
		esac
		verbose "\
build_ca: CA key password created via temp-files"
	fi

	# Generate the CA keypair:
	if [ "$EASYRSA_RAW_CA" ]; then
		if easyrsa_openssl req -utf8 -new \
			-key "$out_key_tmp" \
			-out "$out_file_tmp" \
			${x509:+ -x509} \
			${date_stamp:+ -days "$EASYRSA_CA_EXPIRE"} \
			${EASYRSA_DIGEST:+ -"$EASYRSA_DIGEST"}
		then
			: # ok
			unset -v error_info
		else
			die "Failed to build the CA keypair."
		fi

		verbose "\
build_ca: CA certificate password created via RAW"

	else
		easyrsa_openssl req -utf8 -new \
			-key "$out_key_tmp" -keyout "$out_key_tmp" \
			-out "$out_file_tmp" \
			${ssl_batch:+ -batch} \
			${x509:+ -x509} \
			${date_stamp:+ -days "$EASYRSA_CA_EXPIRE"} \
			${EASYRSA_DIGEST:+ -"$EASYRSA_DIGEST"} \
			${EASYRSA_NO_PASS:+ "$no_password"} \
			${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} \
			${in_key_pass_tmp:+ -passin file:"$in_key_pass_tmp"} \
			${out_key_pass_tmp:+ -passout file:"$out_key_pass_tmp"} \
				|| die "Failed to build the CA keypair"
		verbose "\
build_ca: CA certificate password created via temp-files"
	fi

	# Move temp-files to output files
	mv "$out_key_tmp" "$out_key" || {
		die "Failed to move key temp-file"
	}
	mv "$out_file_tmp" "$out_file" || {
		rm -f "$out_key" # Also remove the key
		die  "Failed to move cert temp-file"
	}

	# Success messages
	if [ "$sub_ca" ]; then
		notice "\
Your intermediate CA request is at:
* $out_file
  and now must be sent to your parent CA for signing.

Place your resulting cert at:
* $EASYRSA_PKI/ca.crt
  prior to signing operations."
	else
		notice "\
CA creation complete. Your new CA certificate is at:
* $out_file"
	fi

	return 0
} # => build_ca()

# gen-dh backend:
gen_dh() {
	# Verify PKI has been initialised
	verify_pki_init

	out_file="$EASYRSA_PKI/dh.pem"

	# check to see if we already have a dh parameters file
	if [ -e "$out_file" ]; then
		if [ "$EASYRSA_BATCH" ]; then
			# if batch is enabled, die
			die "\
DH parameters file already exists
at: $out_file"
		else
			# warn the user, allow to force overwrite
			confirm "Overwrite?  " "yes" "\
DH parameters file already exists
at: $out_file"
		fi
	fi

	# Create a temp file
	# otherwise user abort leaves an incomplete dh.pem
	tmp_dh_file=""
	easyrsa_mktemp tmp_dh_file || \
		die "gen_dh - easyrsa_mktemp tmp_dh_file"

	# Generate dh.pem
	"$EASYRSA_OPENSSL" dhparam -out "$tmp_dh_file" \
		"$EASYRSA_KEY_SIZE" || \
			die "Failed to generate DH params"

	# Validate dh.pem
	"$EASYRSA_OPENSSL" dhparam -in "$tmp_dh_file" \
		-check -noout || \
			die "Failed to validate DH params"

	mv -f "$tmp_dh_file" "$out_file" || \
		die "Failed to move temp DH file"

	notice "
DH parameters of size $EASYRSA_KEY_SIZE created at:
* $out_file"

	return 0
} # => gen_dh()

# gen-req and key backend:
gen_req() {
	# Verify PKI has been initialised
	verify_pki_init

	# pull filename, use as default interactive CommonName
	[ "$1" ] || die "\
Error: gen-req must have a file base as the first argument.
Run easyrsa without commands for usage and commands."

	# Initialisation
	unset -v text ssl_batch

	# Set ssl batch mode and Default commonName, as required
	if [ "$EASYRSA_BATCH" ]; then
		ssl_batch=1
		# If EASYRSA_REQ_CN is set to something other than
		# ChangeMe then keep user defined value
		[ "$EASYRSA_REQ_CN" = ChangeMe ] && \
			export EASYRSA_REQ_CN="$1"
	else
		# --req-cn must be used with --batch
		# otherwise use file-name
		export EASYRSA_REQ_CN="$1"
	fi

	# Output files
	key_out="$EASYRSA_PKI/private/$1.key"
	req_out="$EASYRSA_PKI/reqs/$1.req"

	shift # scrape off file-name

	# function opts support
	while [ "$1" ]; do
		case "$1" in
			text) text=1 ;;
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			# batch flag supports internal caller build_full()
			batch) ssl_batch=1 ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# don't wipe out an existing private key without confirmation
	[ -f "$key_out" ] && confirm "Confirm key overwrite: " "yes" "\

WARNING!!!

An existing private key was found at $key_out
Continuing with key generation will replace this key."

	# When EASYRSA_EXTRA_EXTS is defined,
	# append it to openssl's [req] section:
	if [ "$EASYRSA_EXTRA_EXTS" ]; then
		# Check for insert-marker in ssl config file
		if ! grep -q '^#%EXTRA_EXTS%' "$EASYRSA_SSL_CONF"
		then
			die "\
This openssl config file does \
does not support EASYRSA_EXTRA_EXTS.
* $EASYRSA_SSL_CONF

Please update 'openssl-easyrsa.cnf' \
to the latest Easy-RSA release."
		fi

		# Setup & insert the extra ext data keyed by a magic line
		extra_exts="
req_extensions = req_extra
[ req_extra ]
$EASYRSA_EXTRA_EXTS"
		# vars don't expand in single quote
		# shellcheck disable=SC2016
		awkscript='
{if ( match($0, "^#%EXTRA_EXTS%") )
	{ while ( getline<"/dev/stdin" ) {print} next }
 {print}
}'
		# Assign temp-file for confg
		conf_tmp=""
		easyrsa_mktemp conf_tmp || \
			die "gen_req - easyrsa_mktemp conf_tmp"

		print "$extra_exts" | \
			awk "$awkscript" "$EASYRSA_SSL_CONF" \
			> "$conf_tmp" \
			|| die "Writing SSL config to temp file failed"
		# Use this SSL config for the rest of this function
		EASYRSA_SSL_CONF="$conf_tmp"
	fi

	# Name temp files
	key_out_tmp=""
	easyrsa_mktemp key_out_tmp || \
		die "gen_req - easyrsa_mktemp key_out_tmp"
	req_out_tmp=""
	easyrsa_mktemp req_out_tmp || \
		die "gen_req - easyrsa_mktemp req_out_tmp"

	# Set Edwards curve name or elliptic curve parameters file
	algo_opts=""
	if [ "ed" = "$EASYRSA_ALGO" ]; then
		algo_opts="$EASYRSA_CURVE"
	else
		algo_opts="$EASYRSA_ALGO:$EASYRSA_ALGO_PARAMS"
	fi

	# Generate request
	easyrsa_openssl req -utf8 -new -newkey "$algo_opts" \
		-keyout "$key_out_tmp" -out "$req_out_tmp" \
		${EASYRSA_NO_PASS:+ "$no_password"} \
		${text:+ -text} \
		${ssl_batch:+ -batch} \
		${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} \
			|| die "Failed to generate request"

	# Move temp-files to target-files
	mv "$key_out_tmp" "$key_out"
	mv "$req_out_tmp" "$req_out"

	# Success messages
	notice "\
Keypair and certificate request completed. Your files are:
* req: $req_out
* key: $key_out${build_full:+ $NL}"

	return 0
} # => gen_req()

# common signing backend
sign_req() {
	# CA is required to sign
	verify_ca_init

	crt_type="$1"
	req_in="$EASYRSA_PKI/reqs/$2.req"
	crt_out="$EASYRSA_PKI/issued/$2.crt"

	# Check argument sanity:
	[ "$2" ] || die "\
Incorrect number of arguments provided to sign-req:
expected 2, got $# (see command help for usage)"

	# Cert type must exist under the EASYRSA_EXT_DIR
	[ -e "$EASYRSA_EXT_DIR/$crt_type" ] || die "\
Missing X509-type '$crt_type'"
	[ -e "$EASYRSA_EXT_DIR/COMMON" ] || die "\
Missing X509-type 'COMMON'"

	# Cert type must NOT be COMMON
	[ "$crt_type" != COMMON ] || die "\
Invalid certificate type: '$crt_type'"

	# Request file must exist
	[ -e "$req_in" ] || die "\
No request found for the input: '$2'
Expected to find the request at: $req_in"

	# Certificate file must NOT exist
	[ ! -e "$crt_out" ] || die "\
Cannot sign this request for '$2'.
Conflicting certificate already exists at:
* $crt_out"

	# Confirm input is a cert req
	verify_file req "$req_in" || die "\
The certificate request file is not in a valid X509 format:
* $req_in"

	# Randomize Serial number
	if [ "$EASYRSA_RAND_SN" != "no" ]; then
		i=""
		serial=""
		check_serial=""
		unset -v unique_serial
		for i in 1 2 3 4 5; do
			serial="$(
				easyrsa_random 16
				)" || die "sign_req - easyrsa_random"

			# Check for duplicate serial in CA db
			# Always errors out - Do not capture error
			# unset EASYRSA_SILENT_SSL to capure all output
			check_serial="$(
				unset -v EASYRSA_SILENT_SSL
				easyrsa_openssl ca -status "$serial" 2>&1
				)" || :

			case "$check_serial" in
				*"not present in db"*)
					unique_serial=1
					break
				;;
				*)
					verbose "check_serial: $check_serial"
			esac
		done

		# Check for unique_serial
		[ "$unique_serial" ] || die "\
sign_req - Randomize Serial number failed:

$check_serial"

		# Print random $serial to pki/serial file
		# for use by SSL config
		print "$serial" > "$EASYRSA_PKI/serial" || \
			die "sign_req - write serial to file"
	fi

	# When EASYRSA_CP_EXT is defined,
	# adjust openssl's [default_ca] section:
	if [ "$EASYRSA_CP_EXT" ]; then
		# Check for insert-marker in ssl config file
		if ! grep -q '^#%COPY_EXTS%' "$EASYRSA_SSL_CONF"
		then
			die "\
This openssl config file does \
not support option '--copy-ext'.
* $EASYRSA_SSL_CONF

Please update 'openssl-easyrsa.cnf' \
to the latest Easy-RSA release."
		fi

		# Setup & insert the copy_extensions data
		# keyed by a magic line
		copy_exts="copy_extensions = copy"
		# shellcheck disable=SC2016 # vars don't expand ''
		awkscript='
{if ( match($0, "^#%COPY_EXTS%") )
	{ while ( getline<"/dev/stdin" ) {print} next }
 {print}
}'
		# Assign temp-file for confg
		conf_tmp=""
		easyrsa_mktemp conf_tmp || \
			die "sign_req - easyrsa_mktemp conf_tmp"

		print "$copy_exts" | \
			awk "$awkscript" "$EASYRSA_SSL_CONF" \
			> "$conf_tmp" \
			|| die "Writing SSL config to temp file failed"
		# Use this SSL config for the rest of this function
		EASYRSA_SSL_CONF="$conf_tmp"
	fi

	# Generate the extensions file for this cert:
	ext_tmp=""
	easyrsa_mktemp ext_tmp || \
		die "sign_req - easyrsa_mktemp ext_tmp"
	{
		# Append COMMON and cert-type extensions
		cat "$EASYRSA_EXT_DIR/COMMON" || \
			die "Failed to read X509-type COMMON"
		cat "$EASYRSA_EXT_DIR/$crt_type" || \
			die "Failed to read X509-type $crt_type"

		# Support a dynamic CA path length when present:
		if [ "$crt_type" = "ca" ] && [ "$EASYRSA_SUBCA_LEN" ]
		then
			# Print the last occurence of basicContraints in
			# x509-types/ca
			# If basicContraints is not defined then bail
			# shellcheck disable=SC2016 # vars don't expand ''
			awkscript='\
/^[[:blank:]]*basicConstraints[[:blank:]]*=/ { bC=$0 }
END { if (length(bC) == 0 ) exit 1; print bC }'
			basicConstraints="$(
				awk "$awkscript" "$EASYRSA_EXT_DIR/$crt_type"
				)" || die "\
basicConstraints is not defined, cannot use 'pathlen'"
			print "$basicConstraints, pathlen:$EASYRSA_SUBCA_LEN"
			unset -v basicConstraints
		fi

		# Deprecated Netscape extension support
		case "$EASYRSA_NS_SUPPORT" in
			[yY][eE][sS])

			# Netscape extension
			case "$crt_type" in
				serverClient)
					print "nsCertType = serverClient" ;;
				server)
					print "nsCertType = server" ;;
				client)
					print "nsCertType = client" ;;
				ca)
					print "nsCertType = sslCA" ;;
				*)
					die "Unknown certificate type: $crt_type"
			esac

			# Netscape comment
			[ "$EASYRSA_NS_COMMENT" ] && \
				print "nsComment = \"$EASYRSA_NS_COMMENT\""
		;;
		*)
			: # ok No NS support required
		esac

		# Add user SAN from --subject-alt-name
		if [ "$user_san_true" ]; then
			print "$EASYRSA_EXTRA_EXTS"
		else
			# or default server SAN
			# If type is server and no subjectAltName was
			# requested then add one to the extensions file
			if [ "$crt_type" = 'server' ] || \
				[ "$crt_type" = 'serverClient' ];
			then
				# req san or default server SAN
				san="$(display_san req "$req_in")"
				if [ "$san" ]; then
					print "subjectAltName = $san"
				else
					default_server_san "$req_in"
				fi
			fi

			# Add user set EASYRSA_EXTRA_EXTS
			[ -z "$EASYRSA_EXTRA_EXTS" ] || \
				print "$EASYRSA_EXTRA_EXTS"
		fi
	} > "$ext_tmp" || die "\
Failed to create temp extension file (bad permissions?) at:
* $ext_tmp"

	# Set valid_period message
	if [ "$EASYRSA_END_DATE" ]; then
		valid_period="
until date '$EASYRSA_END_DATE'"
	else
		valid_period="
for '$EASYRSA_CERT_EXPIRE' days"
	fi

	# Display the request subject in an easy-to-read format
	# Confirm the user wishes to sign this request
	# Support batch by internal caller:
	confirm "Confirm request details: " "yes" "\
You are about to sign the following certificate.
Please check over the details shown below for accuracy. \
Note that this request
has not been cryptographically verified. Please be sure \
it came from a trusted
source or that you have verified the request checksum \
with the sender.

Request subject, to be signed as a $crt_type certificate \
${valid_period}:

$(display_dn req "$req_in")
"	# => confirm end

	# Confirm deprecated use of NS extensions
	case "$EASYRSA_NS_SUPPORT" in
		[yY][eE][sS])
		confirm "Confirm use of Netscape extensions: " yes \
		"WARNING: Netscape extensions are DEPRECATED!"
	;;
	*) : #ok
	esac

	# Assign temp cert file
	crt_out_tmp=""
	easyrsa_mktemp crt_out_tmp || \
		die "sign_req - easyrsa_mktemp crt_out_tmp"

	# sign request
	easyrsa_openssl ca -utf8 -batch \
		-in "$req_in" -out "$crt_out_tmp" \
		-extfile "$ext_tmp" \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
		${EASYRSA_NO_TEXT:+ -notext} \
		${EASYRSA_CERT_EXPIRE:+ -days "$EASYRSA_CERT_EXPIRE"} \
		${EASYRSA_START_DATE:+ -startdate "$EASYRSA_START_DATE"} \
		${EASYRSA_END_DATE:+ -enddate "$EASYRSA_END_DATE"} \
			|| die "\
Signing failed (openssl output above may have more detail)"

	mv "$crt_out_tmp" "$crt_out" || \
		die "Failed to move temp-file to certificate."

	# Success messages
	notice "\
Certificate created at:
* $crt_out"

	return 0
} # => sign_req()

# common build backend
# used to generate+sign in 1 step
build_full() {
	# pull filename base:
	[ "$2" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and commands."

	crt_type="$1"
	name="$2"
	shift 2

	req_out="$EASYRSA_PKI/reqs/$name.req"
	key_out="$EASYRSA_PKI/private/$name.key"
	crt_out="$EASYRSA_PKI/issued/$name.crt"

	# function opts support
	while [ "$1" ]; do
		case "$1" in
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# abort on existing req/key/crt files
	err_exists="\
file already exists. Aborting build to avoid overwriting this file.
If you wish to continue, please use a different name.
Matching file found at: "
	[ -e "$req_out" ] && die "Request $err_exists $req_out"
	[ -e "$key_out" ] && die "Key $err_exists $key_out"
	[ -e "$crt_out" ] && die "Certificate $err_exists $crt_out"
	unset -v err_exists

	# Make inline directory
	[ -d "$EASYRSA_PKI/inline" ] ||	\
		mkdir -p "$EASYRSA_PKI/inline" || \
			die "Failed to create inline directoy."

	# Confirm over write inline file
	inline_out="$EASYRSA_PKI/inline/$name.inline"
	[ -e "$inline_out" ] && \
		confirm "Confirm OVER-WRITE existing inline file ? " y "\
Warning!

An inline file for name '$name' already exists:
* $inline_out"

	# Set commonName
	[ "$EASYRSA_REQ_CN" = ChangeMe ] || die "\
Option conflict:
* '$cmd' does not support setting an external commonName"
	EASYRSA_REQ_CN="$name"

	# create request
	build_full=1
	gen_req "$name" batch

	# Sign it
	error_build_full_cleanup=1
	if sign_req "$crt_type" "$name"; then
		unset -v error_build_full_cleanup
	else
		die "\
Failed to sign '$name' - \
See error messages above for details."
	fi

	# inline it
	if inline_creds "$name" > "$inline_out"; then
		notice "\
Inline file created:
* $inline_out"
	else
		warn "\
Failed to write inline file:
* $inline_out"
	fi

	return 0
} # => build_full()

# Create inline credentials file for this node
inline_creds ()
{
	[ "$1" ] || die "inline_creds - Name missing"
	printf "%s\n\n" "# $crt_type: $1"
	printf "%s\n" "<cert>"
	cat "$crt_out"
	printf "%s\n\n" "</cert>"
	printf "%s\n" "<key>"
	[ -e "$key_out" ] && cat "$key_out"
	printf "%s\n\n" "</key>"
	printf "%s\n" "<ca>"
	cat "$EASYRSA_PKI/ca.crt"
	printf "%s\n\n" "</ca>"
} # => inline_creds ()

# revoke backend
revoke() {
	# pull filename base:
	[ "$1" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift

	in_dir="$EASYRSA_PKI"
	crt_in="$in_dir/issued/$file_name_base.crt"
	key_in="$in_dir/private/$file_name_base.key"
	req_in="$in_dir/reqs/$file_name_base.req"
	creds_in="$in_dir/$file_name_base.creds"
	inline_in="$in_dir/inline/$file_name_base.inline"

	# Assign possible "crl_reason"
	if [ "$1" ]; then
		crl_reason="$1"
		shift

		case "$crl_reason" in
			unspecified) : ;;
			keyCompromise) : ;;
			CACompromise) : ;;
			affiliationChanged) : ;;
			superseded) : ;;
			cessationOfOperation) : ;;
			certificateHold) : ;;
			*) die "Illegal reason: $crl_reason"
		esac
	else
		unset -v crl_reason
	fi

	# Enforce syntax
	if [ "$1" ]; then
		die "Syntax error: $1"
	fi

	# referenced cert must exist:
	[ -e "$crt_in" ] || die "\
Unable to revoke as no certificate was found. Certificate was expected
at: $crt_in"

	# Verify certificate
	verify_file x509 "$crt_in" || die "\
Unable to revoke as the input file is not a valid certificate. Unexpected
input in file: $crt_in"

	# Verify request
	if [ -e "$req_in" ]; then
		verify_file req "$req_in" || die "\
Unable to verify request. The file is not a valid request.
Unexpected input in file: $req_in"
	fi

	# get the serial number of the certificate
	ssl_cert_serial "$crt_in" cert_serial

	duplicate_crt_by_serial="$EASYRSA_PKI/certs_by_serial/$cert_serial.pem"

	# Set out_dir
	out_dir="$EASYRSA_PKI/revoked"
	crt_out="$out_dir/certs_by_serial/$cert_serial.crt"
	key_out="$out_dir/private_by_serial/$cert_serial.key"
	req_out="$out_dir/reqs_by_serial/$cert_serial.req"

	# NEVER over-write a revoked cert, serial number must be unique
	deny_msg="\
Cannot revoke this certificate because a conflicting file exists.
*"
	[ -e "$crt_out" ] && die "$deny_msg certificate: $crt_out"
	[ -e "$key_out" ] && die "$deny_msg private key: $key_out"
	[ -e "$req_out" ] && die "$deny_msg request    : $req_out"
	unset -v deny_msg

	# Check for key and request files
	unset -v if_exist_key_in if_exist_req_in
	[ -e "$key_in" ] && if_exist_key_in="
* $key_in"
	[ -e "$req_in" ] && if_exist_req_in="
* $req_in"

	# confirm operation by displaying DN:
	warn "\
This process is destructive!

These files will be MOVED to the 'revoked' storage directory:
* $crt_in${if_exist_key_in}${if_exist_req_in}

These files will be DELETED:
All PKCS files for commonName : $file_name_base

The inline credentials files:
* $creds_in
* $inline_in

The duplicate certificate:
* $duplicate_crt_by_serial"

	confirm "  Continue with revocation: " "yes" "\
Please confirm you wish to revoke the certificate
with the following subject:

  $(display_dn x509 "$crt_in")

  serial-number: $cert_serial

  Reason: ${crl_reason:-None given}"

	# Revoke certificate
	easyrsa_openssl ca -utf8 -revoke "$crt_in" \
		${crl_reason:+ -crl_reason "$crl_reason"} \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			|| die "\
Failed to revoke certificate: revocation command failed."

	# move revoked files
	# so we can reissue certificates with the same name
	revoke_move

	notice "\
                              * IMPORTANT *

Revocation was successful. You must run 'gen-crl' and upload a new CRL to your
infrastructure in order to prevent the revoked certificate from being accepted."

	return 0
} # => revoke()

# revoke_move
# moves revoked certificates to the 'revoked' folder
# allows reissuing certificates with the same name
revoke_move() {
	for target in "$out_dir" \
		"$out_dir/certs_by_serial" \
		"$out_dir/private_by_serial" \
		"$out_dir/reqs_by_serial"
	do
		[ -d "$target" ] && continue
		mkdir -p "$target" ||
			die "Failed to mkdir: $target"
	done

	# move crt, key and req file to renewed_then_revoked folders
	mv "$crt_in" "$crt_out" || die "Failed to move: $crt_in"

	# only move the key if we have it
	if [ -e "$key_in" ]; then
		mv "$key_in" "$key_out" || warn "Failed to move: $key_in"
	fi

	# only move the req if we have it
	if [ -e "$req_in" ]; then
		mv "$req_in" "$req_out" || warn "Failed to move: $req_in"
	fi

	# remove any pkcs files
	for pkcs in p12 p7b p8 p1; do
		if [ -e "$in_dir/issued/$file_name_base.$pkcs" ]; then
			# issued
			rm "$in_dir/issued/$file_name_base.$pkcs" ||
				warn "Failed to remove: $file_name_base.$pkcs"

		elif [ -e "$in_dir/private/$file_name_base.$pkcs" ]; then
			# private
			rm "$in_dir/private/$file_name_base.$pkcs" ||
				warn "Failed to remove: $file_name_base.$pkcs"
		else
			: # ok
		fi
	done

	# remove the duplicate certificate
	if [ -e "$duplicate_crt_by_serial" ]; then
		rm "$duplicate_crt_by_serial" || warn "\
Failed to remove the duplicate certificate:
* $duplicate_crt_by_serial"
	fi

	# remove credentials file
	if [ -e "$creds_in" ]; then
		rm "$creds_in" || warn "\
Failed to remove credentials file:
* $creds_in"
	fi

	# remove inline file
	if [ -e "$inline_in" ]; then
		rm "$inline_in" || warn "\
Failed to remove inline file:
* $inline_in"
	fi

	return 0
} # => revoke_move()

# renew backend
renew() {
	# pull filename base:
	[ "$1" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift

	# Assign input files
	in_dir="$EASYRSA_PKI"
	crt_in="$in_dir/issued/$file_name_base.crt"
	key_in="$in_dir/private/$file_name_base.key"
	# key_out is used by inline_creds()
	key_out="$in_dir/private/$file_name_base.key"
	req_in="$in_dir/reqs/$file_name_base.req"
	creds_in="$in_dir/$file_name_base.creds"
	inline_in="$in_dir/inline/$file_name_base.inline"

	# Upgrade CA index.txt.attr - unique_subject = no
	up23_upgrade_ca || \
		die "Failed to upgrade CA to support renewal."

	# deprecate ALL options
	while [ "$1" ]; do
		case "$1" in
			nopass)
				warn "\
Option 'nopass' is not supported by command 'renew'."
			;;
			*) die "Unknown option: $1"
		esac
		shift
	done

	# Verify certificate
	if [ -f "$crt_in" ]; then
		verify_file x509 "$crt_in" || die "\
Input file is not a valid certificate:
* $crt_in"
	else
		die "\
Missing certificate file:
* $crt_in"
	fi

	# Verify request
	if [ -e "$req_in" ]; then
		verify_file req "$req_in" || die "\
Input file is not a valid request:
* $req_in"
	else
		die "\
Missing request file:
* $req_in"
	fi

	# get the serial number of the certificate
	ssl_cert_serial "$crt_in" cert_serial

	duplicate_crt_by_serial="\
$EASYRSA_PKI/certs_by_serial/$cert_serial.pem"

	# Set out_dir
	out_dir="$EASYRSA_PKI/renewed"
	crt_out="$out_dir/issued/$file_name_base.crt"

	# NEVER over-write a renewed cert, revoke it first
	deny_msg="\
Cannot renew this certificate, a conflicting file exists:
*"
	[ -e "$crt_out" ] && die "$deny_msg certificate: $crt_out"
	unset -v deny_msg

	# Make inline directory
	[ -d "$EASYRSA_PKI/inline" ] ||	\
		mkdir -p "$EASYRSA_PKI/inline" || \
			die "Failed to create inline directoy."

	# Extract certificate usage from old cert
	cert_ext_key_usage="$(
		easyrsa_openssl x509 -in "$crt_in" -noout -text |
		sed -n "/X509v3 Extended Key Usage:/{n;s/^ *//g;p;}"
		)"

	case "$cert_ext_key_usage" in
		"TLS Web Client Authentication")
			cert_type=client
		;;
		"TLS Web Server Authentication")
			cert_type=server
		;;
	"TLS Web Server Authentication, TLS Web Client Authentication")
			cert_type=serverClient
		;;
		*) die "Unknown key usage: $cert_ext_key_usage"
	esac

	# Use SAN from --san if set else use SAN from old cert
	if echo "$EASYRSA_EXTRA_EXTS" | grep -q subjectAltName; then
		: # ok - Use current subjectAltName
	else
		san="$(
easyrsa_openssl x509 -in "$crt_in" -noout -text | sed -n \
"/X509v3 Subject Alternative Name:\
/{n;s/IP Address:/IP:/g;s/ //g;p;}"
		)" || die "renew - san: easyrsa_openssl subshell"

		[ "$san" ] && export EASYRSA_EXTRA_EXTS="\
$EASYRSA_EXTRA_EXTS
subjectAltName = $san"
	fi

	# confirm operation by displaying DN:
	warn "\
This process is destructive!

These files will be MOVED to 'renewed' storage directory:
* $crt_in

These files will be DELETED:
All PKCS files for commonName: $file_name_base

The inline credentials files:
* $creds_in
* $inline_in

The duplicate certificate:
* $duplicate_crt_by_serial"

	confirm "  Continue with renewal: " "yes" "\
Please confirm you wish to renew the certificate
with the following subject:

  $(display_dn x509 "$crt_in")

  serial-number: $cert_serial"

	# move renewed files
	# so we can reissue certificate with the same name
	renew_move
	error_undo_renew_move=1

	# renew certificate
	if EASYRSA_BATCH=1 sign_req "$cert_type" "$file_name_base"
	then
		unset -v error_undo_renew_move
	else
		# If renew failed then restore cert.
		# Otherwise, issue a warning
		renew_restore_move
		die "\
Renewal has failed to build a new certificate."
	fi

	# inline it
	# Over write existing because renew is successful
	if inline_creds "$file_name_base" > "$inline_in"; then
		notice "\
Inline file created:
* $inline_in"
	else
		warn "\
Failed to write inline file:
* $inline_in"
	fi

	# Success messages
	notice "\
Renew was successful.

                              * IMPORTANT *

Renew has created a new certificate, to replace the old certificate.

To revoke the old certificate, once the new one has been deployed,
use: 'revoke-renewed $file_name_base reason' ('reason' is optional)"

	return 0
} # => renew()

# Restore files on failure to renew
renew_restore_move() {
	unset -v rrm_err error_undo_renew_move
	# restore crt file to PKI folders
	if mv "$restore_crt_out" "$restore_crt_in"; then
		: # ok
	else
		warn "Failed to restore: $restore_crt_out"
		rrm_err=1
	fi

	# messages
	if [ "$rrm_err" ]; then
		warn "Failed to restore renewed files."
	else
		notice "\
Renew FAILED but files have been successfully restored."
	fi

	return 0
} # => renew_restore_move()

# renew_move
# moves renewed certificates to the 'renewed' folder
# allows reissuing certificates with the same name
renew_move() {
	# make sure renewed dirs exist
	for target in "$out_dir" \
		"$out_dir/issued" \
		"$out_dir/private" \
		"$out_dir/reqs"
	do
		[ -d "$target" ] && continue
		mkdir -p "$target" ||
			die "Failed to mkdir: $target"
	done

	# move crt, key and req file to renewed folders
	# After this point, renew is possible!
	restore_crt_in="$crt_in"
	restore_crt_out="$crt_out"
	mv "$crt_in" "$crt_out" || \
		die "Failed to move: $crt_in"

	# Further file removal is a convenience, only.
	# remove any pkcs files
	for pkcs in p12 p7b p8 p1; do
		# issued
		rm -f "$in_dir/issued/$file_name_base.$pkcs"
		# private
		rm -f "$in_dir/private/$file_name_base.$pkcs"
	done

	# remove the duplicate certificate
	if [ -e "$duplicate_crt_by_serial" ]; then
		rm "$duplicate_crt_by_serial" || warn "\
Failed to remove the duplicate certificate:
* $duplicate_crt_by_serial"
	fi

	# remove credentials file
	if [ -e "$creds_in" ]; then
		rm "$creds_in" || warn "\
Failed to remove credentials file:
* $creds_in"
	fi

	# remove inline file
	if [ -e "$inline_in" ]; then
		rm "$inline_in" || warn "\
Failed to remove inline file:
* $inline_in"
	fi

	return 0
} # => renew_move()

# revoke-renewed backend
revoke_renewed() {
	# pull filename base:
	[ "$1" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift

	in_dir="$EASYRSA_PKI/renewed"
	crt_in="$in_dir/issued/$file_name_base.crt"
	key_in="$in_dir/private/$file_name_base.key"
	req_in="$in_dir/reqs/$file_name_base.req"
	#creds_in="$EASYRSA_PKI/$file_name_base.creds"

	# Assign possible "crl_reason"
	if [ "$1" ]; then
		crl_reason="$1"
		shift

		case "$crl_reason" in
			unspecified) : ;;
			keyCompromise) : ;;
			CACompromise) : ;;
			affiliationChanged) : ;;
			superseded) : ;;
			cessationOfOperation) : ;;
			certificateHold) : ;;
			*) die "Illegal reason: $crl_reason"
		esac
	else
		unset -v crl_reason
	fi

	# Enforce syntax
	if [ "$1" ]; then
		die "Syntax error: $1"
	fi

	# referenced cert must exist:
	[ -f "$crt_in" ] || die "\
Unable to revoke as no renewed certificate was found.
Certificate was expected at: $crt_in"

	# Verify certificate
	verify_file x509 "$crt_in" || die "\
Unable to revoke as the input file is not a valid certificate. Unexpected
input in file: $crt_in"

	# Verify request
	if [ -e "$req_in" ]; then
		verify_file req "$req_in" || die "\
Unable to verify request. The file is not a valid request.
Unexpected input in file: $req_in"
	fi

	# get the serial number of the certificate
	ssl_cert_serial "$crt_in" cert_serial

	duplicate_crt_by_serial="$EASYRSA_PKI/certs_by_serial/$cert_serial.pem"

	# output
	out_dir="$EASYRSA_PKI/revoked"
	crt_out="$out_dir/certs_by_serial/$cert_serial.crt"
	key_out="$out_dir/private_by_serial/$cert_serial.key"
	req_out="$out_dir/reqs_by_serial/$cert_serial.req"

	# NEVER over-write a revoked cert, serial number must be unique
	deny_msg="\
Cannot revoke this certificate because a conflicting file exists.
*"
	[ -e "$crt_out" ] && die "$deny_msg certificate: $crt_out"
	[ -e "$key_out" ] && die "$deny_msg private key: $key_out"
	[ -e "$req_out" ] && die "$deny_msg request    : $req_out"
	unset -v deny_msg

	# confirm operation by displaying DN:
	unset -v if_exist_key_in if_exist_req_in
	[ -e "$key_in" ] && if_exist_key_in="
* $key_in"
	[ -e "$req_in" ] && if_exist_req_in="
* $req_in"
	warn "\
This process is destructive!

These files will be moved to the 'revoked' storage sub-directory:
* $crt_in${if_exist_key_in}${if_exist_req_in}"

	confirm "  Continue with revocation: " "yes" "\
  Please confirm you wish to revoke the renewed certificate
  with the following subject:

  $(display_dn x509 "$crt_in")

  serial-number: $cert_serial

  Reason: ${crl_reason:-None given}"

	# Revoke the old (already renewed) certificate
	easyrsa_openssl ca -utf8 -revoke "$crt_in" \
		${crl_reason:+ -crl_reason "$crl_reason"} \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			|| die "Failed to revoke renewed certificate: revocation command failed."

	# move revoked files
	revoke_renewed_move

	notice "                              * IMPORTANT *

Revocation was successful. You must run 'gen-crl' and upload a new CRL to your
infrastructure in order to prevent the revoked certificate from being accepted."

	return 0
} # => revoke_renewed()

# move-renewed-revoked
# moves renewed then revoked certificates to the 'revoked' folder
revoke_renewed_move() {
	# make sure revoked dirs exist
	for target in "$out_dir" \
		"$out_dir/certs_by_serial" \
		"$out_dir/private_by_serial" \
		"$out_dir/reqs_by_serial"
	do
		[ -d "$target" ] && continue
		mkdir -p "$target" ||
			die "Failed to mkdir: $target"
	done

	# move crt, key and req file to renewed_then_revoked folders
	mv "$crt_in" "$crt_out" || die "Failed to move: $crt_in"

	# only move the key if we have it
	if [ -e "$key_in" ]; then
		mv "$key_in" "$key_out" || warn "Failed to move: $key_in"
	fi

	# only move the req if we have it
	if [ -e "$req_in" ]; then
		mv "$req_in" "$req_out" || warn "Failed to move: $req_in"
	fi

	return 0
} # => revoke_renewed_move()

# Move renewed certs_by_serial to the new renew layout
rewind_renew() {
	# pull filename base: serial number
	[ "$1" ] || die "\
Error: didn't find a serial number as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift "$#" # No options supported

	cert_serial="$file_name_base"
	in_dir="$EASYRSA_PKI/renewed"
	crt_in="$in_dir/certs_by_serial/$file_name_base.crt"
	key_in="$in_dir/private_by_serial/$file_name_base.key"
	req_in="$in_dir/reqs_by_serial/$file_name_base.req"

	# referenced cert must exist:
	[ -f "$crt_in" ] || die "\
Unable to rewind as no certificate was found. Certificate was expected
at: $crt_in"

	# Verify certificate
	verify_file x509 "$crt_in" || die "\
Unable to rewind as the input file is not a valid certificate. Unexpected
input in file: $crt_in"

	# Verify request
	if [ -e "$req_in" ]; then
		verify_file req "$req_in" || die "\
Unable to verify request. The file is not a valid request.
Unexpected input in file: $req_in"
	fi

	# get the commonName of the certificate via DN
	crt_cn="$(
		easyrsa_openssl x509 -in "$crt_in" -noout -subject -nameopt \
		utf8,multiline | grep '^[[:blank:]]*commonName[[:blank:]]*= '
		)" || die "Failed to find commonName in certificate"
	crt_cn="${crt_cn#*= }"

	# Set out_dir
	out_dir="$EASYRSA_PKI/renewed"
	crt_out="$out_dir/issued/$crt_cn.crt"
	key_out="$out_dir/private/$crt_cn.key"
	req_out="$out_dir/reqs/$crt_cn.req"

	# Create out_dir
	for newdir in issued private reqs; do
		mkdir -p "$out_dir/$newdir" || die "Failed to create: $out_dir/$newdir"
	done

	# NEVER over-write a renewed cert, revoke it first
	deny_msg="\
Cannot rewind this certificate because a conflicting file exists.
*"
	[ -e "$crt_out" ] && die "$deny_msg certificate: $crt_out"
	[ -e "$key_out" ] && die "$deny_msg private key: $key_out"
	[ -e "$req_out" ] && die "$deny_msg request    : $req_out"
	unset -v deny_msg

	warn "\
This process is destructive!

These files will be moved to the NEW 'renewed' storage sub-directory:
* $crt_in
* $key_in
* $req_in"

	confirm "  Continue with rewind-renew: " "yes" "\
Please confirm you wish to rewind-renew the certificate
with the following subject:

  $(display_dn x509 "$crt_in")

  serial-number: $cert_serial
"	# => confirm end

	# move crt, key and req file to renewed folders
	mv "$crt_in" "$crt_out" || die "Failed to move: $crt_in"

	# only move the key if we have it
	if [ -e "$key_in" ]; then
		if mv "$key_in" "$key_out"; then
			: # ok
		else
			# Attempt restore
			mv -f "$crt_out" "$crt_in"
			die "Failed to move: $key_in"
		fi
	fi

	# only move the req if we have it
	if [ -e "$req_in" ]; then
		if mv "$req_in" "$req_out"; then
			: # ok
		else
			# Attempt restore
			mv -f "$crt_out" "$crt_in"
			mv -f "$key_out" "$key_in"
			die "Failed to move: $req_in"
		fi
	fi

	# Success message
	notice "\
Rewind is successful.

Common Name  : $crt_cn
Serial number: $cert_serial

To revoke use: 'revoke-renewed $crt_cn'"
} # => rewind_renew()

# rebuild backend
rebuild() {
	# pull filename base:
	[ "$1" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift

	in_dir="$EASYRSA_PKI"
	crt_in="$in_dir/issued/$file_name_base.crt"
	key_in="$in_dir/private/$file_name_base.key"
	req_in="$in_dir/reqs/$file_name_base.req"
	creds_in="$in_dir/$file_name_base.creds"
	inline_in="$in_dir/inline/$file_name_base.inline"

	# Upgrade CA index.txt.attr - unique_subject = no
	up23_upgrade_ca || die "Failed to upgrade CA to support renewal."

	# Set 'nopass'
	while [ "$1" ]; do
		case "$1" in
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			*) die "Unknown option: $1"
		esac
		shift
	done

	# referenced cert must exist:
	[ -f "$crt_in" ] || die "\
Unable to rebuild as no certificate was found. Certificate was expected
at: $crt_in"

	# Verify certificate
	verify_file x509 "$crt_in" || die "\
Unable to rebuild as the input file is not a valid certificate. Unexpected
input in file: $crt_in"

	# Verify request
	if [ -e "$req_in" ]; then
		verify_file req "$req_in" || die "\
Unable to verify request. The file is not a valid request.
Unexpected input in file: $req_in"
	fi

	# get the serial number of the certificate
	ssl_cert_serial "$crt_in" cert_serial

	duplicate_crt_by_serial="$EASYRSA_PKI/certs_by_serial/$cert_serial.pem"

	# Set out_dir
	out_dir="$EASYRSA_PKI/renewed"
	crt_out="$out_dir/issued/$file_name_base.crt"
	key_out="$out_dir/private/$file_name_base.key"
	req_out="$out_dir/reqs/$file_name_base.req"

	# NEVER over-write a renewed cert, revoke it first
	deny_msg="\
Cannot rebuild this certificate because a conflicting file exists.
*"
	[ -e "$crt_out" ] && die "$deny_msg certificate: $crt_out"
	[ -e "$key_out" ] && die "$deny_msg private key: $key_out"
	[ -e "$req_out" ] && die "$deny_msg request    : $req_out"
	unset -v deny_msg

	#	# Check if old cert is expired or expires within 30
	#	cert_dates "$crt_in"
	#
	#	[ "$expire_date_s" -lt "$allow_renew_date_s" ] || die "\
	#Certificate expires in more than $EASYRSA_PRE_EXPIRY_WINDOW days.
	#Renewal not allowed."

	# Extract certificate usage from old cert
	cert_ext_key_usage="$(
		easyrsa_openssl x509 -in "$crt_in" -noout -text |
		sed -n "/X509v3 Extended Key Usage:/{n;s/^ *//g;p;}"
		)"

	case "$cert_ext_key_usage" in
		"TLS Web Client Authentication")
			cert_type=client
			;;
		"TLS Web Server Authentication")
			cert_type=server
			;;
		"TLS Web Server Authentication, TLS Web Client Authentication")
			cert_type=serverClient
			;;
		*) die "Unknown key usage: $cert_ext_key_usage"
	esac

	# Use SAN from --subject-alt-name if set else use SAN from old cert
	if echo "$EASYRSA_EXTRA_EXTS" | grep -q subjectAltName; then
		: # ok - Use current subjectAltName
	else
		san="$(
		easyrsa_openssl x509 -in "$crt_in" -noout -text | sed -n \
		"/X509v3 Subject Alternative Name:/{n;s/IP Address:/IP:/g;s/ //g;p;}"
			)"

		[ "$san" ] && export EASYRSA_EXTRA_EXTS="\
$EASYRSA_EXTRA_EXTS
subjectAltName = $san"
	fi

	# confirm operation by displaying DN:
	unset -v if_exist_key_in if_exist_req_in
	[ -e "$key_in" ] && if_exist_key_in="
* $key_in"
	[ -e "$req_in" ] && if_exist_req_in="
* $req_in"
	warn "\
This process is destructive!

These files will be moved to the 'renewed' storage directory:
* $crt_in${if_exist_key_in}${if_exist_req_in}

These files will be DELETED:
All PKCS files for commonName : $file_name_base

The inline credentials files:
* $creds_in
* $inline_in

The duplicate certificate:
* $duplicate_crt_by_serial

IMPORTANT: The new key will${EASYRSA_NO_PASS:+ NOT} be password protected."

	confirm "  Continue with rebuild: " "yes" "\
Please confirm you wish to renew the certificate
with the following subject:

  $(display_dn x509 "$crt_in")

  serial-number: $cert_serial"

	# move renewed files so we can reissue certificate with the same name
	rebuild_move
	error_undo_rebuild_move=1

	# rebuild certificate
	if EASYRSA_BATCH=1 build_full "$cert_type" "$file_name_base"; then
		unset -v error_undo_rebuild_move
	else
		# If rebuild failed then restore cert, key and req. Otherwise,
		# issue a warning. If *restore* fails then at least the file-names
		# are not serial-numbers
		rebuild_restore_move
		die "\
Rebuild has failed to build a new certificate/key pair."
	fi

	# Success messages
	notice "Rebuild was successful.

                              * IMPORTANT *

Rebuild has created a new certificate and key, to replace both old files.

To revoke the old certificate, once the new one has been deployed,
use: 'revoke-renewed $file_name_base reason' ('reason' is optional)"

	return 0
} # => rebuild()

# Restore files on failure to rebuild
rebuild_restore_move() {
	unset -v rrm_err error_undo_renew_move
	# restore crt, key and req file to PKI folders
	if mv "$restore_crt_out" "$restore_crt_in"; then
		: # ok
	else
		warn "Failed to restore: $restore_crt_out"
		rrm_err=1
	fi

	# only restore the key if we have it
	if [ -e "$restore_key_out" ]; then
		if mv "$restore_key_out" "$restore_key_in"; then
			: # ok
		else
			warn "Failed to restore: $restore_key_out"
			rrm_err=1
		fi
	fi

	# only restore the req if we have it
	if [ -e "$restore_req_out" ]; then
		if mv "$restore_req_out" "$restore_req_in"; then
			: # ok
		else
			warn "Failed to restore: $restore_req_out"
			rrm_err=1
		fi
	fi

	# messages
	if [ "$rrm_err" ]; then
		warn "Failed to restore renewed files."
	else
		notice "Rebuild FAILED but files have been successfully restored."
	fi

	return 0
} # => rebuild_restore_move()

# rebuild_move
# moves renewed certificates to the 'renewed' folder
# allows reissuing certificates with the same name
rebuild_move() {
	# make sure renewed dirs exist
	for target in "$out_dir" \
		"$out_dir/issued" \
		"$out_dir/private" \
		"$out_dir/reqs"
	do
		[ -d "$target" ] && continue
		mkdir -p "$target" ||
			die "Failed to mkdir: $target"
	done

	# move crt, key and req file to renewed folders
	restore_crt_in="$crt_in"
	restore_crt_out="$crt_out"
	mv "$crt_in" "$crt_out" || die "Failed to move: $crt_in"

	# only move the key if we have it
	restore_key_in="$key_in"
	restore_key_out="$key_out"
	if [ -e "$key_in" ]; then
		mv "$key_in" "$key_out" || warn "Failed to move: $key_in"
	fi

	# only move the req if we have it
	restore_req_in="$req_in"
	restore_req_out="$req_out"
	if [ -e "$req_in" ]; then
		mv "$req_in" "$req_out" || warn "Failed to move: $req_in"
	fi

	# remove any pkcs files
	for pkcs in p12 p7b p8 p1; do
		if [ -e "$in_dir/issued/$file_name_base.$pkcs" ]; then
			# issued
			rm "$in_dir/issued/$file_name_base.$pkcs" ||
				warn "Failed to remove: $file_name_base.$pkcs"

		elif [ -e "$in_dir/private/$file_name_base.$pkcs" ]; then
			# private
			rm "$in_dir/private/$file_name_base.$pkcs" ||
				warn "Failed to remove: $file_name_base.$pkcs"
		else
			: # ok
		fi
	done

	# remove the duplicate certificate
	if [ -e "$duplicate_crt_by_serial" ]; then
		rm "$duplicate_crt_by_serial" || warn "\
Failed to remove the duplicate certificate:
* $duplicate_crt_by_serial"
	fi

	# remove credentials file
	if [ -e "$creds_in" ]; then
		rm "$creds_in" || warn "\
Failed to remove credentials file:
* $creds_in"
	fi

	# remove inline file
	if [ -e "$inline_in" ]; then
		rm "$inline_in" || warn "\
Failed to remove inline file:
* $inline_in"
	fi

	return 0
} # => rebuild_move()

# gen-crl backend
gen_crl() {
	verify_ca_init

	out_file="$EASYRSA_PKI/crl.pem"

	out_file_tmp=""
	easyrsa_mktemp out_file_tmp || \
		die "gen_crl - easyrsa_mktemp out_file_tmp"

	easyrsa_openssl ca -utf8 -gencrl -out "$out_file_tmp" \
		${EASYRSA_CRL_DAYS:+ -days "$EASYRSA_CRL_DAYS"} \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} || \
			die "CRL Generation failed."

	mv ${EASYRSA_BATCH:+ -f} "$out_file_tmp" "$out_file"

	notice "\
An updated CRL has been created:
* $out_file"

	return 0
} # => gen_crl()

# import-req backend
import_req() {
	# Verify PKI has been initialised
	verify_pki_init

	# pull passed paths
	in_req="$1"
	short_name="$2"
	out_req="$EASYRSA_PKI/reqs/$2.req"

	[ "$short_name" ] || die "\
Unable to import: incorrect command syntax.
Run easyrsa without commands for usage and command help."

	# Request file must exist
	[ -e "$in_req" ] || die "\
No request found for the input: '$2'
Expected to find the request at: $in_req"

	verify_file req "$in_req" || die "\
The input file does not appear to be a certificate request. Aborting import.
File Path: $in_req"

	# destination must not exist
	[ -e "$out_req" ] && die "\
Unable to import the request as the destination file already exists.
Please choose a different name for your imported request file.
Existing file at: $out_req"

	# now import it
	cp "$in_req" "$out_req"

	notice "\
The request has been successfully imported with a short name of: $short_name
You may now use this name to perform signing operations on this request."

	return 0
} # => import_req()

# export pkcs#12, pkcs#7, pkcs#8 or pkcs#1
export_pkcs() {
	pkcs_type="$1"
	shift

	[ "$1" ] || die "\
Unable to export p12: incorrect command syntax.
Run easyrsa without commands for usage and command help."

	short_name="$1"
	shift

	crt_in="$EASYRSA_PKI/issued/$short_name.crt"
	key_in="$EASYRSA_PKI/private/$short_name.key"
	crt_ca="$EASYRSA_PKI/ca.crt"

	# Verify PKI has been initialised
	verify_pki_init

	# opts support
	cipher=-aes256
	want_ca=1
	want_key=1
	unset -v pkcs_friendly_name
	while [ "$1" ]; do
		case "$1" in
			noca) want_ca="" ;;
			nokey) want_key="" ;;
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			usefn) pkcs_friendly_name="$short_name" ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	pkcs_certfile_path=
	if [ "$want_ca" ]; then
		verify_file x509 "$crt_ca" || die "\
Unable to include CA cert in the $pkcs_type output (missing file, or use noca option.)
Missing file expected at: $crt_ca"
		pkcs_certfile_path="$crt_ca"
	fi

	# input files must exist
	verify_file x509 "$crt_in" || die "\
Unable to export $pkcs_type for short name '$short_name' without the certificate.
Missing cert expected at: $crt_in"

	# For 'nopass' PKCS requires an explicit empty password 'pass:'
	if [ "$EASYRSA_NO_PASS" ]; then
		EASYRSA_PASSIN=pass:
		EASYRSA_PASSOUT=pass:
		unset -v cipher # pkcs#1 only
	fi

	case "$pkcs_type" in
	p12)
		pkcs_out="$EASYRSA_PKI/private/$short_name.p12"

		if [ "$want_key" ]; then
			[ -e "$key_in" ] || die "\
Unable to export p12 for short name '$short_name' without the key
(if you want a p12 without the private key, use nokey option.)
Missing key expected at: $key_in"
		else
			nokeys=1
		fi

		# export the p12:
		easyrsa_openssl pkcs12 -in "$crt_in" -inkey "$key_in" -export \
			-out "$pkcs_out" \
			${nokeys:+ -nokeys} \
			${pkcs_certfile_path:+ -certfile "$pkcs_certfile_path"} \
			${pkcs_friendly_name:+ -name "$pkcs_friendly_name"} \
			${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} \
				|| die "Failed to export PKCS#12"
	;;
	p7)
		pkcs_out="$EASYRSA_PKI/issued/$short_name.p7b"

		# export the p7:
		easyrsa_openssl crl2pkcs7 -nocrl -certfile "$crt_in" \
			-out "$pkcs_out" \
			${pkcs_certfile_path:+ -certfile "$pkcs_certfile_path"} \
				|| die "Failed to export PKCS#7"
	;;
	p8)
		pkcs_out="$EASYRSA_PKI/private/$short_name.p8"

		# export the p8:
		easyrsa_openssl pkcs8 -in "$key_in" -topk8 \
			-out "$pkcs_out" \
			${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} \
				|| die "Failed to export PKCS#8"
      ;;
	p1)
		pkcs_out="$EASYRSA_PKI/private/$short_name.p1"

		# export the p1:
		easyrsa_openssl rsa -in "$key_in" \
			-out "$pkcs_out" \
			${cipher:+ "$cipher"} \
			${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
			${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} \
				|| die "Failed to export PKCS#1"
	;;
	*) die "Unknown PKCS type: $pkcs_type"
	esac

	notice "\
Successful export of $pkcs_type file. Your exported file is at the following
location: $pkcs_out"

	return 0
} # => export_pkcs()

# set-pass backend legacy
set_pass_legacy() {
	# Verify PKI has been initialised
	verify_pki_init

	# key type, supplied internally from frontend command call (rsa/ec)
	key_type="$1"
	shift

	# values supplied by the user:
	raw_file="$1"
	shift

	file="$EASYRSA_PKI/private/$raw_file.key"

	[ "$raw_file" ] || die "\
Missing argument to 'set-$key_type-pass' command: no name/file supplied.
See help output for usage details."

	# parse command options
	cipher="-aes256"
	unset -v nopass
	while [ "$1" ]; do
		case "$1" in
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			file) file="$raw_file" ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# If nopass then do not encrypt else encrypt with password.
	if [ "$EASYRSA_NO_PASS" ]; then
		unset -v cipher
	fi

	[ -e "$file" ] || die "\
Missing private key: expected to find the private key component at:
$file"

	notice "\
If the key is currently encrypted you must supply the decryption passphrase.
${cipher:+You will then enter a new PEM passphrase for this key.$NL}"

	# Set password
	out_key_tmp=""
	easyrsa_mktemp out_key_tmp || \
		die "set_pass_legacy - easyrsa_mktemp out_key_tmp"

	easyrsa_openssl "$key_type" -in "$file" -out "$out_key_tmp" \
		${cipher:+ "$cipher"} \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
		${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} || die "\
Failed to change the private key passphrase. See above for possible openssl
error messages."

	mv "$out_key_tmp" "$file" || die "\
Failed to change the private key passphrase. See above for error messages."

	notice "Key passphrase successfully changed"

	return 0
} # => set_pass_legacy()

# set-pass backend
set_pass() {
	# Verify PKI has been initialised
	verify_pki_init

	# values supplied by the user:
	raw_file="$1"
	file="$EASYRSA_PKI/private/$raw_file.key"

	if [ "$raw_file" ]; then
		shift
	else
		die "\
Missing argument: no name/file supplied."
	fi

	# parse command options
	cipher="-aes256"
	while [ "$1" ]; do
		case "$1" in
			nopass)
				[ "$prohibit_no_pass" ] || EASYRSA_NO_PASS=1
			;;
			file) file="$raw_file" ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# If nopass then do not encrypt else encrypt with password.
	if [ "$EASYRSA_NO_PASS" ]; then
		unset -v cipher
	fi

	[ -e "$file" ] || die "\
Missing private key: expected to find the private key component at:
$file"

	warn "\
If the key is encrypted then you must supply the decryption pass phrase.
${cipher:+You will then enter and verify a new PEM pass phrase for this key.}"

	# Set password
	out_key_tmp=""
	easyrsa_mktemp out_key_tmp || \
		die "set_pass - easyrsa_mktemp out_key_tmp"

	easyrsa_openssl pkey -in "$file" -out "$out_key_tmp" \
		${cipher:+ "$cipher"} \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} \
		${EASYRSA_PASSOUT:+ -passout "$EASYRSA_PASSOUT"} || die "\
Failed to change the private key passphrase."

	mv "$out_key_tmp" "$file" || die "\
Failed to update the private key file."

	key_update=changed
	[ "$EASYRSA_NO_PASS" ] && key_update=removed
	notice "Key passphrase successfully $key_update"
} # => set_pass()

# update-db backend
update_db() {
	verify_ca_init

	easyrsa_openssl ca -utf8 -updatedb \
		${EASYRSA_PASSIN:+ -passin "$EASYRSA_PASSIN"} || die "\
Failed to perform update-db: see above for related openssl errors."

	return 0
} # => update_db()

# Display subjectAltName
display_san() {
	[ "$#" = 2 ] || die "\
display_san - input error"

	format="$1"
	path="$2"
	shift 2

	if echo "$EASYRSA_EXTRA_EXTS" | grep -q subjectAltName; then
		# Print user defined SAN
			print "$(\
		echo "$EASYRSA_EXTRA_EXTS" | grep subjectAltName | \
		sed 's/^[[:space:]]*subjectAltName[[:space:]]*=[[:space:]]*//'
		)"

	else
		# Generate a SAN
			san="$(
		x509v3san="X509v3 Subject Alternative Name:"
		easyrsa_openssl "$format" -in "$path" -noout -text | sed -n \
		"/${x509v3san}/{n;s/ //g;s/IPAddress:/IP:/g;s/RegisteredID/RID/;p;}"
		)"

		# Print auto SAN
		[ "$san" ] && print "$san"
	fi
} # => display_san()

# display cert DN info on a req/X509, passed by full pathname
display_dn() {
	[ "$#" = 2 ] || die "\
display_dn - input error"

	format="$1"
	path="$2"
	shift 2

	# Display DN
	name_opts="utf8,sep_multiline,space_eq,lname,align"
	print "$(
		easyrsa_openssl "$format" -in "$path" -noout -subject \
			-nameopt "$name_opts"
		)"

	# Display SAN, if present
	san="$(display_san "$format" "$path")"
	if [ "$san" ]; then
		print ""
		print "X509v3 Subject Alternative Name:"
		print "    $san"
	fi
} # => display_dn()

# generate default SAN from req/X509, passed by full pathname
default_server_san() {
	[ "$#" = 1 ] || die "\
default_server_san - input error"

	path="$1"
	shift

	# Extract CN from DN
	cn="$(
		easyrsa_openssl req -in "$path" -noout -subject \
			-nameopt sep_multiline |
				awk -F'=' '/^  *CN=/{print $2}'
		)"

	# See: https://github.com/OpenVPN/easy-rsa/issues/576
	# Select default SAN
	if echo "$cn" | grep -q \
		-E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
	then
		print "subjectAltName = IP:$cn"
	else
		print "subjectAltName = DNS:$cn"
	fi
} # => default_server_san()

# Verify certificate against CA
verify_cert() {
	# pull filename base:
	[ "$1" ] || die "\
Error: didn't find a file base name as the first argument.
Run easyrsa without commands for usage and command help."

	verify_ca_init

	# Assign file_name_base and dust off!
	file_name_base="$1"
	shift

	# Support global --batch mode
	unset -v exit_with_error
	if [ "$EASYRSA_BATCH" ]; then
		exit_with_error=1
		EASYRSA_SILENT=1
	fi

	# function opts support
	while [ "$1" ]; do
		case "$1" in
			# batch flag, return status [0/1] to calling program
			# Otherwise, exit 0 on successful completion
			batch)
				exit_with_error=1
				EASYRSA_SILENT=1
			;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	in_dir="$EASYRSA_PKI"
	ca_crt="$in_dir/ca.crt"
	crt_in="$in_dir/issued/$file_name_base.crt"

	# Cert file must exist
	[ -e "$crt_in" ] || die "\
No certificate found for the input: '$crt_in'"

	# Verify file is a valid cert
	verify_file x509 "$crt_in" || die "\
Input is not a valid certificate: $crt_in"

	# Test SSL out
	# openssl direct call because error is expected
	if "$EASYRSA_OPENSSL" verify -CAfile "$ca_crt" \
		"$crt_in" 1>/dev/null
	then
		notice "\
  Certificate name:   $file_name_base
  Verfication status: GOOD"
		# easyrsa_error_exit=1 # Simple 'proof of concept' test
	else
		notice "\
  Certificate name:   $file_name_base
  Verfication status: FAILED"
		# Exit with error (batch mode), otherwise term msg only
		if [ "$exit_with_error" ]; then
			easyrsa_error_exit=1
			# Return error for internal callers (status reports)
			# or command line in --batch mode
			return 1
		fi
	fi
} # => verify_cert()

# verify a file seems to be a valid req/X509
verify_file() {
	format="$1"
	path="$2"
	easyrsa_openssl "$format" -in "$path" -noout 2>/dev/null
} # => verify_file()

# show-* command backend
# Prints req/cert details in a readable format
show() {
	type="$1"
	name="$2"
	in_file=""
	format=""
	[ "$name" ] || die "\
Missing expected <file_name_base> argument.
Run easyrsa without commands for usage help."
	shift 2

	# opts support
	type_opts="-${type}opt"
	out_opts="no_pubkey,no_sigdump"
	name_opts="utf8,sep_multiline,space_eq,lname,align"
	while [ "$1" ]; do
		case "$1" in
			full) out_opts= ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	# Determine cert/req type (v2)
	case "$type" in
	cert)
		verify_ca_init
		in_file="$EASYRSA_PKI/issued/$name.crt"
		format="x509"
	;;
	req)
		verify_pki_init
		in_file="$EASYRSA_PKI/reqs/$name.req"
		format="req"
	;;
	crl)
		verify_ca_init
		in_file="$EASYRSA_PKI/$name.pem"
		format="crl"
		unset -v type_opts out_opts name_opts
	;;
	*) die "Unrecognised type: $type"
	esac

	# Verify file exists and is of the correct type
	[ -e "$in_file" ] || die "\
No such '$type' type file with a <file_name_base> of '$name' is present.
Expected to find this file at:
$in_file"

	verify_file "$format" "$in_file" || die "\
This file is not a valid $type file:
$in_file"

	notice "\
Showing $type details for: '$name'

This file is stored at:
* $in_file"

	easyrsa_openssl "$format" -in "$in_file" -noout -text \
		${type_opts:+ "$type_opts" "$out_opts"} \
		${name_opts:+ -nameopt "$name_opts"} \
			|| die "\
OpenSSL failure to process the input"

} # => show()

# show-ca command backend
# Prints CA cert details in a readable format
show_ca() {
	# opts support
	out_opts="no_pubkey,no_sigdump"
	name_opts="utf8,sep_multiline,space_eq,lname,align"
	while [ "$1" ]; do
		case "$1" in
			full) out_opts= ;;
			*) warn "Ignoring unknown command option: '$1'"
		esac
		shift
	done

	verify_ca_init
	in_file="$EASYRSA_PKI/ca.crt"
	format="x509"

	# Verify file exists and is of the correct type
	[ -e "$in_file" ] || die "\
No such $type file with a basename of '$name' is present.
Expected to find this file at:
$in_file"

	verify_file "$format" "$in_file" || die "\
This file is not a valid $type file:
$in_file"

	notice "
Showing details for CA certificate, at:
* $in_file
"

	easyrsa_openssl "$format" -in "$in_file" -noout -text \
		-nameopt "$name_opts" -certopt "$out_opts" || die "\
OpenSSL failure to process the input"

} # => show_ca()

# get the serial number of the certificate -> serial=XXXX
ssl_cert_serial() {
	[ "$#" = 2 ] || die "ssl_cert_serial - input error"
	[ -f "$1" ] || die "ssl_cert_serial - missing cert"

	fn_ssl_out="$(
		easyrsa_openssl x509 -in "$1" -noout -serial
		)"  || die "ssl_cert_serial - failed: -serial"
	# remove the serial= part -> we only need the XXXX part
	fn_ssl_out="${fn_ssl_out##*=}"

	force_set_var "$2" "$fn_ssl_out" || \
		die "ssl_cert_serial - failed to set var '$*'"

	unset -v fn_ssl_out
} # => ssl_cert_serial()

# Get certificate start date
ssl_cert_not_before_date() {
	verbose "DEPRECATED: ssl_cert_not_before_date()"
	[ "$#" = 2 ] || die "\
ssl_cert_not_before_date - input error"
	[ -f "$1" ] || die "\
ssl_cert_not_before_date - missing cert"

	fn_ssl_out="$(
		easyrsa_openssl x509 -in "$1" -noout -startdate
		)" || die "\
ssl_cert_not_before_date - failed: -startdate"

	fn_ssl_out="${fn_ssl_out#*=}"

	force_set_var "$2" "$fn_ssl_out" || die "\
ssl_cert_not_before_date - failed to set var '$*'"

	unset -v fn_ssl_out
} # => ssl_cert_not_before_date()

# Get certificate end date
ssl_cert_not_after_date() {
	verbose "DEPRECATED: ssl_cert_not_after_date()"
	[ "$#" = 2 ] || die "\
ssl_cert_not_after_date - input error"
	[ -f "$1" ] || die "\
ssl_cert_not_after_date - missing cert"

	fn_ssl_out="$(
		easyrsa_openssl x509 -in "$1" -noout -enddate
		)" || die "\
ssl_cert_not_after_date - failed: -enddate"

	fn_ssl_out="${fn_ssl_out#*=}"

	force_set_var "$2" "$fn_ssl_out" || die "\
ssl_cert_not_after_date - failed to set var '$*'"

	unset -v fn_ssl_out
} # => ssl_cert_not_after_date()

# SSL -- v3 -- startdate iso_8601
iso_8601_cert_startdate() {
	verbose "NEW: iso_8601_cert_startdate"
	[ "$#" = 2 ] || die "\
iso_8601_cert_startdate: input error"
	[ -f "$1" ] || die "\
iso_8601_cert_startdate: missing cert"

	# On error return, let the caller decide what to do
	if fn_ssl_out="$(
		easyrsa_openssl x509 -in "$1" -noout \
			-startdate -dateopt iso_8601
		)"
	then
		: # ok
	else
		# The caller MUST assess this error
		verbose "\
iso_8601_cert_startdate: GENERATED ERROR"
		return 1
	fi

	fn_ssl_out="${fn_ssl_out#*=}"

	force_set_var "$2" "$fn_ssl_out" || die "\
iso_8601_cert_startdate: failed to set var '$*'"

	unset -v fn_ssl_out
} # => iso_8601_cert_startdate()

# SSL -- v3 -- enddate iso_8601
iso_8601_cert_enddate() {
	verbose "NEW: iso_8601_cert_enddate"
	[ "$#" = 2 ] || die "\
iso_8601_cert_enddate: input error"
	[ -f "$1" ] || die "\
iso_8601_cert_enddate: missing cert"

	# On error return, let the caller decide what to do
	if fn_ssl_out="$(
		easyrsa_openssl x509 -in "$1" -noout \
			-enddate -dateopt iso_8601
		)"
	then
		: # ok
	else
		# The caller MUST assess this error
		verbose "\
iso_8601_cert_enddate: GENERATED ERROR"
		return 1
	fi

	fn_ssl_out="${fn_ssl_out#*=}"

	force_set_var "$2" "$fn_ssl_out" || die "\
iso_8601_cert_enddate: failed to set var '$*'"

	unset -v fn_ssl_out
} # => iso_8601_cert_enddate()

# iso_8601_timestamp_to_seconds since epoch
iso_8601_timestamp_to_seconds() {
	verbose "NEW: iso_8601_timestamp_to_seconds"
	# check input
	[ "$#" = 2 ] || die "\
iso_8601_timestamp_to_seconds: input error"

	in_date="$1"
	verbose "\
NEW: iso_8601_timestamp_to_seconds: in_date=$in_date"

	# Consume $in_date string
	yyyy="${in_date%%-*}"

	# When yyyy is only two digits prepend century
	if [ "${#yyyy}" = 2 ]; then
		yyyy="${yyyy#0}"
		if [ "$yyyy" -lt 70 ]; then
			if [ "${#yyyy}" = 2 ]; then
				yyyy="20${yyyy}"
			else
				yyyy="200${yyyy}"
			fi
		else
			yyyy="19${yyyy}"
		fi
	fi
	verbose "\
NEW: iso_8601_timestamp_to_seconds: yyyy: $yyyy"

	# yyyy must be four digits now
	# Caller MUST assess this error
	if [ "${#yyyy}" = 4 ]; then
		: # ok
	else
		verbose "\
NEW: iso_8601_timestamp_to_seconds: GENERATED ERROR (yyyy=$yyyy)"
		return 1
	fi

	# Leap years
	leap_years="$(( (yyyy - 1970 + 2 ) / 4 ))"
	is_leap_year="$(( (yyyy - 1970 + 2 ) % 4 ))"
	if [ "$is_leap_year" = 0 ]; then
		leap_years="$(( leap_years - 1 ))"
		leap_day=1
		verbose "\
NEW: iso_8601_timestamp_to_seconds: is_leap_year=TRUE"
	else
		leap_day=0
		verbose "\
NEW: iso_8601_timestamp_to_seconds: is_leap_year=FALSE"
	fi
	unset -v is_leap_year

	in_date="${in_date#*-}"
	mm="${in_date%%-*}"
	in_date="${in_date#*-}"
	dd="${in_date%% *}"
	in_date="${in_date#* }"
	HH="${in_date%%:*}"
	in_date="${in_date#*:}"
	MM="${in_date%%:*}"
	in_date="${in_date#*:}"
	SS="${in_date%?}"
	in_date="${in_date#??}"
	TZ="$in_date"
	unset -v in_date

	# Check that TZ is a single character
	if [ "${#TZ}" = 1 ]; then
		: # ok
	else
		# Caller MUST assess this error
		verbose "\
NEW: iso_8601_timestamp_to_seconds: GENERATED ERROR (TZ=$TZ)"
		return 1
	fi

	# number of days per month
	case "$mm" in
	01) mdays="$(( 0 ))" ;;
	02) mdays="$(( 31 ))" ;;
	03) mdays="$(( 31+28+leap_day ))" ;;
	04) mdays="$(( 31+28+leap_day+31 ))" ;;
	05) mdays="$(( 31+28+leap_day+31+30 ))" ;;
	06) mdays="$(( 31+28+leap_day+31+30+31 ))" ;;
	07) mdays="$(( 31+28+leap_day+31+30+31+30 ))" ;;
	08) mdays="$(( 31+28+leap_day+31+30+31+30+31 ))" ;;
	09) mdays="$(( 31+28+leap_day+31+30+31+30+31+31 ))" ;;
	10) mdays="$(( 31+28+leap_day+31+30+31+30+31+31+30 ))" ;;
	11) mdays="$(( 31+28+leap_day+31+30+31+30+31+31+30+31 ))" ;;
	12) mdays="$(( 31+28+leap_day+31+30+31+30+31+31+30+31+30 ))" ;;
	# This means the input date was not iso_8601
	*)
		# Caller MUST assess this error
		verbose "\
NEW: iso_8601_timestamp_to_seconds: GENERATED ERROR (mm=$mm)"
		return 1
	esac

	# Remove leading ZERO. eg: SS = 09
	[ "$yyyy" = "${yyyy#0}" ] || die "Leading zero: yyyy: $yyyy"
	mm="${mm#0}"
	dd="${dd#0}"
	HH="${HH#0}"
	MM="${MM#0}"
	SS="${SS#0}"

	# Calculate seconds since epoch
	out_seconds="$((
		(( yyyy - 1970 ) * ( 60 * 60 * 24 * 365 ))
		+ (( leap_years ) * ( 60 * 60 * 24 ))
		+ (( mdays ) * ( 60 * 60 * 24 ))
		+ (( dd - 1 ) * ( 60 * 60 * 24 ))
		+ (( HH ) * ( 60 * 60 ))
		+ (( MM ) * ( 60 ))
		+ SS
		))" || die "\
iso_8601_timestamp_to_seconds: out_seconds=$out_seconds"

	# Return out_seconds
	force_set_var "$2" "$out_seconds" || die "\
iso_8601_timestamp_to_seconds: \
- force_set_var - $2 - $out_seconds"

	unset -v in_date out_seconds leap_years \
		yyyy mm dd HH MM SS TZ
} # => iso_8601_timestamp_to_seconds()

# Number of days from NOW@today as timestamp seconds
days_to_timestamp_s() {
	verbose "REQUIRED: days_to_timestamp_s: uses date"
	# check input
	[ "$#" = 2 ] || die "\
days_to_timestamp_s: input error"

	in_days="$1"
	in_seconds="$(( in_days * 60 * 60 * 24 ))"

	# There are NO OS dependencies for this use of date
	# OS dependencies
	# Linux and Windows
	# date.exe does not allow +%s as input
	# MacPorts GNU date
	if timestamp_s="$(
			date +%s 2>/dev/null
			)"
	then : # ok

	# Darwin, BSD
	elif timestamp_s="$(
			date +%s 2>/dev/null
			)"
	then : # ok

	# busybox
	elif timestamp_s="$(
			busybox date +%s 2>/dev/null
			)"
	then : # ok

	# Something else
	else
		die "\
days_to_timestamp_s: 'date +%s' failed"
	fi

	# Add period
	timestamp_s="$(( timestamp_s + in_seconds ))"

	# Return timestamp_s
	force_set_var "$2" "$timestamp_s" || die "\
days_to_timestamp_s: force_set_var - $2 - $timestamp_s"

	unset -v in_days in_seconds timestamp_s
} # => days_to_timestamp_s()

# Convert certificate date to timestamp seconds since epoch
# Used to verify iso_8601 calculated seconds since epoch
cert_date_to_timestamp_s() {
	verbose "DEPRECATED: cert_date_to_timestamp_s"
	# check input
	[ "$#" = 2 ] || die "\
cert_date_to_timestamp_s: input error"

#die "* NOT ALLOWED: cert_date_to_timestamp_s()"

	in_date="$1"

	# OS dependencies
	# Linux and Windows
	# date.exe does not allow +%s as input
	# MacPorts GNU date
	if timestamp_s="$(
			date -d "$in_date" +%s \
				2>/dev/null
			)"
	then : # ok

	# Darwin, BSD
	elif timestamp_s="$(
			date -j -f '%b %d %T %Y %Z' \
				"$in_date" +%s 2>/dev/null
			)"
	then : # ok

	# busybox
	elif timestamp_s="$(
			busybox date -D "%b %e %H:%M:%S %Y" \
				-d "$in_date" +%s 2>/dev/null
			)"
	then : # ok

	# Something else
	else
		die "\
cert_date_to_timestamp_s:
'date' failed for in_date=$in_date"
	fi

	# Return timestamp_s
	force_set_var "$2" "$timestamp_s" || die "\
cert_date_to_timestamp_s: force_set_var - $2 - $timestamp_s"

	unset -v in_date timestamp_s
} # => cert_date_to_timestamp_s()

# Build a Windows date.exe compatible input field
# iso_8601 date
db_date_to_iso_8601_date() {
	verbose "iso_8601: db_date_to_iso_8601_date"
	# check input
	[ "$#" = 2 ] || die "\
db_date_to_iso_8601_date - input error"

	# Expected format: '230612235959Z'
	in_date="$1"
	verbose "db_date_to_iso_8601_date: in_date=$in_date"

	# Consume $in_date string
	# yyyy is expected to be only 'yy'
	yyyy="${in_date%???????????}"
	in_date="${in_date#"$yyyy"}"

	# When yyyy is only two digits prepend century
	if [ "${#yyyy}" = 2 ]; then
		yyyy="${yyyy#0}"
		if [ "$yyyy" -lt 70 ]; then
			if [ "${#yyyy}" = 2 ]; then
				yyyy="20${yyyy}"
			else
				yyyy="200${yyyy}"
			fi
		else
			if [ "${#yyyy}" = 2 ]; then
				yyyy="19${yyyy}"
			else
				yyyy="190${yyyy}"
			fi
		fi
	fi
	verbose "db_date_to_iso_8601_date: yyyy=$yyyy"

	mm="${in_date%?????????}"
	in_date="${in_date#"$mm"}"
	dd="${in_date%???????}"
	in_date="${in_date#"$dd"}"
	HH="${in_date%?????}"
	in_date="${in_date#"$HH"}"
	MM="${in_date%???}"
	in_date="${in_date#"$MM"}"
	SS="${in_date%?}"
	in_date="${in_date#"$SS"}"
	TZ="$in_date"

	# Assign iso_8601 date
	out_date="${yyyy}-${mm}-${dd} ${HH}:${MM}:${SS}${TZ}"

	# Return out_date
	force_set_var "$2" "$out_date" || die "\
db_date_to_iso_8601_date: force_set_var - $2 - $out_date"

	unset -v in_date out_date yyyy mm dd HH MM SS TZ
} # => db_date_to_iso_8601_date()

# Convert default SSL date to iso_8601 date
# This may not be feasible, due to different languages
# Alow the caller to assess those errors (eg. Fall-back)
cert_date_to_iso_8601_date() {
	verbose "iso_8601-WIP: cert_date_to_iso_8601_date"
	die "BLOCKED: cert_date_to_iso_8601_date"

	# check input
	[ "$#" = 2 ] || die "\
cert_date_to_iso_8601_date: input error"

	# Expected format: 'Mar 21 18:25:01 2023 GMT'
	in_date="$1"

	# Consume in_date string
	mmm="${in_date%% *}"
	in_date="${in_date#"$mmm" }"
	dd="${in_date%% *}"
	in_date="${in_date#"$dd" }"
	HH="${in_date%%:*}"
	in_date="${in_date#"$HH":}"
	MM="${in_date%%:*}"
	in_date="${in_date#"$MM":}"
	SS="${in_date%% *}"
	in_date="${in_date#"$SS" }"
	yyyy="${in_date%% *}"
	in_date="${in_date#"$yyyy" }"
	TZ="$in_date"

	# Assign month number by abbreviation
	case "$mmm" in
	Jan) mm="01" ;;
	Feb) mm="02" ;;
	Mar) mm="03" ;;
	Apr) mm="04" ;;
	May) mm="05" ;;
	Jun) mm="06" ;;
	Jul) mm="07" ;;
	Aug) mm="08" ;;
	Sep) mm="09" ;;
	Oct) mm="10" ;;
	Nov) mm="11" ;;
	Dec) mm="12" ;;
	*)
		information "Only english dates are currently supported."
		warn "cert_date_to_iso_8601_date - Unknown month: '$mmm'"
		# The caller is REQUIRED to assess this error
		return 1
	esac

	# Assign signle letter timezone from abbreviation
	case "$TZ" in
	GMT) TZ=Z ;;
	*)
		information "Only english dates are currently supported."
		warn "cert_date_to_iso_8601_date - Unknown timezone: '$TZ'"
		# The caller is REQUIRED to assess this error
		return 1
	esac

	# Assign iso_8601 date
	out_date="${yyyy}-${mm}-${dd} ${HH}:${MM}:${SS}${TZ}"

	# Return iso_8601 date
	force_set_var "$2" "$out_date" || die "\
cert_date_to_iso_8601: force_set_var - $2 - $out_date"

	unset -v in_date out_date yyyy mmm  mm dd HH MM SS TZ
} # => cert_date_to_iso_8601()

# SC2295: Expansion inside ${..} need to be quoted separately,
# otherwise they match as patterns. (what-ever that means ;-)
# Unfortunately, Windows sh.exe has an weird bug.
# Try in sh.exe: t='   '; s="a${t}b${t}c"; echo "${s%%"${t}"*}"

# Read db
# shellcheck disable=SC2295
read_db() {
	TCT='	' # tab character
	db_in="$EASYRSA_PKI/index.txt"
	pki_r_issued="$EASYRSA_PKI/renewed/issued"
	pki_r_by_sno="$EASYRSA_PKI/renewed/certs_by_serial"
	unset -v target_found

	while read -r db_status db_notAfter db_record; do

		verbose "***** Read next record *****"

		# Recreate temp session
		remove_secure_session || \
			die "read_db - remove_secure_session"
		secure_session || \
			die "read_db - secure_session"
		if [ "$require_safe_ssl_conf" ];  then
			EASYRSA_SILENT=1 make_safe_ssl || \
				die "read_db - make_safe_ssl"
		fi

		# Interpret the db/certificate record
		unset -v db_serial db_cn db_revoke_date db_reason
		case "$db_status" in
		V|E)
			# Valid
			db_serial="${db_record%%${TCT}*}"
			db_record="${db_record#*${TCT}}"
			db_cn="${db_record#*/CN=}"; db_cn="${db_cn%%/*}"
			cert_issued="$EASYRSA_PKI/issued/$db_cn.crt"
			cert_r_issued="$pki_r_issued/$db_cn.crt"
			cert_r_by_sno="$pki_r_by_sno/$db_serial.crt"
		;;
		R)
			# Revoked
			db_revoke_date="${db_record%%${TCT}*}"
			db_reason="${db_revoke_date#*,}"
			if [ "$db_reason" = "$db_revoke_date" ]; then
				db_reason="None given"
			else
				db_revoke_date="${db_revoke_date%,*}"
			fi
			db_record="${db_record#*${TCT}}"

			db_serial="${db_record%%${TCT}*}"
			db_record="${db_record#*${TCT}}"
			db_cn="${db_record#*/CN=}"; db_cn="${db_cn%%/*}"
		;;
		*) die "Unexpected status: $db_status"
		esac

		# Output selected status report for this record
		case "$report" in
		expire)
		# Certs which expire before EASYRSA_PRE_EXPIRY_WINDOW days
			case "$db_status" in
			V|E)
				case "$target" in
				'') expire_status ;;
				*)
					if [ "$target" = "$db_cn" ]; then
						expire_status
					fi
				esac
			;;
			*)
				: # Ignore ok
			esac
		;;
		revoke)
		# Certs which have been revoked
			case "$db_status" in
			R)
				case "$target" in
				'') revoke_status ;;
				*)
					if [ "$target" = "$db_cn" ]; then
						revoke_status
					fi
				esac
			;;
			*)
				: # Ignore ok
			esac
		;;
		renew)
		# Certs which have been renewed but not revoked
			case "$db_status" in
			V|E)
				case "$target" in
				'') renew_status ;;
				*)
					if [ "$target" = "$db_cn" ]; then
						renew_status
					fi
				esac
			;;
			*)
				: # Ignore ok
			esac
		;;
		*) die "Unrecognised report: $report"
		esac

		# Is db record for target found
		if [ "$target" = "$db_cn" ]; then
			target_found=1
		fi

	done < "$db_in"

	# Check for target found/valid commonName, if given
	if [ "$target" ]; then
		[ "$target_found" ] || \
			warn "Certificate for $target was not found"
	fi
} # => read_db()

# Expire status
expire_status() {
	unset -v expire_status_cert_exists
	pre_expire_window_s="$((
		EASYRSA_PRE_EXPIRY_WINDOW * 60*60*24
		))"

	# The certificate for CN should exist but may not
	unset -v expire_status_cert_exists
	if [ -e "$cert_issued" ]; then

		verbose "expire_status: cert exists"
		expire_status_cert_exists=1

		# get the serial number of the certificate
		ssl_cert_serial "$cert_issued" cert_serial

		# db serial must match certificate serial, otherwise
		# this is a renewed cert which has been replaced by
		# an issued cert
		if [ "$db_serial" != "$cert_serial" ]; then
			information "\
expire_status: SERIAL MISMATCH
  db_serial:     $db_serial
  cert_serial:   $cert_serial
  commonName:    $db_cn
  cert_issued:   $cert_issued${NL}"
			#return 0
		fi

		# Get cert end date in iso_8601 format from SSL
		# or fall-back to old format
		# Redirect SSL error to /dev/null here not in function
		cert_not_after_date=
		if iso_8601_cert_enddate \
			"$cert_issued" cert_not_after_date 2>/dev/null
		then
			: # ok
		else
			verbose "\
expire_status: ACCEPTED ERROR-1: \
from iso_8601_cert_enddate"
			verbose "\
expire_status: CONSUMED ERROR: \
FALL-BACK to default SSL date format"
			ssl_cert_not_after_date \
				"$cert_issued" cert_not_after_date
			verbose "\
expire_status: FALL-BACK completed"
		fi

	else
		verbose "expire_status: cert does NOT exist"
		# Translate db date to usable date
		cert_not_after_date=
		db_date_to_iso_8601_date \
			"$db_notAfter" cert_not_after_date
		# Cert does not exist
	fi

	# Only verify if there is a certificate
	if [ "$expire_status_cert_exists" ]; then

		# Check cert expiry against window
		# openssl direct call because error is expected
		if "$EASYRSA_OPENSSL" x509 -in "$cert_issued" \
			-noout -checkend "$pre_expire_window_s" \
			1>/dev/null
		then
			expire_msg="will NOT expire"
			will_not_expire=1
			unset -v will_expire
		else
			expire_msg="will expire"
			will_expire=1
			unset -v will_not_expire
		fi
		verbose "expire_status: SSL checkend: $expire_msg"

		# Get timestamp seconds for certificate expiry date
		# Redirection for errout is not necessary here
		cert_expire_date_s=
		if iso_8601_timestamp_to_seconds \
				"$cert_not_after_date" cert_expire_date_s
		then
			: # ok

			# Verify dates via 'date +%s' format
			verbose "\
expire_status: cert_date_to_timestamp_s: for comparison"
			old_cert_expire_date_s=
			cert_date_to_timestamp_s \
				"$cert_not_after_date" old_cert_expire_date_s

			# Prove this works
			if [ "$cert_expire_date_s" = "$old_cert_expire_date_s" ]
			then
				verbose "\
expire_status: ABSOLUTE seconds MATCH:
    cert_expire_date_s=     $cert_expire_date_s
    old_cert_expire_date_s= $old_cert_expire_date_s"
			else
				verbose "\
expire_status: ABSOLUTE seconds do not MATCH:
    cert_expire_date_s=     $cert_expire_date_s
    old_cert_expire_date_s= $old_cert_expire_date_s
    difference=             \
$(( cert_expire_date_s - old_cert_expire_date_s ))"

				# If there is an error then use --days-margin=10
				[ "$EASYRSA_iso_8601_MARGIN" ] || \
					die "\
expire_status - ABSOLUTE seconds mismatch: Use --allow-margin=N"

				# Allows days for margin of error in seconds
				margin_s="$((
					EASYRSA_iso_8601_MARGIN * (60 * 60 * 24) + 1
					))"
				margin_plus_s="$((
					old_cert_expire_date_s + margin_s
					))"
				margin_minus_s="$((
					old_cert_expire_date_s - margin_s
					))"

				if [ "$cert_expire_date_s" -lt "$margin_plus_s" ] && \
					[ "$cert_expire_date_s" -gt "$margin_minus_s" ]
				then
					: # ok
					verbose "\
expire_status: MARGIN seconds ACCEPTED:
    cert_expire_date_s=     $cert_expire_date_s
    old_cert_expire_date_s= $old_cert_expire_date_s
    difference=             \
    $(( cert_expire_date_s - old_cert_expire_date_s ))
    margin_plus_s=          $margin_plus_s
    margin_minus_s=         $margin_minus_s"
				else
					verbose "\
expire_status: MARGIN seconds REJECTED:
    cert_expire_date_s=     $cert_expire_date_s
    old_cert_expire_date_s= $old_cert_expire_date_s
    margin_plus_s=          $margin_plus_s
    margin_minus_s=         $margin_minus_s"

					die "\
expire_status: Verify cert expire date EXCESS mismatch!"
				fi
			fi

			verbose "\
expire_status: cert_date_to_timestamp_s: comparison complete"

		else
			verbose  "\
expire_status: ACCEPTED ERROR-2: \
iso_8601_timestamp_to_seconds"
			verbose "\
expire_status: CONSUMED ERROR: \
FALL-BACK to default SSL date format"

			cert_date_to_timestamp_s \
				"$cert_not_after_date" cert_expire_date_s

			verbose "\
expire_status: FALL-BACK completed"
		fi
	fi

	# Convert number of days to a timestamp in seconds
	cutoff_date_s=
	days_to_timestamp_s \
		"$EASYRSA_PRE_EXPIRY_WINDOW" cutoff_date_s

	# Get the current date/time as a timestamp in seconds
	now_date_s=
	days_to_timestamp_s \
		0 now_date_s

	# Compare and print output
	if [ "$cert_expire_date_s" -lt "$cutoff_date_s" ]; then
		# Cert expires in less than grace period
		if [ "$will_not_expire" ]; then
			die "\
EasyRSA: will expire - SSL: will NOT expire"
		fi
		if [ "$cert_expire_date_s" -gt "$now_date_s" ]; then
			verbose "expire_status: Valid -> expiring"
			printf '%s%s\n' \
				"$db_status | Serial: $db_serial | " \
				"Expires: $cert_not_after_date | CN: $db_cn"
		else
			verbose "expire_status: Expired"
			printf '%s%s\n' \
				"$db_status | Serial: $db_serial | " \
				"Expired: $cert_not_after_date | CN: $db_cn"
		fi
	else
		if [ "$will_expire" ]; then
			die "\
EasyRSA: will NOT expire - SSL: will expire"
		fi
		verbose "expire_status: Valid -> NOT expiring"
	fi
} # => expire_status()

# Revoke status
revoke_status() {
	# Translate db date to usable date
	cert_revoke_date=
	db_date_to_iso_8601_date "$db_revoke_date" cert_revoke_date

	printf '%s%s%s\n' \
		"$db_status | Serial: $db_serial | " \
		"Revoked: $cert_revoke_date | " \
		"Reason: $db_reason | CN: $db_cn"
} # => revoke_status()

# Renewed status
# renewed certs only remain in the renewed folder until revoked
# Only ONE renewed cert with unique CN can exist in renewed folder
renew_status() {
	# Does a Renewed cert exist ?
	# files in issued are file name, or in serial are SerialNumber
	unset -v cert_file_in cert_is_issued cert_is_serial renew_is_old

	# Find renewed/issued/CN
	if [ -e "$cert_r_issued" ]; then
		cert_file_in="$cert_r_issued"
		cert_is_issued=1
	fi

	# Find renewed/cert_by_serial/SN
	if [ -e "$cert_r_by_sno" ]; then
		cert_file_in="$cert_r_by_sno"
		cert_is_serial=1
		renew_is_old=1
	fi

	# Both should not exist
	if [ "$cert_is_issued" ] && [ "$cert_is_serial" ]; then
		die "Too many certs"
	fi

	# If a renewed cert exists
	if [ "$cert_file_in" ]; then
		# get the serial number of the certificate
		ssl_cert_serial "$cert_file_in" cert_serial

		# db serial must match certificate serial, otherwise
		# this is an issued cert that replaces a renewed cert
		if [ "$db_serial" != "$cert_serial" ]; then
			information "\
serial mismatch:
  db_serial:    $db_serial
  cert_serial:  $cert_serial
  cert_file_in: $cert_file_in"
			return 0
		fi

		# Use cert date
		# Assigns cert_not_after_date
		ssl_cert_not_after_date "$cert_file_in" cert_not_after_date

		# Highlight renewed/cert_by_serial
		if [ "$renew_is_old" ]; then
			printf '%s%s\n' \
				"*** $db_status | Serial: $db_serial | " \
				"Expires: $cert_not_after_date | CN: $db_cn"
		else
			printf '%s%s\n' \
				"$db_status | Serial: $db_serial | " \
				"Expires: $cert_not_after_date | CN: $db_cn"
		fi

	else
		# Cert is valid but not renewed
		: # ok - ignore
	fi
} # => renew_status()

# cert status reports
status() {

	[ "$#" -gt 0 ] || die "status - input error"
	report="$1"
	target="$2"

	verify_ca_init

	# test fix: https://github.com/OpenVPN/easy-rsa/issues/819
	export LC_TIME=C.UTF-8

	# If no target file then add Notice
	if [ -z "$target" ]; then
		# Select correct Notice
		case "$report" in
		expire)
			notice "\
* Showing certificates which expire in less than \
$EASYRSA_PRE_EXPIRY_WINDOW days (--days):"
		;;
		revoke)
			notice "\
* Showing certificates which are revoked:"
		;;
		renew)
			notice "\
* Showing certificates which have been renewed but NOT revoked:

*** Marks those which require 'rewind-renew' \
before they can be revoked."
		;;
		*) warn "Unrecognised report: $report"
		esac
	fi

	# Create report
	read_db

} # => status()

# set_var is not known by shellcheck, therefore:
# Fake declare known variables for shellcheck
# Use these options without this function:
# -o all -e 2250,2244,2248 easyrsa
satisfy_shellcheck() {
	die "Security feature enabled!"
	# Add more as/if required

	# Enable the heredoc for a peek
#cat << SC2154
	EASYRSA=
	EASYRSA_OPENSSL=
	EASYRSA_PKI=
	EASYRSA_DN=
	EASYRSA_REQ_COUNTRY=
	EASYRSA_REQ_PROVINCE=
	EASYRSA_REQ_CITY=
	EASYRSA_REQ_ORG=
	EASYRSA_REQ_EMAIL=
	EASYRSA_REQ_OU=
	EASYRSA_ALGO=
	EASYRSA_KEY_SIZE=
	EASYRSA_CURVE=
	EASYRSA_CA_EXPIRE=
	EASYRSA_CERT_EXPIRE=
	EASYRSA_PRE_EXPIRY_WINDOW=
	EASYRSA_CRL_DAYS=
	EASYRSA_NS_SUPPORT=
	EASYRSA_NS_COMMENT=
	EASYRSA_TEMP_DIR=
	EASYRSA_REQ_CN=
	EASYRSA_DIGEST=

	EASYRSA_SSL_CONF=
	EASYRSA_SAFE_CONF=
	OPENSSL_CONF=

	#EASYRSA_KDC_REALM=

	EASYRSA_RAND_SN=
	KSH_VERSION=
#SC2154

} # => satisfy_shellcheck()

# Identify host OS
detect_host() {
	unset -v easyrsa_ver_test easyrsa_host_os easyrsa_host_test \
			easyrsa_win_git_bash

	# Detect Windows
	[ "${OS}" ] && easyrsa_host_test="${OS}"

	# shellcheck disable=SC2016 # expansion inside '' blah
	easyrsa_ksh=\
'@(#)MIRBSD KSH R39-w32-beta14 $Date: 2013/06/28 21:28:57 $'

	[ "${KSH_VERSION}" = "${easyrsa_ksh}" ] && \
		easyrsa_host_test="${easyrsa_ksh}"
	unset -v easyrsa_ksh

	# If not Windows then nix
	if [ "${easyrsa_host_test}" ]; then
		easyrsa_host_os=win
		easyrsa_uname="${easyrsa_host_test}"
		easyrsa_shell="$SHELL"
		# Detect Windows git/bash
		if [ "${EXEPATH}" ]; then
			easyrsa_shell="$SHELL (Git)"
			easyrsa_win_git_bash="${EXEPATH}"
			# If found then set openssl NOW!
			#[ -e /usr/bin/openssl ] && \
			#	set_var EASYRSA_OPENSSL /usr/bin/openssl
		fi
	else
		easyrsa_host_os=nix
		easyrsa_uname="$(uname 2>/dev/null)"
		easyrsa_shell="${SHELL:-undefined}"
	fi

	easyrsa_ver_test="${EASYRSA_version%%~*}"
	if [ "$easyrsa_ver_test" ]; then
		host_out="Host: $EASYRSA_version"
	else
		host_out="Host: dev"
	fi

	host_out="\
$host_out | $easyrsa_host_os | $easyrsa_uname | $easyrsa_shell"
	host_out="\
${host_out}${easyrsa_win_git_bash+ | "$easyrsa_win_git_bash"}"
	unset -v easyrsa_ver_test easyrsa_host_test
} # => detect_host()

# Extra diagnostics
show_host() {
	[ "$EASYRSA_SILENT" ] && return
	print_version
	print "$host_out"
	[ "$EASYRSA_DEBUG" ] || return 0
	case "$easyrsa_host_os" in
	win) set ;;
	nix) env ;;
	*) print "Unknown host OS: $easyrsa_host_os"
	esac
} # => show_host()

# Verify the selected algorithm parameters
verify_algo_params() {
	# EASYRSA_ALGO_PARAMS must be set depending on selected algo
	case "$EASYRSA_ALGO" in
	rsa)
		# Set RSA key size
		EASYRSA_ALGO_PARAMS="$EASYRSA_KEY_SIZE"
	;;
	ec)
		# Verify Elliptic curve
		EASYRSA_ALGO_PARAMS=""
		easyrsa_mktemp EASYRSA_ALGO_PARAMS || die \
		"verify_algo_params - easyrsa_mktemp EASYRSA_ALGO_PARAMS"

		# Create the required ecparams file
		# call openssl directly because error is expected
		"$EASYRSA_OPENSSL" ecparam -name "$EASYRSA_CURVE" \
			-out "$EASYRSA_ALGO_PARAMS" \
			1>/dev/null || die "\
Failed to generate ecparam file (permissions?) at:
* $EASYRSA_ALGO_PARAMS"
	;;
	ed)
		# Verify Edwards curve
		# call openssl directly because error is expected
		"$EASYRSA_OPENSSL" genpkey \
			-algorithm "$EASYRSA_CURVE" \
			1>/dev/null || die "\
Edwards Curve $EASYRSA_CURVE not found."
	;;
	*) die "\
Alg '$EASYRSA_ALGO' is invalid: Must be 'rsa', 'ec' or 'ed'"
	esac
	verbose "\
verify_algo_params: Params verified for algo '$EASYRSA_ALGO'"
} # => verify_algo_params()

# Check for conflicting input options
mutual_exclusions() {
	# --nopass cannot be used with --passout
	if [ "$EASYRSA_PASSOUT" ]; then
		# --passout MUST take priority over --nopass
		[ "$EASYRSA_NO_PASS" ] && warn "\
Option --passout cannot be used with --nopass|nopass."
		unset -v EASYRSA_NO_PASS
		prohibit_no_pass=1
	fi

	# --silent-ssl requires --batch
	if [ "$EASYRSA_SILENT_SSL" ]; then
		[ "$EASYRSA_BATCH" ] || warn "\
Option --silent-ssl requires batch mode --batch."
	fi

	# --startdate requires --enddate
	# otherwise, --days counts from now
	if [ "$EASYRSA_START_DATE" ]; then
		[ "$EASYRSA_END_DATE" ] || die "\
Use of --startdate requires use of --enddate."
	fi

	# --enddate may over-rule EASYRSA_CERT_EXPIRE
	if [ "$EASYRSA_END_DATE" ]; then
		case "$cmd" in
			sign-req|build-*-full|renew|rebuild)
				# User specified alias_days IS over-ruled
				if [ "$alias_days" ]; then
					warn "\
Option --days is over-ruled by option --enddate."
				fi
				unset -v EASYRSA_CERT_EXPIRE alias_days
			;;
			*)
				warn "\
EasyRSA '$cmd' does not support --startdate or --enddate"
				unset -v EASYRSA_START_DATE EASYRSA_END_DATE
		esac
	fi

	# Insecure Windows directory
	if [ "$easyrsa_host_os" = win ]; then
		if echo "$PWD" | grep -q '/P.*/OpenVPN/easy-rsa'; then
			warn "\
Using Windows-System-Folders for your PKI is NOT SECURE!
Your Easy-RSA PKI CA Private Key is WORLD readable.

To correct this problem, it is recommended that you either:
* Copy Easy-RSA to your User folders and run it from there, OR
* Define your PKI to be in your User folders. EG:
  'easyrsa --pki-dir=\"C:/Users/<your-user-name>/easy-rsa/pki\"\
 <command>'"
		fi
	fi

	# Use of --silent and --verbose
	if [ "$EASYRSA_SILENT" ] && [ "$EASYRSA_VERBOSE" ]; then
		die "Use of --silent and --verbose is unresolvable."
	fi
} # => mutual_exclusions()

# vars setup
# Here sourcing of 'vars' if present occurs.
# If not present, defaults are used to support
# running without a sourced config format
vars_setup() {
	# Try to locate a 'vars' file in order of preference.
	# If one is found then source it.
	# NOTE: EASYRSA_PKI is never set here,
	# unless cmd-line --pki-dir=<DIR> is set.
	# NOTE: EASYRSA is never set here,
	# unless done so outside of easyrsa.
	vars=

	# Find vars
	# Explicit user defined vars file:
	if [ "$EASYRSA_VARS_FILE" ]; then
		if [ -e "$EASYRSA_VARS_FILE" ]; then
			vars="$EASYRSA_VARS_FILE"
			user_vars_true=1
		else
			# If the --vars option does not point to a file
			die "\
The 'vars' file was not found:
* $EASYRSA_VARS_FILE"
		fi

	# Otherwise, find vars
	else

		# set up program path
		prog_file="$0"
		prog_dir="${prog_file%/*}"
		if [ "$prog_dir" = . ] || [ "$prog_dir" = "$PWD" ]
		then
			prog_in_pwd=1
		else
			unset -v prog_in_pwd
		fi

		# Program dir vars - This location is least wanted.
		prog_vars="${prog_dir}/vars"

		# set up PKI path vars - Top preference
		pki_vars="${EASYRSA_PKI:-$PWD/pki}/vars"
		expected_pki_vars="$pki_vars"

		# Some other place vars, out of scope.
		if [ "$EASYRSA" ]; then
			easy_vars="${EASYRSA}/vars"
		else
			unset -v easy_vars
		fi

		# vars of last resort
		pwd_vars="$PWD/vars"

		# Clear flags - This is the preferred order to find:
		unset -v e_pki_vars e_easy_vars e_pwd_vars e_prog_vars \
			found_vars vars_in_pki

		# PKI location, if present:
		[ -e "$pki_vars" ] && e_pki_vars=1

		# EASYRSA, if defined:
		[ -e "$easy_vars" ] && e_easy_vars=1

		# vars of last resort
		[ -e "$pwd_vars" ] && e_pwd_vars=1

		# program location:
		[ -e "$prog_vars" ] && e_prog_vars=1

		# Filter duplicates
		if [ "$e_prog_vars" ] && [ "$e_pwd_vars" ] && \
			[ "$prog_in_pwd" ]
		then
			unset -v prog_vars e_prog_vars
		fi

		# Allow only one vars to be found, No exceptions!
		found_vars="$((
			e_pki_vars + e_easy_vars + e_pwd_vars + e_prog_vars
			))"

		# If found_vars greater than 1
		# then output user info and exit
		case "$found_vars" in
			0) unset -v found_vars ;;
			1)
				# If a SINGLE vars file is found
				# then assign $vars
				[ "$e_prog_vars" ] && vars="$prog_vars"
				[ "$e_pwd_vars" ] && vars="$pwd_vars"
				[ "$e_easy_vars" ] && vars="$easy_vars"
				[ "$e_pki_vars" ] && \
					vars="$pki_vars" && vars_in_pki=1
				: # Wipe error status
			;;
			*)
				# For init-pki, skip this check
				if [ "$pki_is_required" ]; then
					[ "$e_pki_vars" ] && print "Found: $pki_vars"
					[ "$e_easy_vars" ] && print "Found: $easy_vars"
					[ "$e_pwd_vars" ] && print "Found: $pwd_vars"
					[ "$e_prog_vars" ] && print "Found: $prog_vars"
					die "\
Conflicting 'vars' files found.

Priority should be given to your PKI vars file:
* $expected_pki_vars"
				fi

				# For init-pki, pki/vars will be deleted
				# Another vars file exists
				# so don't create pki/vars
				no_new_vars=1
		esac

		# Clean up
		unset -v prog_vars pwd_vars easy_vars pki_vars \
				expected_pki_vars
	# END: Find vars
	fi

	# If EASYRSA_NO_VARS is defined then do not use vars
	# If no_pki_required then located vars files are not
	# required
	if [ "$EASYRSA_NO_VARS" ] || [ "$no_pki_required" ]; then
		: # ok

	# If a vars file was located then source it
	else
		# $vars remains undefined .. no vars found
		# 'install_data_to_pki vars-setup' will NOT
		# create a default PKI/vars
		if [ -z "$vars" ]; then
			information \
				"No Easy-RSA 'vars' configuration file exists!"
			no_new_vars=1

		else
			# 'vars' now MUST exist
			[ -e "$vars" ] || die "\
Missing vars file:
* $vars"

			# Installation information
			information "\
Using Easy-RSA configuration:
  $vars"

			# Sanitize vars
			if grep -q \
				-e 'EASYRSA_PASSIN' -e 'EASYRSA_PASSOUT' \
				-e '[^(]`[^)]' \
				"$vars"
			then
				die "\
One or more of these problems has been found in your 'vars' file:

* Use of 'EASYRSA_PASSIN' or 'EASYRSA_PASSOUT':
  Storing password information in the 'vars' file is not permitted.

* Use of unsupported characters:
  These characters are not supported: \` backtick

Please, correct these errors and try again."
			fi

			if grep -q \
				-e '[[:blank:]]export[[:blank:]]' \
				-e '[[:blank:]]unset[[:blank:]]' \
				"$vars"
			then
				warn "\
One or more of these problems has been found in your 'vars' file:

* Use of 'export':
  Remove 'export' or replace it with 'set_var'.

* Use of 'unset':
  Remove 'unset' ('force_set_var' may also work)."
			fi

			# Enable sourcing 'vars'
			# shellcheck disable=SC2034 # appears unused
			EASYRSA_CALLER=1

			# Test souring 'vars' in a subshell
			# shellcheck disable=1090 # can't follow .. vars
			( . "$vars" ) || \
				die "Failed to source the vars file."

			# Source 'vars' now
			# shellcheck disable=1090 # can't follow .. vars
			. "$vars" 2>/dev/null
			unset -v EASYRSA_CALLER
		fi
	fi

	# Set defaults, preferring existing env-vars if present
	set_var EASYRSA					"$PWD"
	set_var EASYRSA_OPENSSL			openssl
	set_var EASYRSA_PKI				"$EASYRSA/pki"
	set_var EASYRSA_DN				cn_only
	set_var EASYRSA_REQ_COUNTRY		"US"
	set_var EASYRSA_REQ_PROVINCE	"California"
	set_var EASYRSA_REQ_CITY		"San Francisco"
	set_var EASYRSA_REQ_ORG			"Copyleft Certificate Co"
	set_var EASYRSA_REQ_EMAIL		me@example.net
	set_var EASYRSA_REQ_OU			"My Organizational Unit"
	set_var EASYRSA_REQ_SERIAL		""
	set_var EASYRSA_ALGO			rsa
	set_var EASYRSA_KEY_SIZE		2048

	case "$EASYRSA_ALGO" in
	rsa)
		: # ok
		# default EASYRSA_KEY_SIZE must always be set
		# it must NOT be set selectively because it is
		# present in the SSL config file
	;;
	ec)
		set_var EASYRSA_CURVE		secp384r1
	;;
	ed)
		set_var EASYRSA_CURVE		ed25519
	;;
	*) die "Unknown algorithm '$EASYRSA_ALGO'"
	esac

	set_var EASYRSA_CA_EXPIRE		3650
	set_var EASYRSA_CERT_EXPIRE		825
	set_var \
		EASYRSA_PRE_EXPIRY_WINDOW	90
	set_var EASYRSA_CRL_DAYS		180
	set_var EASYRSA_NS_SUPPORT		no
	set_var EASYRSA_NS_COMMENT		\
		"Easy-RSA (~VER~) Generated Certificate"
	set_var EASYRSA_TEMP_DIR		"$EASYRSA_PKI"
	set_var EASYRSA_REQ_CN			ChangeMe
	set_var EASYRSA_DIGEST			sha256

	set_var EASYRSA_SSL_CONF		"$EASYRSA_PKI/openssl-easyrsa.cnf"
	set_var EASYRSA_SAFE_CONF		"$EASYRSA_PKI/safessl-easyrsa.cnf"

	set_var EASYRSA_KDC_REALM		"CHANGEME.EXAMPLE.COM"
} # => vars_setup()

# Verify working environment
verify_working_env() {
	# Verify SSL Lib - One time ONLY
	verify_ssl_lib

	# Find x509-types but do not fail
	# Not fatal here, used by 'help'
	install_data_to_pki x509-types-only

	# For commands which 'require a PKI' and PKI exists
	if  [ "$pki_is_required" ] && [ -d "$EASYRSA_PKI" ]
	then

		# Temp dir MUST exist
		if [ -d "$EASYRSA_TEMP_DIR" ]; then

			# Temp dir session
			secure_session || \
				die "\
verify_working_env - secure-session failed"

			# Install data-files into ALL PKIs
			# This will find x509-types
			# and export EASYRSA_EXT_DIR or die.
			# Other errors only require warning.
			install_data_to_pki vars-setup || \
				warn "\
verify_working_env - install_data_to_pki vars-setup failed"

			# if the vars file in use is not in the PKI
			# and not user defined then Show the messages
			if [ "$vars_in_pki" ] || [ "$user_vars_true" ] || \
				[ "$no_new_vars" ]
			then
				: # ok - No message required
			else
				prefer_vars_in_pki_msg
			fi

			# Verify selected algorithm and parameters
			verify_algo_params

			# Check $working_safe_ssl_conf, to build
			# a fully configured safe ssl conf, on the
			# next invocation of easyrsa_openssl()
			[ -z "$working_safe_ssl_conf" ] || {
				die "working_safe_ssl_conf must not be set!"
			}

			# Last setup msg
			information "\
Using SSL: $EASYRSA_OPENSSL $ssl_version
"
		else
			# The directory does not exist
			die "\
Temporary directory does not exist:
* $EASYRSA_TEMP_DIR"
		fi
	fi
} # => verify_working_env()

# variable assignment by indirection when undefined; merely exports
# the variable when it is already defined (even if currently null)
# Sets $1 as the value contained in $2 and exports (may be blank)
set_var() {
	[ "$1" ] || die "set_var - missing input"
	[ "$1" = "${1% *}" ] || die "set_var - input error"
	[ "$#" -lt 3 ] || die "set_var - excess input"
	eval "export \"$1\"=\"\${$1-$2}\""
} #=> set_var()

# sanatize and set var
force_set_var() {
	[ "$#" = 2 ] || die "force_set_var - input"
	unset -v "$1" || die "force_set_var - unset"
	set_var "$1" "$2" || die "force_set_var - set_var"
} # => force_set_var()



############################################################################
# Upgrade v2 PKI to v3 PKI

# You can report problems on the normal openvpn support channels:
# --------------------------------------------------------------------------
#   1. The Openvpn Forum: https://forums.openvpn.net/viewforum.php?f=31
#   2. The #easyrsa IRC channel at libera.chat
#   3. Info: https://community.openvpn.net/openvpn/wiki/easyrsa-upgrade
# --------------------------------------------------------------------------
#

up23_fail_upgrade ()
{
	# Replace die()
	unset -v EASYRSA_BATCH
	notice "
============================================================================
The update has failed but NOTHING has been lost.

ERROR: $1
----------------------------------------------------------------------------

Further info:
* https://community.openvpn.net/openvpn/wiki/easyrsa-upgrade#ersa-up23-fails

Easyrsa3 upgrade FAILED
============================================================================
"
	exit 9
} #=> up23_fail_upgrade ()

up23_verbose ()
{
	[ "$VERBOSE" ] || return 0
	printf "%s\n" "$1"
} #=> up23_verbose ()

up23_verify_new_pki ()
{
	# Fail now, before any changes are made

	up23_verbose "> Verify DEFAULT NEW PKI does not exist .."
	EASYRSA_NEW_PKI="$EASYRSA/pki"
	[ -d "$EASYRSA_NEW_PKI" ] \
	&& up23_fail_upgrade "DEFAULT NEW PKI exists: $EASYRSA_NEW_PKI"

	up23_verbose "> Verify VERY-SAFE-PKI does not exist .."
	EASYRSA_SAFE_PKI="$EASYRSA/VERY-SAFE-PKI"
	[ -d "$EASYRSA_SAFE_PKI" ] \
	&& up23_fail_upgrade "VERY-SAFE-PKI exists: $EASYRSA_SAFE_PKI"

	up23_verbose "> Verify openssl-easyrsa.cnf does exist .."
	EASYRSA_SSL_CNFFILE="$EASYRSA/openssl-easyrsa.cnf"
	[ -f "$EASYRSA_SSL_CNFFILE" ] \
	|| up23_fail_upgrade "cannot find $EASYRSA_SSL_CNFFILE"

	up23_verbose "> Verify vars.example does exist .."
	EASYRSA_VARSV3_EXMP="$EASYRSA/vars.example"
	[ -f "$EASYRSA_VARSV3_EXMP" ] \
	|| up23_fail_upgrade "cannot find $EASYRSA_VARSV3_EXMP"

	up23_verbose "> OK"
	up23_verbose "  Initial dirs & files are in a workable state."
} #=> up23_verify_new_pki ()

# shellcheck disable=SC2154
up23_verify_current_pki ()
{
	up23_verbose "> Verify CURRENT PKI vars .."

	# This can probably be improved
	EASYRSA_NO_REM="$(grep '^set ' "$EASYRSA_VER2_VARSFILE")"

	# This list may not be complete
	# Not required: DH_KEY_SIZE PKCS11_MODULE_PATH PKCS11_PIN
	for i in KEY_DIR KEY_SIZE KEY_COUNTRY KEY_PROVINCE \
	KEY_CITY KEY_ORG KEY_EMAIL KEY_CN KEY_NAME KEY_OU
	do
		# Effectively, source the v2 vars file
		UNIQUE="set $i"
		KEY_grep="$(printf "%s\n" "$EASYRSA_NO_REM" | grep "$UNIQUE")"
		KEY_value="${KEY_grep##*=}"
		set_var $i "$KEY_value"
	done

	[ -d "$KEY_DIR" ] || up23_fail_upgrade "Cannot find CURRENT PKI KEY_DIR: $KEY_DIR"

	up23_verbose "> OK"
	up23_verbose "  Current CURRENT PKI vars uses PKI in: $KEY_DIR"
} #=> up23_verify_current_pki ()

# shellcheck disable=SC2154
up23_verify_current_ca ()
{
	up23_verbose "> Find CA .."
	# $KEY_DIR is assigned in up23_verify_current_pki ()
	[ -f "$KEY_DIR/ca.crt" ] \
	|| up23_fail_upgrade "Cannot find current ca.crt: $KEY_DIR/ca.crt"
	up23_verbose "> OK"

	# If CA is already verified then return
	in_file="$KEY_DIR/ca.crt"
	[ "$CURRENT_CA_IS_VERIFIED" = "$in_file" ] && return 0
	format="x509"

	# Current CA is unverified
	# Extract the current CA details
	name_opts="utf8,sep_multiline,space_eq,lname,align"
	CA_SUBJECT="$(
		easyrsa_openssl $format -in "$in_file" -subject -noout \
			-nameopt "$name_opts"
		)"

	# Extract individual elements
	CA_countryName="$(printf "%s\n" "$CA_SUBJECT" \
	| grep countryName | sed "s\`^.*=\ \`\`g")"
	CA_stateOrProvinceName="$(printf "%s\n" "$CA_SUBJECT" \
	| grep stateOrProvinceName | sed "s\`^.*=\ \`\`g")"
	CA_localityName="$(printf "%s\n" "$CA_SUBJECT" \
	| grep localityName | sed "s\`^.*=\ \`\`g")"
	CA_organizationName="$(printf "%s\n" "$CA_SUBJECT" \
	| grep organizationName | sed "s\`^.*=\ \`\`g")"
	CA_organizationalUnitName="$(printf "%s\n" "$CA_SUBJECT" \
	| grep organizationalUnitName | sed "s\`^.*=\ \`\`g")"
	CA_emailAddress="$(printf "%s\n" "$CA_SUBJECT" \
	| grep emailAddress | sed "s\`^.*=\ \`\`g")"

	# Match the current CA elements to the vars file settings
	CA_vars_match=1
	[ "$CA_countryName" = "$KEY_COUNTRY" ] || CA_vars_match=0
	[ "$CA_stateOrProvinceName" = "$KEY_PROVINCE" ] || CA_vars_match=0
	[ "$CA_localityName" = "$KEY_CITY" ] || CA_vars_match=0
	[ "$CA_organizationName" = "$KEY_ORG" ] || CA_vars_match=0
	[ "$CA_organizationalUnitName" = "$KEY_OU" ] || CA_vars_match=0
	[ "$CA_emailAddress" = "$KEY_EMAIL" ] || CA_vars_match=0

	if [ "$CA_vars_match" -eq 1 ]
	then
		CURRENT_CA_IS_VERIFIED="partially"
	else
		warn "CA certificate does not match vars file settings"
	fi

	opts="-certopt no_pubkey,no_sigdump"
	if [ ! "$EASYRSA_BATCH" ]
	then
		up23_show_current_ca
	elif [ "$VERBOSE" ]
	then
		up23_show_current_ca
	fi
	confirm "* Confirm CA shown above is correct: " "yes" \
	"Found current CA at: $KEY_DIR/ca.crt"
	CURRENT_CA_IS_VERIFIED="$in_file"
} #=> up23_verify_current_ca ()

up23_show_current_ca ()
{
	name_opts="utf8,sep_multiline,space_eq,lname,align"
	printf "%s\n" "-------------------------------------------------------------------------"
	# $opts is always set here
	# shellcheck disable=SC2086 # Ignore unquoted variables
	easyrsa_openssl $format -in "$in_file" -noout -text \
		-nameopt "$name_opts" $opts || die "\
	OpenSSL failure to process the input CA certificate: $in_file"
	printf "%s\n" "-------------------------------------------------------------------------"
} #=> up23_show_current_ca ()

up23_backup_current_pki ()
{
	up23_verbose "> Backup current PKI .."

	mkdir -p "$EASYRSA_SAFE_PKI" \
	|| up23_fail_upgrade "Failed to create safe PKI dir: $EASYRSA_SAFE_PKI"

	cp -r "$KEY_DIR" "$EASYRSA_SAFE_PKI" \
	|| up23_fail_upgrade "Failed to copy $KEY_DIR to $EASYRSA_SAFE_PKI"

	# EASYRSA_VER2_VARSFILE is either version 2 *nix ./vars or Win vars.bat
	cp "$EASYRSA_VER2_VARSFILE" "$EASYRSA_SAFE_PKI" \
	|| up23_fail_upgrade "Failed to copy $EASYRSA_VER2_VARSFILE to EASYRSA_SAFE_PKI"

	up23_verbose "> OK"
	up23_verbose "  Current PKI backup created in: $EASYRSA_SAFE_PKI"
} #=> up23_backup_current_pki ()

up23_create_new_pki ()
{
	# Dirs: renewed and revoked are created when used.
	up23_verbose "> Create NEW PKI .."
	up23_verbose ">> Create NEW PKI dirs .."
	for i in private reqs issued certs_by_serial
	do
		mkdir -p "$EASYRSA_PKI/$i" \
		|| up23_fail_upgrade "Failed to Create NEW PKI dir: $EASYRSA_PKI/$i"
	done
	up23_verbose ">> OK"

	up23_verbose ">> Copy database to NEW PKI .."
	# Failure for these is not optional
	# Files ignored: index.txt.old serial.old
	for i in index.txt serial ca.crt index.txt.attr
	do
		cp "$KEY_DIR/$i" "$EASYRSA_PKI" \
		|| up23_fail_upgrade "Failed to copy $KEY_DIR/$i to $EASYRSA_PKI"
	done
	up23_verbose ">> OK"

	up23_verbose ">> Copy current PKI to NEW PKI .."
	for i in "csr.reqs" "pem.certs_by_serial" "crt.issued" "key.private" \
	"p12.private" "p8.private" "p7b.issued"
	do
		FILE_EXT="${i%%.*}"
		DEST_DIR="${i##*.}"
		if ls "$KEY_DIR/"*".$FILE_EXT" > /dev/null 2>&1; then
			cp "$KEY_DIR/"*".$FILE_EXT" "$EASYRSA_PKI/$DEST_DIR" \
			|| up23_fail_upgrade "Failed to copy .$FILE_EXT"
		else
			up23_verbose "   Note: No .$FILE_EXT files found"
		fi
	done
	up23_verbose ">> OK"
	up23_verbose "> OK"

	# Todo: CRL - Or generate a new CRL on completion
	up23_verbose "  New PKI created in: $EASYRSA_PKI"
} #=> up23_create_new_pki ()

up23_upgrade_ca ()
{
	[ -d "$EASYRSA_PKI" ] || return 0
	up23_verbose "> Confirm that index.txt.attr exists and 'unique_subject = no'"
	if [ -f "$EASYRSA_PKI/index.txt.attr" ]
	then
		if grep -q 'unique_subject = no' "$EASYRSA_PKI/index.txt.attr"
		then
			# If index.txt.attr exists and "unique_suject = no" then do nothing
			return 0
		fi
	else
		# If index.txt.attr does not exists then do nothing
		return 0
	fi

	# Otherwise this is required for all easyrsa v3
	#confirm "Set 'unique_subject = no' in index.txt.attr for your current CA: " \
	#"yes" "This version of easyrsa requires that 'unique_subject = no' is set correctly"

	printf "%s\n" "unique_subject = no" > "$EASYRSA_PKI/index.txt.attr"
	up23_verbose "> OK"
	up23_verbose "  Upgraded index.txt.attr to v306+"
} #=> up23_upgrade_index_txt_attr ()

up23_create_openssl_cnf ()
{
	up23_verbose "> OpenSSL config .."
	EASYRSA_PKI_SSL_CNFFILE="$EASYRSA_PKI/openssl-easyrsa.cnf"
	EASYRSA_PKI_SAFE_CNFFILE="$EASYRSA_PKI/safessl-easyrsa.cnf"
	cp "$EASYRSA_SSL_CNFFILE" "$EASYRSA_PKI_SSL_CNFFILE" \
	|| up23_fail_upgrade "create $EASYRSA_PKI_SSL_CNFFILE"
	up23_verbose "> OK"
	up23_verbose "  New OpenSSL config file created in: $EASYRSA_PKI_SSL_CNFFILE"

	# Create secure session
	# Because the upgrade runs twice, once as a test and then for real
	# secured_session must be cleared to avoid overload error
	#[ "$secured_session" ] && unset -v secured_session
	#up23_verbose "> Create secure session"
	#secure_session || die "up23_create_openssl_cnf - secure_session failed."
	#up23_verbose "> OK"
	#up23_verbose "  secure session: $secured_session"

	# Create $EASYRSA_PKI/safessl-easyrsa.cnf
	easyrsa_openssl makesafeconf
	if [ -f "$EASYRSA_PKI_SAFE_CNFFILE" ]
	then
		up23_verbose "  New SafeSSL config file created in: $EASYRSA_PKI_SAFE_CNFFILE"
	else
		up23_verbose "  FAILED to create New SafeSSL config file in: $EASYRSA_PKI_SAFE_CNFFILE"
	fi
} #=> up23_create_openssl_cnf ()

up23_move_easyrsa2_programs ()
{
	# These files may not exist here
	up23_verbose "> Move easyrsa2 programs to SAFE PKI .."
	for i in build-ca build-dh build-inter build-key build-key-pass \
	build-key-pkcs12 build-key-server build-req build-req-pass \
	clean-all inherit-inter list-crl pkitool revoke-full sign-req \
	whichopensslcnf build-ca-pass build-key-server-pass init-config \
	make-crl revoke-crt openssl-0.9.6.cnf openssl-0.9.8.cnf \
	openssl-1.0.0.cnf openssl.cnf README.txt index.txt.start \
	vars.bat.sample serial.start
	do
		# Although unlikely, both files could exist
		# EG: ./build-ca and ./build-ca.bat
		NIX_FILE="$EASYRSA/$i"
		WIN_FILE="$EASYRSA/$i.bat"
		if [ -f "$NIX_FILE" ]
		then
			cp "$NIX_FILE" "$EASYRSA_SAFE_PKI" \
			|| up23_fail_upgrade "copy $NIX_FILE $EASYRSA_SAFE_PKI"
		fi

		if [ -f "$WIN_FILE" ]
		then
			cp "$WIN_FILE" "$EASYRSA_SAFE_PKI" \
			|| up23_fail_upgrade "copy $WIN_FILE $EASYRSA_SAFE_PKI"
		fi

		if [ ! -f "$NIX_FILE" ] && [ ! -f "$WIN_FILE" ]
		then
			up23_verbose "File does not exist, ignoring: $i(.bat)"
		fi

	# These files are not removed on TEST run
	[ "$NOSAVE" -eq 1  ] && rm -f "$NIX_FILE" "$WIN_FILE"
	done

	up23_verbose "> OK"
	up23_verbose "  Easyrsa2 programs successfully moved to: $EASYRSA_SAFE_PKI"
} #=> up23_move_easyrsa2_programs ()

# shellcheck disable=SC2154
up23_build_v3_vars ()
{
	up23_verbose "> Build v3 vars file .."

	EASYRSA_EXT="easyrsa-upgrade-23"
	EASYRSA_VARSV2_TMP="$EASYRSA/vars-v2.tmp.$EASYRSA_EXT"
	rm -f "$EASYRSA_VARSV2_TMP"
	EASYRSA_VARSV3_TMP="$EASYRSA/vars-v3.tmp.$EASYRSA_EXT"
	rm -f "$EASYRSA_VARSV3_TMP"
	EASYRSA_VARSV3_NEW="$EASYRSA/vars-v3.new.$EASYRSA_EXT"
	rm -f "$EASYRSA_VARSV3_NEW"
	EASYRSA_VARSV3_WRN="$EASYRSA/vars-v3.wrn.$EASYRSA_EXT"
	rm -f "$EASYRSA_VARSV3_WRN"

	printf "%s\n" "\
########################++++++++++#########################
###                                                     ###
###  WARNING: THIS FILE WAS AUTOMATICALLY GENERATED     ###
###           ALL SETTINGS ARE AT THE END OF THE FILE   ###
###                                                     ###
########################++++++++++#########################

" > "$EASYRSA_VARSV3_WRN" || up23_fail_upgrade "Failed to create $EASYRSA_VARSV3_WRN"

	# Create vars v3 temp file from sourced vars v2 key variables
	{
		printf "%s\n" "set_var EASYRSA_KEY_SIZE $KEY_SIZE"
		printf "%s\n" "set_var EASYRSA_REQ_COUNTRY \"$KEY_COUNTRY\""
		printf "%s\n" "set_var EASYRSA_REQ_PROVINCE \"$KEY_PROVINCE\""
		printf "%s\n" "set_var EASYRSA_REQ_CITY \"$KEY_CITY\""
		printf "%s\n" "set_var EASYRSA_REQ_ORG \"$KEY_ORG\""
		printf "%s\n" "set_var EASYRSA_REQ_EMAIL \"$KEY_EMAIL\""
		printf "%s\n" "set_var EASYRSA_REQ_OU \"$KEY_OU\""
		printf "%s\n" 'set_var EASYRSA_NS_SUPPORT "yes"'
		printf "%s\n" 'set_var EASYRSA_DN "org"'
		printf "%s\n" 'set_var EASYRSA_RAND_SN "no"'
		printf "%s\n" ""
	} > "$EASYRSA_VARSV3_TMP" \
	|| up23_fail_upgrade "Failed to create $EASYRSA_VARSV3_TMP"

	# cat temp files into new v3 vars
	cat "$EASYRSA_VARSV3_WRN" "$EASYRSA_VARSV3_EXMP" "$EASYRSA_VARSV3_TMP" \
	> "$EASYRSA_VARSV3_NEW" \
	|| up23_fail_upgrade "Failed to create $EASYRSA_VARSV3_NEW"

	# This file must be created and restored at the end of TEST
	# for the REAL update to to succeed
	EASYRSA_VARS_LIVEBKP="$EASYRSA_TARGET_VARSFILE.livebackup"
	cp "$EASYRSA_VER2_VARSFILE" "$EASYRSA_VARS_LIVEBKP" \
	|| up23_fail_upgrade "Failed to create $EASYRSA_VARS_LIVEBKP"
	rm -f "$EASYRSA_VER2_VARSFILE"

	# "$EASYRSA_TARGET_VARSFILE" is always $EASYRSA/vars
	cp "$EASYRSA_VARSV3_NEW" "$EASYRSA_TARGET_VARSFILE" \
	|| up23_fail_upgrade "copy $EASYRSA_VARSV3_NEW to $EASYRSA_TARGET_VARSFILE"

	# Delete temp files
	rm -f "$EASYRSA_VARSV2_TMP" "$EASYRSA_VARSV3_TMP" \
	"$EASYRSA_VARSV3_NEW" "$EASYRSA_VARSV3_WRN"

	up23_verbose "> OK"
	up23_verbose "  New v3 vars file created in: $EASYRSA_TARGET_VARSFILE"
} #=> up23_build_v3_vars ()

# shellcheck disable=SC2154
up23_do_upgrade_23 ()
{
	up23_verbose "============================================================================"
	up23_verbose "Begin ** $1 ** upgrade process .."
	up23_verbose ""
	up23_verbose "Easyrsa upgrade version: $EASYRSA_UPGRADE_23"
	up23_verbose ""

	up23_verify_new_pki
	up23_create_new_pki
	up23_create_openssl_cnf
	up23_verify_current_pki
	up23_verify_current_ca
	up23_backup_current_pki
	up23_upgrade_ca
	up23_move_easyrsa2_programs
	up23_build_v3_vars

	if [ "$NOSAVE" -eq 0 ]
	then
		# Must stay in this order
		# New created dirs: EASYRSA_NEW_PKI and EASYRSA_SAFE_PKI
		rm -rf "$EASYRSA_NEW_PKI"
		rm -rf "$EASYRSA_SAFE_PKI"
		# EASYRSA_TARGET_VARSFILE is always the new created v3 vars
		# Need to know if this fails
		rm "$EASYRSA_TARGET_VARSFILE" \
		|| up23_fail_upgrade "remove new vars file: $EASYRSA_TARGET_VARSFILE"
		# EASYRSA_VER2_VARSFILE is either v2 *nix ./vars or Win vars.bat
		# Need this dance because v2 vars is same name as v3 vars above
		cp "$EASYRSA_VARS_LIVEBKP" "$EASYRSA_VER2_VARSFILE"
	fi
	rm -f "$EASYRSA_VARS_LIVEBKP"
} #= up23_do_upgrade_23 ()

up23_manage_upgrade_23 ()
{
	EASYRSA_UPGRADE_VERSION="v1.0a (2020/01/08)"
	EASYRSA_UPGRADE_TYPE="$1"
	EASYRSA_FOUND_VARS=0

	# Verify all existing versions of vars/vars.bat
	if [ -f "$vars" ]
	then
		if grep -q 'Complain if a user tries to do this:' "$vars"
		then
			EASYRSA_FOUND_VARS=1
			EASYRSA_VARS_IS_VER3=1
		fi

		# Easyrsa v3 does not use NOR allow use of `export`.
		if grep -q 'export' "$vars"
		then
			EASYRSA_FOUND_VARS=1
			EASYRSA_VARS_IS_VER2=1
			EASYRSA_VER2_VARSFILE="$vars"
			EASYRSA_TARGET_VARSFILE="$vars"
		fi
	fi

	if [ -f "$EASYRSA/vars.bat" ]
	then
		EASYRSA_FOUND_VARS=1
		EASYRSA_VARS_IS_WIN2=1
		EASYRSA_VER2_VARSFILE="$EASYRSA/vars.bat"
		EASYRSA_TARGET_VARSFILE="$EASYRSA/vars"
	fi

	if [ $EASYRSA_FOUND_VARS -ne 1 ];
	then
		die "vars file not found"
	fi

	# Only allow specific vars/vars.bat to exist
	if [ "$EASYRSA_VARS_IS_VER3" ] && [ "$EASYRSA_VARS_IS_VER2" ]
	then
		die "Verify your current vars file, v3 cannot use 'export'."
	fi

	if [ "$EASYRSA_VARS_IS_VER3" ] && [ "$EASYRSA_VARS_IS_WIN2" ]
	then
		die "Verify your current vars/vars.bat file, cannot have both."
	fi

	if [ "$EASYRSA_VARS_IS_VER2" ] && [ "$EASYRSA_VARS_IS_WIN2" ]
	then
		die "Verify your current vars/vars.bat file, cannot have both."
	fi

	# Die on invalid upgrade type or environment
	if [ "$EASYRSA_UPGRADE_TYPE" = "ca" ]
	then
		if [ "$EASYRSA_VARS_IS_VER3" ]
		then
			# v3 ensure index.txt.attr "unique_subject = no"
			up23_upgrade_ca
			unset -v EASYRSA_BATCH
			notice "Your CA is fully up to date."
			return 0
		else
			die "Only v3 PKI CA can be upgraded."
		fi
	fi

	if [ "$EASYRSA_UPGRADE_TYPE" = "pki" ]
	then
		if [ "$EASYRSA_VARS_IS_VER3" ]
		then
			unset -v EASYRSA_BATCH
			notice "Your PKI is fully up to date."
			return 0
		fi
	else
		die "upgrade type must be 'pki' or 'ca'."
	fi

	# PKI is potentially suitable for upgrade

	warn "
=========================================================================

                           * WARNING *

Found settings from EasyRSA-v2 which are not compatible with EasyRSA-v3.
Before you can continue, EasyRSA must upgrade your settings and PKI.
* Found EASYRSA and vars file:
  $EASYRSA
  $EASYRSA_VER2_VARSFILE :

Further info:
* https://community.openvpn.net/openvpn/wiki/easyrsa-upgrade

Easyrsa upgrade version: $EASYRSA_UPGRADE_VERSION
=========================================================================
"

# Test upgrade

	NOSAVE=0

	confirm "* EasyRSA **TEST** upgrade (Changes will NOT be written): " "yes" "
This upgrade will TEST that the upgrade works BEFORE making any changes."

	up23_do_upgrade_23 "TEST"

	notice "
=========================================================================

                             * NOTICE *

EasyRSA upgrade **TEST** has successfully completed.
"
# Upgrade for REAL

	NOSAVE=1

	confirm "* EasyRSA **REAL** upgrade (Changes WILL be written): " "yes" "
=========================================================================

                             * WARNING *

Run REAL upgrade: Answer yes (Once completed you will have a version 3 PKI)
Terminate upgrade: Answer no (No changes have been made to your current PKI)
"

	confirm "* Confirm **REAL** upgrade (Changes will be written): " "yes" "
=========================================================================

                          * SECOND WARNING *

This upgrade will permanently write changes to your PKI !
(With full backup backout)
"
	up23_do_upgrade_23 "REAL"

	notice "
=========================================================================

                             * NOTICE *

Your settings and PKI have been successfully upgraded to EasyRSA version3

A backup of your current PKI is here:
  $EASYRSA_SAFE_PKI

                        * IMPORTANT NOTICE *

1. YOU MUST VERIFY THAT YOUR NEW ./vars FILE IS SETUP CORRECTLY
2. IF YOU ARE USING WINDOWS YOU MUST ENSURE THAT openssl IS CORRECTLY DEFINED
   IN ./vars (example follows)

 #
 # This sample is in Windows syntax -- edit it for your path if not using PATH:
 # set_var EASYRSA_OPENSSL   \"C:/Program Files/OpenSSL-Win32/bin/openssl.exe\"
 #
 # Alternate location (Note: Forward slash '/' is correct for Windpws):
 # set_var EASYRSA_OPENSSL   \"C:/Program Files/Openvpn/bin/openssl.exe\"
 #

3. Finally, you can verify that easyrsa works by using these two commands:
    ./easyrsa show-ca (Verify that your CA is intact and correct)
    ./easyrsa gen-crl ((re)-generate a CRL file)

Further info:
* https://community.openvpn.net/openvpn/wiki/easyrsa-upgrade"
          up23_verbose "
                   * UPGRADE COMPLETED SUCCESSFULLY *
"

return 0

} # => up23_manage_upgrade_23 ()

print_version()
{
	ssl_version="$("${EASYRSA_OPENSSL:-openssl}" version 2>/dev/null)"
		cat << VERSION_TEXT
EasyRSA Version Information
Version:     $EASYRSA_version
Generated:   ~DATE~
SSL Lib:     ${ssl_version:-undefined}
Git Commit:  ~GITHEAD~
Source Repo: https://github.com/OpenVPN/easy-rsa
VERSION_TEXT
} # => print_version ()


########################################
# Invocation entry point:

EASYRSA_version="~VER~"
NL='
'

# Be secure with a restrictive umask
[ "$EASYRSA_NO_UMASK" ] || umask "${EASYRSA_UMASK:=077}"

# Register cleanup on EXIT
trap 'cleanup $?' EXIT
# When SIGHUP, SIGINT, SIGQUIT, SIGABRT and SIGTERM,
# explicitly exit to signal EXIT (non-bash shells)
trap "exit 1" 1
trap "exit 2" 2
trap "exit 3" 3
trap "exit 6" 6
trap "exit 14" 15

# Get host details - No configurable input allowed
detect_host

# Initialisation requirements
unset -v \
	easyrsa_error_exit \
	prohibit_no_pass \
	secured_session \
	working_safe_ssl_conf \
	user_vars_true \
	user_san_true \
	alias_days

	# Used by build-ca->cleanup to restore prompt
	# after user interrupt when using manual password
	prompt_restore=0

# Parse options
while :; do
	# Reset per pass flags
	unset -v opt val \
		is_empty empty_ok number_only zero_allowed

	# Separate option from value:
	opt="${1%%=*}"
	val="${1#*=}"

	# Empty values are not allowed unless expected
	# eg: '--batch'
	[ "$opt" = "$val" ] && is_empty=1
	# eg: '--pki-dir='
	[ "$val" ] || is_empty=1

	case "$opt" in
	--days)
		number_only=1
		# Set the appropriate date variable
		# when called by command later
		alias_days="$val"
		;;
	--startdate)
		export EASYRSA_START_DATE="$val"
		;;
	--enddate)
		export EASYRSA_END_DATE="$val"
		;;
	--pki-dir)
		export EASYRSA_PKI="$val"
		;;
	--tmp-dir)
		export EASYRSA_TEMP_DIR="$val"
		;;
	--ssl-conf)
		export EASYRSA_SSL_CONF="$val"
		;;
	--keep-tmp)
		export EASYRSA_KEEP_TEMP="$val"
		;;
	--use-algo)
		export EASYRSA_ALGO="$val"
		;;
	--keysize)
		number_only=1
		export EASYRSA_KEY_SIZE="$val"
		;;
	--curve)
		export EASYRSA_CURVE="$val"
		;;
	--dn-mode)
		export EASYRSA_DN="$val"
		;;
	--req-cn)
		export EASYRSA_REQ_CN="$val"
		;;
	--digest)
		export EASYRSA_DIGEST="$val"
		;;
	--req-c)
		empty_ok=1
		export EASYRSA_REQ_COUNTRY="$val"
		;;
	--req-st)
		empty_ok=1
		export EASYRSA_REQ_PROVINCE="$val"
		;;
	--req-city)
		empty_ok=1
		export EASYRSA_REQ_CITY="$val"
		;;
	--req-org)
		empty_ok=1
		export EASYRSA_REQ_ORG="$val"
		;;
	--req-email)
		empty_ok=1
		export EASYRSA_REQ_EMAIL="$val"
		;;
	--req-ou)
		empty_ok=1
		export EASYRSA_REQ_OU="$val"
		;;
	--req-serial)
		empty_ok=1
		export EASYRSA_REQ_SERIAL="$val"
		;;
	--ns-cert)
		empty_ok=1
		[ "$is_empty" ] && unset -v val
		export EASYRSA_NS_SUPPORT="${val:-yes}"
		;;
	--ns-comment)
		empty_ok=1
		export EASYRSA_NS_COMMENT="$val"
		;;
	--batch)
		empty_ok=1
		export EASYRSA_BATCH=1
		;;
	-s|--silent)
		empty_ok=1
		export EASYRSA_SILENT=1
		;;
	--sbatch|--silent-batch)
		empty_ok=1
		export EASYRSA_SILENT=1
		export EASYRSA_BATCH=1
		;;
	--verbose)
		empty_ok=1
		export EASYRSA_VERBOSE=1
		;;
	--days-margin)
		# ONLY ALLOWED use by status reports
		number_only=1
		export EASYRSA_iso_8601_MARGIN="$val"
		;;
	-S|--silent-ssl)
		empty_ok=1
		export EASYRSA_SILENT_SSL=1
		# This will probably be need
		#save_EASYRSA_SILENT_SSL=1
		;;
	--force-safe-ssl)
		empty_ok=1
		export EASYRSA_FORCE_SAFE_SSL=1
		;;
	--no-safe-ssl)
		empty_ok=1
		export EASYRSA_NO_SAFE_SSL=1
		;;
	--nopass|--no-pass)
		empty_ok=1
		export EASYRSA_NO_PASS=1
		;;
	--passin)
		export EASYRSA_PASSIN="$val"
		;;
	--passout)
		export EASYRSA_PASSOUT="$val"
		;;
	--raw-ca)
		empty_ok=1
		export EASYRSA_RAW_CA=1
		;;
	--notext|--no-text)
		empty_ok=1
		export EASYRSA_NO_TEXT=1
		;;
	--subca-len)
		number_only=1
		zero_allowed=1
		export EASYRSA_SUBCA_LEN="$val"
		;;
	--vars)
		user_vars_true=1
		export EASYRSA_VARS_FILE="$val"
		;;
	--copy-ext)
		empty_ok=1
		export EASYRSA_CP_EXT=1
		;;
	--subject-alt-name|--san)
		user_san_true=1
		export EASYRSA_EXTRA_EXTS="\
$EASYRSA_EXTRA_EXTS
subjectAltName = $val"
		;;
	--version)
		shift "$#"
		set -- "$@" "version"
		break
		;;
	# Unsupported options
	--fix-offset)
		die "Option $opt is not supported.
Use options --startdate and --enddate for fixed dates."
		;;
	*)
		break
	esac

	# fatal error when no value was provided
	if [ "$is_empty" ]; then
		[ "$empty_ok" ] || \
			die "Missing value to option: $opt"
	fi

	# fatal error when a number is expected but not provided
	if [ "$number_only" ]; then
		case "$val" in
			(0)
				# Allow zero only
				[ "$zero_allowed" ] || \
					die "$opt - Number expected: '$val'"
			;;
			(*[!1234567890]*|0*)
				die "$opt - Number expected: '$val'"
		esac
	fi

	shift
done

# Set cmd now
# vars_setup needs to know if this is init-pki
cmd="$1"
[ "$1" ] && shift # scrape off command

# This avoids unnecessary warnings and notices
case "$cmd" in
	init-pki|clean-all|""|help|-h|--help|--usage|version)
		no_pki_required=1
		unset -v pki_is_required
	;;
	*)
		pki_is_required=1
		unset -v no_pki_required
esac

# Intelligent env-var detection and auto-loading:
vars_setup

# Check for conflicting input options
mutual_exclusions

# Final checks of working environment
verify_working_env

# Hand off to the function responsible
case "$cmd" in
	init-pki|clean-all)
		init_pki "$@"
		;;
	build-ca)
		[ -z "$alias_days" ] || \
			export EASYRSA_CA_EXPIRE="$alias_days"
		build_ca "$@"
		;;
	gen-dh)
		gen_dh
		;;
	gen-req)
		gen_req "$@"
		;;
	sign|sign-req)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		sign_req "$@"
		;;
	build-client-full)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		build_full client "$@"
		;;
	build-server-full)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		build_full server "$@"
		;;
	build-serverClient-full)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		build_full serverClient "$@"
		;;
	gen-crl)
		[ -z "$alias_days" ] || \
			export EASYRSA_CRL_DAYS="$alias_days"
		gen_crl
		;;
	revoke)
		revoke "$@"
		;;
	revoke-renewed)
		revoke_renewed "$@"
		;;
	renew)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		renew "$@"
		;;
	rewind-renew)
		rewind_renew "$@"
		;;
	rebuild)
		[ -z "$alias_days" ] || \
			export EASYRSA_CERT_EXPIRE="$alias_days"
		rebuild "$@"
		;;
	import-req)
		import_req "$@"
		;;
	export-p12)
		export_pkcs p12 "$@"
		;;
	export-p7)
		export_pkcs p7 "$@"
		;;
	export-p8)
		export_pkcs p8 "$@"
		;;
	export-p1)
		export_pkcs p1 "$@"
		;;
	set-rsa-pass)
		set_pass_legacy rsa "$@"
		;;
	set-ec-pass)
		set_pass_legacy ec "$@"
		;;
	set-pass|set-ed-pass)
		set_pass "$@"
		;;
	update-db)
		update_db
		;;
	show-req)
		show req "$@"
		;;
	show-cert)
		show cert "$@"
		;;
	show-crl)
		show crl crl
		;;
	show-ca)
		show_ca "$@"
		;;
	verify|verify-cert)
		verify_cert "$@"
		;;
	show-expire)
		[ -z "$alias_days" ] || \
			export EASYRSA_PRE_EXPIRY_WINDOW="$alias_days"
		status expire "$@"
		;;
	show-revoke)
		status revoke "$@"
		;;
	show-renew)
		status renew "$@"
		;;
	show-host)
		show_host "$@"
		;;
	make-safe-ssl)
		make_safe_ssl "$@"
		;;
	upgrade)
		up23_manage_upgrade_23 "$@"
		;;
	""|help|-h|--help|--usage)
		cmd_help "$1"
		;;
	version)
		print_version
		;;
	*)
		die "\
Unknown command '$cmd'. Run without commands for usage help."
esac

# Check for untrapped errors
# shellcheck disable=SC2181
if [ $? = 0 ]; then
	# Do 'cleanup ok' on successful completion
	#print "mktemp_counter: $mktemp_counter uses"
	cleanup ok
fi

# Otherwise, exit with error
warn "Untrapped error detected!"
cleanup

# vim: ft=sh nu ai sw=8 ts=8 noet

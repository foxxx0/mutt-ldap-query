# mutt-ldap-query
A helper script for searching contact email addresses in an LDAP directory

## Setup

1. Have a look at the `config.example.ini`, copy it to `~/.config/mutt-ldap-query/config.ini` and adjust it to your environment.
2. Run `./mutt-ldap-query.pl "a_search_string"` to verify it works.
3. Edit your `muttrc` and add `set query_command = "~/bin/mutt-ldap-query.pl '%s'"` to use it for tab-complete from within mutt.


For some verbose/debug output pass `-d` to the script or set the environment variable `MUTT_LDAP_QUERY_DEBUG` to 1.

You can have multiple different configuration files, selectable using the `-c <another_config.ini>` command line argument.
Alternatively, you can set the environment variable `MUTT_LDAP_QUERY_CONFIG` to the path of the config.
When both `MUTT_LDAP_QUERY_CONFIG` and `-c <another_config.ini>` are given, the command line argument takes precedence over the environment variable.

See `./mutt-ldap-query.pl -h` for help / usage instructions.

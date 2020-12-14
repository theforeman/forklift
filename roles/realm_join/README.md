# Realm join

Initialize the machine for foreman kerberos with a given realm prior to install.

## Variables

Check [defaults](defaults/main.yml)

* `foreman_realm` - realm name - usually uppercased domain name.
* `foreman_realm_domain` - domain for the realm we are joining, should match the computer domain unless you're testing some obscure setup
* `foreman_realm_directory_admin_name` - user, that has permissions to control the realm (join, get keytab)
* `foreman_realm_directory_admin_password` - password for the above user

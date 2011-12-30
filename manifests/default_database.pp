# create default database
# generate hashed password with:
# ruby -r'digest/sha1' -e 'puts "*" + Digest::SHA1.hexdigest(Digest::SHA1.digest(ARGV[0])).upcase' PASSWORD
define mysql::default_database(
    $username = 'absent',
    $password,
    $password_is_encrypted = true,
    $privileges = 'all',
    $host = '127.0.0.1',
    $ensure = 'present'
) {
    $real_username = $username ? {
      'absent' => $name,
      default => $username
    }
    mysql_database{"$name":
        ensure => $ensure
    }
    case $password {
        'absent': { 
            info("we don't create the user for database: ${name}") 
            $grant_require = Mysql_database["$name"]
        }
        default: {
            mysql_user{"${real_username}@${host}":
                password_hash => $password_is_encrypted ? {
                    true => "$password",
                    default => mysql_password("$password")
                },
                ensure => $ensure,
                require => [
                    Mysql_database["$name"]
                ],
            }
            $grant_require = [ 
              Mysql_database["$name"], 
              Mysql_user["${real_username}@${host}"] 
            ]
        }
    }
    mysql_grant{"${real_username}@${host}/${name}":
        privileges => "$privileges",
        require => $grant_require,
    }
}

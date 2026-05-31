# Manaprobe-maintainer

Manaprobe-maintainer is a command line interface (CLI) non-iOS/ mac OS program written in the Swift programming language. It is used to update the database of [Manaprobe](https://manaprobe.com).

The database backend is PostgreSQL, and [PostgresClientKit](https://github.com/codewinsdotcom/PostgresClientKit) is the client library used to connect to the database.

## Configuration

Create a configuration file `~/.manaprobe-maintaner.config` with the following contents:

```
# Database host
host=<host>
# Database port
port=<port>
# Database name
database=<database>
# Database user
user=<user>
# Database password
password=<password>
# Full update: true | false
full-update=<full-update>
# Card images path
images-path=<images-path> 
```

## Building

    $ swift build -c release
    $ cp .build/release/manaprobe-maintainer /usr/local/bin/

## Author

Vito Royeca

https://vitoroyeca.me


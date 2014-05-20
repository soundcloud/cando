# CanDo [![Build Status](https://travis-ci.org/soundcloud/cando.svg?branch=master)](https://travis-ci.org/soundcloud/cando)

CanDo is a small gem to implement a simple user access system based on users, roles &
capabilites, where:

  - each user can have 0, 1 or many roles
  - each role can have 0, 1 or many capabilites

Users have capabilities by getting roles assigned (role == collection of
capabilities). Within the code, the `can` helper method can be used to test
whether a user has a certain capability or not (see below for a working code example).

## Dependencies

CanDo depends on the following software:

* [sequel](http://sequel.jeremyevans.net)
* [rake](https://github.com/jimweirich/rake)


## Installation and deployment

Download and install rake with the following.

        gem install cando

## Configuration and usage

### Database setup & configuration
If you want to use an individual database for cando, create the db + credentials (adjust values):

    CREATE DATABASE IF NOT EXISTS cando  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
    GRANT ALL ON `cando`.* to 'cando_user'@'localhost' identified by 'cando_passwd';

Whenever you want to use a CanDo rake task, you need to set the database config via the env var `$CANDO_DB`:

     export CANDO_TEST_DB=mysql://cando_user:cando_passwd@localhost/cando

for other dbs, [see the sequel
documentation](http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect).
**Note that you will have to require the gem for your respective dbms, i.e. the
`mysql`-gem for mysql, the `sqlite3`-gem for sqlite, etc. **

### Init cando
Cando provides a rake task to get you started. This will setup the necessary
tables (they are all prefixed with `cando` and thus should not interfere with
your database.

    rake cando:init

### Using rake tasks
Cando provides several useful rake tasks for easy cli-based operations. In order
to use those edit (or create) the `Rakefile` and include

    require 'cando'

 To get an overview, execute:

     $ rake -T cando
     rake cando:init     # Initialize cando (creates schema and runs migration)

     rake cando:list     # List roles
     rake cando:add      # Add a new role (pass in role name and capabilities with role=<name> capabilities=<cap1>,<cap2>,...
     rake cando:update   # Update role (pass in role name and capabilities with role=<name> capabilities=<cap1>,<cap2>,...
     rake cando:remove   # Remove role (pass in role name with role=<name>)

     rake cando:assign   # Assign role to user (args: roles=<r1>,<r2>,<rn> user=<user_urn>)
     rake cando:users    # List users and their roles

### Using CanDo in your project's code
Using the CanDo in your code (working code with an empty database):

    require 'cando'
    include CanDo

    CanDo.init do
      # if passed, this will be executed if the user does not have the
      # asked-for capability (only applies if 'can' is passed a block)
      cannot_block do |user_urn, capability|
        raise "#{user_urn} can not #{capability}"
      end

      connect "mysql://cando_user:cando_passwd@host:port/database"
    end

    # if the role or a capability does not exist, it'll be created
    define_role("r1", ["capability1", "capability3"])
    define_role("r2", ["capability2"])

    # if the user does not exist, he'll be created -- the roles must be available
    assign_roles("user1", ["r1", "r2"])
    assign_roles("user2", ["r1"])

    # use 'can' block syntax
    can("user1", :capability1) do
      puts "user has capability1"
    end

    # this will raise an exception as declared in the init block
    can("user1", :super_admin) do
      puts "hey hoh" # this will not be printed
    end

    # when no block is given, 'can' returns true or false/nil
    unless can("user2", :capability2)
      puts "user does not have capability1"
    end

## Versioning
CanDo adheres to Semantic Versioning 2.0.0. If there is a violation of
this scheme, report it as a bug.Specifically, if a patch or minor version is
released and breaks backward compatibility, that version should be immediately
yanked and/or a new version should be immediately released that restores
compatibility. Any change that breaks the public API will only be introduced at
a major-version release. As a result of this policy, you can (and should)
specify any dependency on <project name> by using the Pessimistic Version
Constraint with two digits of precision.

## Licensing

See the [LICENSE](LICENSE.md) file for details.

The MIT License (MIT)

Copyright &copy; 2014 Daniel Bornkessel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


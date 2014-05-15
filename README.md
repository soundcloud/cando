# CanDo

CanDo is a small gem to implement a simple user access system based on roles & capabilites.

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
    
Whenever you want to use CanDo, you need to set the database config via the env var `$CANDO_DB`:

     export CANDO_DB=mysql://cando_user@cando_passwd@localhost/cando
     
for other dbs, [see the sequel documentation](http://sequel.jeremyevans.net/rdoc/classes/Sequel.html#method-c-connect). **Note that you will have to require the gem for your respective db, i.e. the `mysql`-gem for mysql, the `sqlite`-gem for sqlite, etc. **

### Init project
Cando provides a rake task to get you started:

    rake cando:init

### Using rake tasks
Cando provides several useful rake tasks for easy cli-based operations. In order to use those edit (or create) the `Rakefile` and include
  
    require 'cando'
        
 To get an overview, execute:
 
     rake -T cando 
        
### Using the helper
Using the `can` helper function in your code:

    require 'cando'
    include CanDoHelper
        
    # block syntax
    can("user_urn", :capability1) do
      puts "user has capability1"
    end
        
    # use as a condition
    unless can("user_urn", :capability2)
      puts "user does not have capability2"
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


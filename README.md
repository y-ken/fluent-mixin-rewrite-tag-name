## Fluent::Mixin::RewriteTagName [![Build Status](https://travis-ci.org/y-ken/fluent-mixin-rewrite-tag-name.png?branch=master)](https://travis-ci.org/y-ken/fluent-mixin-rewrite-tag-name)

## Overview

Fluentd mixin plugin to provides placeholder function for rewriting tag for your any plugins as like [fluent-plugin-rewrite-tag-filter](https://github.com/fluent/fluent-plugin-rewrite-tag-filter). It will let you get easy to implement tag placeholder for your own plugins.

## Placeholders

It supportes these placeholder for rewriting tag.

- `${tag}`
- `__TAG__`
- `{$tag_parts[n]}`
- `__TAG_PARTS[n]__`
- `${hostname}`
- `__HOSTNAME__`

The placeholder of `{$tag_parts[n]}` and `__TAG_PARTS[n]__` acts accessing the index which split the tag with "." (dot).  
For example with `td.apache.access` tag, it will get `td` by `${tag_parts[0]}` and `apache` by `${tag_parts[1]}`.

**Note** 

* range expression ```${tag_parts[0..2]}``` is also supported. see [unit test](https://github.com/y-ken/fluent-mixin-rewrite-tag-name/blob/master/test/mixin/test_rewrite_tag_name.rb#L106).

#### Placeholder Option

* `hostname_command` 

By default, execute command as `hostname` to get full hostname.  
On your needs, it could override hostname command using `hostname_command` option.  
It comes short hostname with `hostname_command hostname -s` configuration specified.

## Configuration

Adding this mixin plugin, it will enabled to use these placeholder in your plugins.

```xml
# input plugin example
<source>
  type              foo_bar

  # it will be rewrited to be 'customprefix.web10-222' when short hostname is 'web10-222'.
  tag               customprefix.${hostname}
  
  # to use short hostname placeholder, add option like below.
  hostname_command             hostname -s
</source>
```

```xml
# output plugin example
<match test.foo>
  type  foo_bar
  
  # it will be rewrited to be 'customprefix.test.foo'.
  tag   customprefix.${tag}
</match>
```

Another examples are written in [unit test](https://github.com/y-ken/fluent-mixin-rewrite-tag-name/blob/master/test/mixin/test_rewrite_tag_name.rb).

## Usage

#### 1. edit gemspec

add dependency for .gemspec file like below. For more detail, see [gemspec example](https://github.com/y-ken/fluent-plugin-anonymizer/blob/master/fluent-plugin-anonymizer.gemspec)

```ruby
spec.add_runtime_dependency "fluent-mixin-rewrite-tag-name"
```

#### 2. activate fluent-mixin-rewrite-tag-name for your plugin

It is the instruction in the case of adding `fluent-plugin-foobar`.

```
$ cd fluent-plugin-foobar
$ vim fluent-plugin-foobar.gemspec # edit gemspec
$ bundle install --path vendor/bundle # or just type `bundle install`
```

#### 3. edit your plugin to implement

It is a quick guide to enable your plugin to use RewriteTagNameMixin.  
The key points of implmentation is just four below.

* add `require 'fluent/mixin/rewrite_tag_name'` at the top of source
* in the case of output plugin, add `include Fluent::HandleTagNameMixin`  
this is required if you will use 'remove_tag_prefix' option together
* add `include Fluent::Mixin::RewriteTagName` in class after HandleTagNameMixin
* add `emit_tag = tag.dup` and `filter_record(emit_tag, time, record)` before `Engine.emit`

##### implement example for input plugin

```ruby
require 'fluent/mixin/rewrite_tag_name'

module Fluent
  class FooBarInput < Fluent::Input
    Plugin.register_input('foo_bar', self)

    # ...snip...

    include Fluent::HandleTagNameMixin
    include Fluent::Mixin::RewriteTagName    
    config_param :hostname_command, :string, :default => 'hostname'

    # ...snip...

    def configure(conf)
      super

      # ...snip...

      # add a error handling 
      if ( !@tag && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix )
        raise Fluent::ConfigError, "foo_bar: missing remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end      
    end

    # ...snip...

    def emit_message(tag, message)
      emit_tag = tag.dup
      filter_record(emit_tag, time, message)
      Engine.emit(emit_tag, Engine.now, message)
    end

    # ...snip...

  end
end
```

##### implement example for output plugin

```ruby
require 'fluent/mixin/rewrite_tag_name'

class Fluent
  class FooBarOutput < Fluent::Output
    Fluent::Plugin.register_output('foo_bar', self)

    include Fluent::Mixin::RewriteTagName
    config_param :hostname_command, :string, :default => 'hostname'

    # ...snip...

    def configure(conf)
      super

      # ...snip...

      # add a error handling 
      if ( !@tag && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix )
        raise Fluent::ConfigError, "foo_bar: missing remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end      
    end

    # ...snip...

    def emit(tag, es, chain)
      es.each do |time, record|
        emit_tag = tag.dup
        filter_record(emit_tag, time, record)
        Fluent::Engine.emit(emit_tag, time, record)
      end
      chain.next
    end

    # ...snip...

  end
end
```

## Case Study

These cool plugins are using this mixin!

* [fluent-plugin-anonymizer](https://github.com/y-ken/fluent-plugin-anonymizer/)

## TODO

* switchable tag template variable like 'tag', 'tag_format'
* support range tag_parts like [fluent-plugin-forest](https://github.com/tagomoris/fluent-plugin-forest/compare/v0.2.2...master)
* support tag_prefix and tag_suffix placeholder like [fluent-plugin-record-reformer](https://github.com/sonots/fluent-plugin-record-reformer)
* merge into [fluentd/lib/fluent/mixin.rb](https://github.com/fluent/fluentd/blob/master/lib/fluent/mixin.rb) as RewriteTagNameMixin module.

Pull requests are very welcome!!

## Copyright

Copyright © 2014- Kentaro Yoshida ([@yoshi_ken](https://twitter.com/yoshi_ken))

## License

Apache License, Version 2.0

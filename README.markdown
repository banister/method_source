method_source
=============

(C) John Mair (banisterfiend) 2011

_retrieve the sourcecode for a method_

*NOTE:* This simply utilizes `Method#source_location`; it
 does not access the live AST.

`method_source` is a utility to return a method's sourcecode as a
Ruby string. Also returns `Proc` and `Lambda` sourcecode.

Method comments can also be extracted using the `comment` method.

It is written in pure Ruby (no C).

* Some Ruby 1.8 support now available. 

`method_source` provides the `source` and `comment` methods to the `Method` and
`UnboundMethod` and `Proc` classes.

* Install the [gem](https://rubygems.org/gems/method_source): `gem install method_source`
* Read the [documentation](http://rdoc.info/github/banister/method_source/master/file/README.markdown)
* See the [source code](http://github.com/banister/method_source)

Example: display method source
------------------------------

    Set.instance_method(:merge).source.display
    # =>
    def merge(enum)
      if enum.instance_of?(self.class)
        @hash.update(enum.instance_variable_get(:@hash))
      else
        do_with_enum(enum) { |o| add(o) }
      end

      self
    end

Example: display method comments
--------------------------------

    Set.instance_method(:merge).comment.display
    # =>
    # Merges the elements of the given enumerable object to the set and
    # returns self.

Limitations:
------------

* Occasional strange behaviour in Ruby 1.8
* Cannot return source for C methods.
* Cannot return source for dynamically defined methods.

Special Thanks
--------------

[Adam Sanderson](https://github.com/adamsanderson) for `comment` functionality.

[Dmitry Elastic](https://github.com/dmitryelastic) for the brilliant Ruby 1.8 `source_location` hack.

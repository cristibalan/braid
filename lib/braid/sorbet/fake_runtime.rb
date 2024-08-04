# typed: ignore

# This file contains a fake implementation of the subset of `sorbet-runtime`
# used by Braid that performs no runtime checks.  See the "Type checking"
# section of development.md for background.

require 'singleton'

# Create our fake module at `Braid::T` so that if someone loads Braid into the
# same Ruby interpreter as other code that needs the real sorbet-runtime, we
# don't break the other code.  (We don't officially support loading Braid as a
# library, but we may as well go ahead and put this infrastructure in place.)
# Code in the `Braid` module still uses normal references to `T`, so the Sorbet
# static analyzer (which doesn't read this file) doesn't see anything out of the
# ordinary, but those references resolve to `Braid::T` at runtime according to
# Ruby's constant lookup rules.
module Braid
  module T

    module Sig
      def sig; end
    end
    def self.let(value, type)
      value
    end

    # NOTICE: Like everything else in the fake Sorbet runtime (e.g., `sig`),
    # these do not actually perform runtime checks.  Currently, if you want a
    # runtime check, you have to implement it yourself.  We considered defining
    # wrapper functions with different names to make this clearer, but then we'd
    # lose the extra static checks that Sorbet performs on direct calls to
    # `T.cast` and `T.must`.
    def self.cast(value, type)
      value
    end
    def self.must(value)
      value
    end
    def self.unsafe(value)
      value
    end
    def self.bind(value, type); end

    class FakeType
      include Singleton
    end
    FAKE_TYPE = FakeType.instance

    def self.type_alias
      FAKE_TYPE
    end

    def self.nilable(type)
      FAKE_TYPE
    end
    def self.untyped
      FAKE_TYPE
    end
    def self.noreturn
      FAKE_TYPE
    end
    def self.any(*types)
      FAKE_TYPE
    end
    Boolean = FAKE_TYPE
    module Array
      def self.[](type)
        FAKE_TYPE
      end
    end
    module Hash
      def self.[](key_type, value_type)
        FAKE_TYPE
      end
    end

    class Struct
      def initialize(**kwargs)
        # The fake runtime isn't obliged to validate the property names or
        # types.
        #
        # Note: If the caller passed a hash of keyword arguments, Ruby will copy
        # it, so we don't need to copy `kwargs` again here to avoid aliasing.
        @attrs = kwargs
      end

      def self.prop(prop_name, prop_type)
        define_method(prop_name) {
          @attrs[prop_name]
        }
        define_method(prop_name.name + '=') { |new_value|
          @attrs[prop_name] = new_value
        }
      end
    end
  end
end

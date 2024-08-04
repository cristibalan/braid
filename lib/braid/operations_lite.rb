# typed: strict

require 'braid/sorbet/setup'

# One helper that is shared with the integration test harness and has no
# dependencies on the rest of Braid.
module Braid
  module Operations
    extend T::Sig

    # Want to use https://github.com/thoughtbot/climate_control ?
    #
    # We have to declare the `&blk` parameter in order to reference it in the
    # type annotation, even though the body doesn't use it.  This causes the
    # block to be converted to a proc at runtime, which has some performance
    # cost (probably not important in the context of Braid).  TODO: Find a way
    # to avoid the performance cost?  File a Sorbet enhancement request?
    sig {
      type_parameters(:R).params(
        dict: T::Hash[String, String],
        blk: T.proc.returns(T.type_parameter(:R))
      ).returns(T.type_parameter(:R))
    }
    def self.with_modified_environment(dict, &blk)
      orig_dict = T.let({}, T::Hash[String, T.nilable(String)])
      dict.each { |name, value|
        orig_dict[name] = ENV[name]
        ENV[name] = value
      }
      begin
        yield
      ensure
        orig_dict.each { |name, orig_value|
          ENV[name] = orig_value
        }
      end
    end
  end
end

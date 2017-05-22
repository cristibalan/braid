# One helper that is shared with the integration test harness and has no
# dependencies on the rest of Braid.
module Braid
  module Operations
    # Want to use https://github.com/thoughtbot/climate_control ?
    def self.with_modified_environment(dict)
      orig_dict = {}
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

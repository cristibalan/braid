# typed: strict
module Braid
  class Mirror

    # Type declarations for the methods simulated by `method_missing`.

    sig {returns(String)}
    def url; end
    sig {params(new_value: String).void}
    def url=(new_value); end

    sig {returns(T.nilable(String))}
    def branch; end
    sig {params(new_value: T.nilable(String)).void}
    def branch=(new_value); end

    # `path` is overridden by the `attr_reader :path`, as noted in the comment
    # on `method_missing`.  `path=` might still work, but it isn't intended to
    # be used, and we want a type error if we try to use it.

    sig {returns(T.nilable(String))}
    def tag; end
    sig {params(new_value: T.nilable(String)).void}
    def tag=(new_value); end

    sig {returns(String)}
    def revision; end
    sig {params(new_value: String).void}
    def revision=(new_value); end

  end
end

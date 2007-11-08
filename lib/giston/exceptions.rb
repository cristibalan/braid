module Giston
  class Exception < StandardError
    #
  end
  class Svn
    class RepositoryNotFound < Giston::Exception; end
  end
  class Git
    class RepositoryError < Giston::Exception; end
  end
end

module Giston
  class Exception < StandardError
  end

  module Commands
    class LocalRevisionIsHigherThanRequestedRevision < Giston::Exception; end
    class MirrorAlreadyUpToDate < Giston::Exception; end
    class RequestedRevisionIsHigherThanRemoteRevision < Giston::Exception; end
  end

  class Config
    class MirrorNameAlreadyInUse < Giston::Exception; end
    class MirrorDoesNotExist < Giston::Exception; end
  end

  class Svn
    class TargetDirectoryAlreadyExists < Giston::Exception; end
    class RepositoryNotFound < Giston::Exception; end
  end

  class Git
    class LocalRepositoryHasUncommitedChanges < Giston::Exception; end
    class RepositoryError < Giston::Exception; end
  end
end

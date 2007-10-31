README

giston update vendor/blah
giston update

giston add http://blah vendor/blah
giston remove vendor/blah

update:
get current rev in git
get last commited rev with svn info
if new shit available
  exit if local changes
  svn diff ourrev:headrev > tmpfile
  patch -p0 --dry-run
  patch -p0
  get binary files from tmpfile
  svn cat from repository for each file
end



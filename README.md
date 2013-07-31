ftw_mirror
==========

FTP-to-WWW mirror scripts

purpose
----------
let's suppose you run a FTP server for sharing files with people.
certainly there will be some people you want to share with but
can't be bothered to set up another FTP user.

conversely, they can't be trusted with setting up a FTP client anyway,
or you don't want to grant them access.

this set of scripts solves this problem by mirroring/linking the files
and providing you with a web frontend.

deployment
----------
- *ftwmirror* is made to run under root. deploy anywhere.
- put the directory *ftw_mirror* somewhere on your webserver.
- configure relevant portions of *ftwmirror* and *ftw_mirror/index.pl*
- watch out for missing perl modules and privileges

known limitations (won't be fixed)
----------
- single-user system: the error log is read by the frontend once, then zeroed.

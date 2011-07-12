TagFS - Limit View on Filesystem by Tags
========================================

TagFS is a filesystem in userspace.  It takes an existing directory with
tags and allows to limit the view on this filesystem by tags.
- tags are read from a file in each directory named `.tags`
- tags can be combined by `+` or `-`, for example
  `music+electronic-minimal` would show only files which have tags
  `music` and `electronic` but not `minimal`
- at the root of the filesystem the tags can be selected, i.e. `cd
  /mountpoint/music+electronic-minimal/` contains the original files
  limited by the tags
- the root of the filesystem lists all available tags

Usage
-----

Compile extension:

    $ make

Tag files:

    echo tag1 >> /files/foo/.tags
    echo tag2 >> /files/foo/bar/.tags
    echo tag2 >> /files/baz/.tags

Mount filesystem:

    $ ./mount /files /mountpoint

Note: The tag files are read only once and are cached thereafter.
Only remounting helps currently.

Unmount filesystem:

    $ fusermount -u /mountpoint

TODO / Planned Features
-----------------------

- allow to tag files (currently only directories)
- different options to store the tags (per-directory or central
  database)
- writable filesystem (currently only the basic read operations are
  implemented)
- reload tags as necessary
- improve performance to compute tags of directories
- maybe organize tags as trees
- custom event loop instead of fuse_main so signals can be handled
  properly

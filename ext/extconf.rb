require 'mkmf'

extension_name = 'fuse'

$CFLAGS = '-std=c99 ' + `pkg-config --cflags fuse`
$LDFLAGS = `pkg-config --libs fuse`

dir_config extension_name
create_makefile extension_name

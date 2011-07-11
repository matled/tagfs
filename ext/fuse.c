#define FUSE_USE_VERSION 26
#define _BSD_SOURCE 1
#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <unistd.h>

#include <fuse.h>

#include <ruby.h>

VALUE Fuse = Qnil;

/* get mapped path from ruby */
static char *mapped_path(const char *path) {
    VALUE ret = rb_funcall(Fuse, rb_intern("path"), 1, rb_str_new2(path));
    if (TYPE(ret) == T_STRING) {
        return StringValueCStr(ret);
    } else if (TYPE(ret) == T_NIL) {
        return NULL;
    } else {
        rb_raise(rb_eRuntimeError, "string expected");
        /* TODO: is this necessary? */
        return NULL;
    }

    static char buf[4096];
    snprintf(buf, sizeof(buf), "/home/audio/%s", path);
    return buf;
}

/* helper function copying value into filler */
static VALUE fill_me(VALUE value, VALUE filler) {
    /* TODO: is raise good? */
    if (TYPE(value) != T_STRING)
        rb_raise(rb_eRuntimeError, "string expected");
    /* TODO: type of filler */
    (*(fuse_fill_dir_t*)filler)(*((void**)filler+1), StringValueCStr(value), NULL, 0);
    return Qnil;
}

/* get directory content from ruby */
static int my_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
    off_t offset, struct fuse_file_info *fi) {
    /* add . and .. automatically */
    filler(buf, ".", NULL, 0);
    filler(buf, "..", NULL, 0);
    /* call Fuse.readdir */
    VALUE ret = rb_funcall(Fuse, rb_intern("readdir"), 1, rb_str_new2(path));
    /* check that the return value responds to #each */
    VALUE success = rb_funcall(ret, rb_intern("respond_to?"),
        1, ID2SYM(rb_intern("each")));
    /* TODO: every invalid directory will result in ENOENT, maybe allow
     * ruby to omit other errors */
    if (success == Qfalse || success == Qnil)
        return -ENOENT;
    /* fill buf with values yielded by ret.each */
    void *data[2] = {filler, buf};
    rb_block_call(ret, rb_intern("each"), 0, NULL, fill_me, (VALUE)data);
    return 0;
}

/* stat: use mapped path */
static int my_getattr(const char *path, struct stat *statbuf) {
    path = mapped_path(path);
    if (!path)
        return -ENOENT;
    if (stat(path, statbuf))
        return -errno;
    else
        return 0;
}

/* open: use mapped path */
static int my_open(const char *path, struct fuse_file_info *fi) {
    if (fi->flags & (O_WRONLY | O_RDWR))
        return -EPERM;
    path = mapped_path(path);
    if (!path)
        return -ENOENT;
    fi->fh = open(path, O_RDONLY);
    if (fi->fh)
        return 0;
    else
        return -errno;
}

/* read: use fd from open */
static int my_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    if (lseek(fi->fh, offset, SEEK_SET) == (off_t)-1)
        return -errno;
    ssize_t n = read(fi->fh, buf, size);
    if (n == -1)
        return -errno;
    else
        return n;
}

/* close: use fd from open */
static int my_release(const char *path, struct fuse_file_info *fi) {
    return close(fi->fh);
}

static struct fuse_operations my_operations = {
    .getattr = my_getattr,
    .readdir = my_readdir,
    .open = my_open,
    .read = my_read,
    .release = my_release,
};

static VALUE run(int argc, VALUE *argv, VALUE self) {
    char *args[argc + 1];
    for (int i = 0; i < argc; ++i) {
        Check_Type(argv[i], T_STRING);
        args[i] = StringValueCStr(argv[i]);
    }
    args[argc] = NULL;
    return INT2FIX(fuse_main(argc, args, &my_operations, NULL));
}

void Init_fuse(void) {
    Fuse = rb_define_module("Fuse");
    rb_define_singleton_method(Fuse, "main", run, -1);
}

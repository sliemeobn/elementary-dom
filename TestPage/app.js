// node_modules/@bjorn3/browser_wasi_shim/dist/wasi_defs.js
var CLOCKID_REALTIME = 0;
var CLOCKID_MONOTONIC = 1;
var ERRNO_SUCCESS = 0;
var ERRNO_BADF = 8;
var ERRNO_EXIST = 20;
var ERRNO_INVAL = 28;
var ERRNO_ISDIR = 31;
var ERRNO_NAMETOOLONG = 37;
var ERRNO_NOENT = 44;
var ERRNO_NOSYS = 52;
var ERRNO_NOTDIR = 54;
var ERRNO_NOTEMPTY = 55;
var ERRNO_NOTSUP = 58;
var ERRNO_PERM = 63;
var ERRNO_NOTCAPABLE = 76;
var RIGHTS_FD_DATASYNC = 1 << 0;
var RIGHTS_FD_READ = 1 << 1;
var RIGHTS_FD_SEEK = 1 << 2;
var RIGHTS_FD_FDSTAT_SET_FLAGS = 1 << 3;
var RIGHTS_FD_SYNC = 1 << 4;
var RIGHTS_FD_TELL = 1 << 5;
var RIGHTS_FD_WRITE = 1 << 6;
var RIGHTS_FD_ADVISE = 1 << 7;
var RIGHTS_FD_ALLOCATE = 1 << 8;
var RIGHTS_PATH_CREATE_DIRECTORY = 1 << 9;
var RIGHTS_PATH_CREATE_FILE = 1 << 10;
var RIGHTS_PATH_LINK_SOURCE = 1 << 11;
var RIGHTS_PATH_LINK_TARGET = 1 << 12;
var RIGHTS_PATH_OPEN = 1 << 13;
var RIGHTS_FD_READDIR = 1 << 14;
var RIGHTS_PATH_READLINK = 1 << 15;
var RIGHTS_PATH_RENAME_SOURCE = 1 << 16;
var RIGHTS_PATH_RENAME_TARGET = 1 << 17;
var RIGHTS_PATH_FILESTAT_GET = 1 << 18;
var RIGHTS_PATH_FILESTAT_SET_SIZE = 1 << 19;
var RIGHTS_PATH_FILESTAT_SET_TIMES = 1 << 20;
var RIGHTS_FD_FILESTAT_GET = 1 << 21;
var RIGHTS_FD_FILESTAT_SET_SIZE = 1 << 22;
var RIGHTS_FD_FILESTAT_SET_TIMES = 1 << 23;
var RIGHTS_PATH_SYMLINK = 1 << 24;
var RIGHTS_PATH_REMOVE_DIRECTORY = 1 << 25;
var RIGHTS_PATH_UNLINK_FILE = 1 << 26;
var RIGHTS_POLL_FD_READWRITE = 1 << 27;
var RIGHTS_SOCK_SHUTDOWN = 1 << 28;
var Iovec = class {
  static read_bytes(view, ptr) {
    const iovec = new Iovec();
    iovec.buf = view.getUint32(ptr, true);
    iovec.buf_len = view.getUint32(ptr + 4, true);
    return iovec;
  }
  static read_bytes_array(view, ptr, len) {
    const iovecs = [];
    for (let i = 0; i < len; i++) {
      iovecs.push(Iovec.read_bytes(view, ptr + 8 * i));
    }
    return iovecs;
  }
};
var Ciovec = class {
  static read_bytes(view, ptr) {
    const iovec = new Ciovec();
    iovec.buf = view.getUint32(ptr, true);
    iovec.buf_len = view.getUint32(ptr + 4, true);
    return iovec;
  }
  static read_bytes_array(view, ptr, len) {
    const iovecs = [];
    for (let i = 0; i < len; i++) {
      iovecs.push(Ciovec.read_bytes(view, ptr + 8 * i));
    }
    return iovecs;
  }
};
var WHENCE_SET = 0;
var WHENCE_CUR = 1;
var WHENCE_END = 2;
var FILETYPE_CHARACTER_DEVICE = 2;
var FILETYPE_DIRECTORY = 3;
var FILETYPE_REGULAR_FILE = 4;
var Dirent = class {
  head_length() {
    return 24;
  }
  name_length() {
    return this.dir_name.byteLength;
  }
  write_head_bytes(view, ptr) {
    view.setBigUint64(ptr, this.d_next, true);
    view.setBigUint64(ptr + 8, this.d_ino, true);
    view.setUint32(ptr + 16, this.dir_name.length, true);
    view.setUint8(ptr + 20, this.d_type);
  }
  write_name_bytes(view8, ptr, buf_len) {
    view8.set(
      this.dir_name.slice(0, Math.min(this.dir_name.byteLength, buf_len)),
      ptr
    );
  }
  constructor(next_cookie, name, type) {
    this.d_ino = 0n;
    const encoded_name = new TextEncoder().encode(name);
    this.d_next = next_cookie;
    this.d_namlen = encoded_name.byteLength;
    this.d_type = type;
    this.dir_name = encoded_name;
  }
};
var FDFLAGS_APPEND = 1 << 0;
var FDFLAGS_DSYNC = 1 << 1;
var FDFLAGS_NONBLOCK = 1 << 2;
var FDFLAGS_RSYNC = 1 << 3;
var FDFLAGS_SYNC = 1 << 4;
var Fdstat = class {
  write_bytes(view, ptr) {
    view.setUint8(ptr, this.fs_filetype);
    view.setUint16(ptr + 2, this.fs_flags, true);
    view.setBigUint64(ptr + 8, this.fs_rights_base, true);
    view.setBigUint64(ptr + 16, this.fs_rights_inherited, true);
  }
  constructor(filetype, flags) {
    this.fs_rights_base = 0n;
    this.fs_rights_inherited = 0n;
    this.fs_filetype = filetype;
    this.fs_flags = flags;
  }
};
var FSTFLAGS_ATIM = 1 << 0;
var FSTFLAGS_ATIM_NOW = 1 << 1;
var FSTFLAGS_MTIM = 1 << 2;
var FSTFLAGS_MTIM_NOW = 1 << 3;
var OFLAGS_CREAT = 1 << 0;
var OFLAGS_DIRECTORY = 1 << 1;
var OFLAGS_EXCL = 1 << 2;
var OFLAGS_TRUNC = 1 << 3;
var Filestat = class {
  write_bytes(view, ptr) {
    view.setBigUint64(ptr, this.dev, true);
    view.setBigUint64(ptr + 8, this.ino, true);
    view.setUint8(ptr + 16, this.filetype);
    view.setBigUint64(ptr + 24, this.nlink, true);
    view.setBigUint64(ptr + 32, this.size, true);
    view.setBigUint64(ptr + 38, this.atim, true);
    view.setBigUint64(ptr + 46, this.mtim, true);
    view.setBigUint64(ptr + 52, this.ctim, true);
  }
  constructor(filetype, size) {
    this.dev = 0n;
    this.ino = 0n;
    this.nlink = 0n;
    this.atim = 0n;
    this.mtim = 0n;
    this.ctim = 0n;
    this.filetype = filetype;
    this.size = size;
  }
};
var EVENTRWFLAGS_FD_READWRITE_HANGUP = 1 << 0;
var SUBCLOCKFLAGS_SUBSCRIPTION_CLOCK_ABSTIME = 1 << 0;
var RIFLAGS_RECV_PEEK = 1 << 0;
var RIFLAGS_RECV_WAITALL = 1 << 1;
var ROFLAGS_RECV_DATA_TRUNCATED = 1 << 0;
var SDFLAGS_RD = 1 << 0;
var SDFLAGS_WR = 1 << 1;
var PREOPENTYPE_DIR = 0;
var PrestatDir = class {
  write_bytes(view, ptr) {
    view.setUint32(ptr, this.pr_name.byteLength, true);
  }
  constructor(name) {
    this.pr_name = new TextEncoder().encode(name);
  }
};
var Prestat = class {
  static dir(name) {
    const prestat = new Prestat();
    prestat.tag = PREOPENTYPE_DIR;
    prestat.inner = new PrestatDir(name);
    return prestat;
  }
  write_bytes(view, ptr) {
    view.setUint32(ptr, this.tag, true);
    this.inner.write_bytes(view, ptr + 4);
  }
};

// node_modules/@bjorn3/browser_wasi_shim/dist/debug.js
var Debug = class Debug2 {
  enable(enabled) {
    this.log = createLogger(enabled === void 0 ? true : enabled, this.prefix);
  }
  get enabled() {
    return this.isEnabled;
  }
  constructor(isEnabled) {
    this.isEnabled = isEnabled;
    this.prefix = "wasi:";
    this.enable(isEnabled);
  }
};
function createLogger(enabled, prefix) {
  if (enabled) {
    const a = console.log.bind(console, "%c%s", "color: #265BA0", prefix);
    return a;
  } else {
    return () => {};
  }
}
var debug = new Debug(false);

// node_modules/@bjorn3/browser_wasi_shim/dist/wasi.js
var WASIProcExit = class extends Error {
  constructor(code) {
    super("exit with exit code " + code);
    this.code = code;
  }
};
var WASI = class WASI2 {
  start(instance) {
    this.inst = instance;
    try {
      instance.exports._start();
      return 0;
    } catch (e) {
      if (e instanceof WASIProcExit) {
        return e.code;
      } else {
        throw e;
      }
    }
  }
  initialize(instance) {
    this.inst = instance;
    if (instance.exports._initialize) {
      instance.exports._initialize();
    }
  }
  constructor(args, env, fds, options = {}) {
    this.args = [];
    this.env = [];
    this.fds = [];
    debug.enable(options.debug);
    this.args = args;
    this.env = env;
    this.fds = fds;
    const self = this;
    this.wasiImport = {
      args_sizes_get(argc, argv_buf_size) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        buffer.setUint32(argc, self.args.length, true);
        let buf_size = 0;
        for (const arg of self.args) {
          buf_size += arg.length + 1;
        }
        buffer.setUint32(argv_buf_size, buf_size, true);
        debug.log(
          buffer.getUint32(argc, true),
          buffer.getUint32(argv_buf_size, true)
        );
        return 0;
      },
      args_get(argv, argv_buf) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        const orig_argv_buf = argv_buf;
        for (let i = 0; i < self.args.length; i++) {
          buffer.setUint32(argv, argv_buf, true);
          argv += 4;
          const arg = new TextEncoder().encode(self.args[i]);
          buffer8.set(arg, argv_buf);
          buffer.setUint8(argv_buf + arg.length, 0);
          argv_buf += arg.length + 1;
        }
        if (debug.enabled) {
          debug.log(
            new TextDecoder("utf-8").decode(
              buffer8.slice(orig_argv_buf, argv_buf)
            )
          );
        }
        return 0;
      },
      environ_sizes_get(environ_count, environ_size) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        buffer.setUint32(environ_count, self.env.length, true);
        let buf_size = 0;
        for (const environ of self.env) {
          buf_size += environ.length + 1;
        }
        buffer.setUint32(environ_size, buf_size, true);
        debug.log(
          buffer.getUint32(environ_count, true),
          buffer.getUint32(environ_size, true)
        );
        return 0;
      },
      environ_get(environ, environ_buf) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        const orig_environ_buf = environ_buf;
        for (let i = 0; i < self.env.length; i++) {
          buffer.setUint32(environ, environ_buf, true);
          environ += 4;
          const e = new TextEncoder().encode(self.env[i]);
          buffer8.set(e, environ_buf);
          buffer.setUint8(environ_buf + e.length, 0);
          environ_buf += e.length + 1;
        }
        if (debug.enabled) {
          debug.log(
            new TextDecoder("utf-8").decode(
              buffer8.slice(orig_environ_buf, environ_buf)
            )
          );
        }
        return 0;
      },
      clock_res_get(id, res_ptr) {
        let resolutionValue;
        switch (id) {
          case CLOCKID_MONOTONIC: {
            resolutionValue = 5000n;
            break;
          }
          case CLOCKID_REALTIME: {
            resolutionValue = 1000000n;
            break;
          }
          default:
            return ERRNO_NOSYS;
        }
        const view = new DataView(self.inst.exports.memory.buffer);
        view.setBigUint64(res_ptr, resolutionValue, true);
        return ERRNO_SUCCESS;
      },
      clock_time_get(id, precision, time) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        if (id === CLOCKID_REALTIME) {
          buffer.setBigUint64(
            time,
            BigInt(new Date().getTime()) * 1000000n,
            true
          );
        } else if (id == CLOCKID_MONOTONIC) {
          let monotonic_time;
          try {
            monotonic_time = BigInt(Math.round(performance.now() * 1e6));
          } catch (e) {
            monotonic_time = 0n;
          }
          buffer.setBigUint64(time, monotonic_time, true);
        } else {
          buffer.setBigUint64(time, 0n, true);
        }
        return 0;
      },
      fd_advise(fd, offset, len, advice) {
        if (self.fds[fd] != void 0) {
          return ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_allocate(fd, offset, len) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_allocate(offset, len);
        } else {
          return ERRNO_BADF;
        }
      },
      fd_close(fd) {
        if (self.fds[fd] != void 0) {
          const ret = self.fds[fd].fd_close();
          self.fds[fd] = void 0;
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_datasync(fd) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_sync();
        } else {
          return ERRNO_BADF;
        }
      },
      fd_fdstat_get(fd, fdstat_ptr) {
        if (self.fds[fd] != void 0) {
          const { ret, fdstat } = self.fds[fd].fd_fdstat_get();
          if (fdstat != null) {
            fdstat.write_bytes(
              new DataView(self.inst.exports.memory.buffer),
              fdstat_ptr
            );
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_fdstat_set_flags(fd, flags) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_fdstat_set_flags(flags);
        } else {
          return ERRNO_BADF;
        }
      },
      fd_fdstat_set_rights(fd, fs_rights_base, fs_rights_inheriting) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_fdstat_set_rights(
            fs_rights_base,
            fs_rights_inheriting
          );
        } else {
          return ERRNO_BADF;
        }
      },
      fd_filestat_get(fd, filestat_ptr) {
        if (self.fds[fd] != void 0) {
          const { ret, filestat } = self.fds[fd].fd_filestat_get();
          if (filestat != null) {
            filestat.write_bytes(
              new DataView(self.inst.exports.memory.buffer),
              filestat_ptr
            );
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_filestat_set_size(fd, size) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_filestat_set_size(size);
        } else {
          return ERRNO_BADF;
        }
      },
      fd_filestat_set_times(fd, atim, mtim, fst_flags) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_filestat_set_times(atim, mtim, fst_flags);
        } else {
          return ERRNO_BADF;
        }
      },
      fd_pread(fd, iovs_ptr, iovs_len, offset, nread_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const iovecs = Iovec.read_bytes_array(buffer, iovs_ptr, iovs_len);
          let nread = 0;
          for (const iovec of iovecs) {
            const { ret, data } = self.fds[fd].fd_pread(iovec.buf_len, offset);
            if (ret != ERRNO_SUCCESS) {
              buffer.setUint32(nread_ptr, nread, true);
              return ret;
            }
            buffer8.set(data, iovec.buf);
            nread += data.length;
            offset += BigInt(data.length);
            if (data.length != iovec.buf_len) {
              break;
            }
          }
          buffer.setUint32(nread_ptr, nread, true);
          return ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_prestat_get(fd, buf_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const { ret, prestat } = self.fds[fd].fd_prestat_get();
          if (prestat != null) {
            prestat.write_bytes(buffer, buf_ptr);
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_prestat_dir_name(fd, path_ptr, path_len) {
        if (self.fds[fd] != void 0) {
          const { ret, prestat } = self.fds[fd].fd_prestat_get();
          if (prestat == null) {
            return ret;
          }
          const prestat_dir_name = prestat.inner.pr_name;
          const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
          buffer8.set(prestat_dir_name.slice(0, path_len), path_ptr);
          return prestat_dir_name.byteLength > path_len
            ? ERRNO_NAMETOOLONG
            : ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_pwrite(fd, iovs_ptr, iovs_len, offset, nwritten_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const iovecs = Ciovec.read_bytes_array(buffer, iovs_ptr, iovs_len);
          let nwritten = 0;
          for (const iovec of iovecs) {
            const data = buffer8.slice(iovec.buf, iovec.buf + iovec.buf_len);
            const { ret, nwritten: nwritten_part } = self.fds[fd].fd_pwrite(
              data,
              offset
            );
            if (ret != ERRNO_SUCCESS) {
              buffer.setUint32(nwritten_ptr, nwritten, true);
              return ret;
            }
            nwritten += nwritten_part;
            offset += BigInt(nwritten_part);
            if (nwritten_part != data.byteLength) {
              break;
            }
          }
          buffer.setUint32(nwritten_ptr, nwritten, true);
          return ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_read(fd, iovs_ptr, iovs_len, nread_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const iovecs = Iovec.read_bytes_array(buffer, iovs_ptr, iovs_len);
          let nread = 0;
          for (const iovec of iovecs) {
            const { ret, data } = self.fds[fd].fd_read(iovec.buf_len);
            if (ret != ERRNO_SUCCESS) {
              buffer.setUint32(nread_ptr, nread, true);
              return ret;
            }
            buffer8.set(data, iovec.buf);
            nread += data.length;
            if (data.length != iovec.buf_len) {
              break;
            }
          }
          buffer.setUint32(nread_ptr, nread, true);
          return ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_readdir(fd, buf, buf_len, cookie, bufused_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          let bufused = 0;
          while (true) {
            const { ret, dirent } = self.fds[fd].fd_readdir_single(cookie);
            if (ret != 0) {
              buffer.setUint32(bufused_ptr, bufused, true);
              return ret;
            }
            if (dirent == null) {
              break;
            }
            if (buf_len - bufused < dirent.head_length()) {
              bufused = buf_len;
              break;
            }
            const head_bytes = new ArrayBuffer(dirent.head_length());
            dirent.write_head_bytes(new DataView(head_bytes), 0);
            buffer8.set(
              new Uint8Array(head_bytes).slice(
                0,
                Math.min(head_bytes.byteLength, buf_len - bufused)
              ),
              buf
            );
            buf += dirent.head_length();
            bufused += dirent.head_length();
            if (buf_len - bufused < dirent.name_length()) {
              bufused = buf_len;
              break;
            }
            dirent.write_name_bytes(buffer8, buf, buf_len - bufused);
            buf += dirent.name_length();
            bufused += dirent.name_length();
            cookie = dirent.d_next;
          }
          buffer.setUint32(bufused_ptr, bufused, true);
          return 0;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_renumber(fd, to) {
        if (self.fds[fd] != void 0 && self.fds[to] != void 0) {
          const ret = self.fds[to].fd_close();
          if (ret != 0) {
            return ret;
          }
          self.fds[to] = self.fds[fd];
          self.fds[fd] = void 0;
          return 0;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_seek(fd, offset, whence, offset_out_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const { ret, offset: offset_out } = self.fds[fd].fd_seek(
            offset,
            whence
          );
          buffer.setBigInt64(offset_out_ptr, offset_out, true);
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_sync(fd) {
        if (self.fds[fd] != void 0) {
          return self.fds[fd].fd_sync();
        } else {
          return ERRNO_BADF;
        }
      },
      fd_tell(fd, offset_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const { ret, offset } = self.fds[fd].fd_tell();
          buffer.setBigUint64(offset_ptr, offset, true);
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      fd_write(fd, iovs_ptr, iovs_len, nwritten_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const iovecs = Ciovec.read_bytes_array(buffer, iovs_ptr, iovs_len);
          let nwritten = 0;
          for (const iovec of iovecs) {
            const data = buffer8.slice(iovec.buf, iovec.buf + iovec.buf_len);
            const { ret, nwritten: nwritten_part } =
              self.fds[fd].fd_write(data);
            if (ret != ERRNO_SUCCESS) {
              buffer.setUint32(nwritten_ptr, nwritten, true);
              return ret;
            }
            nwritten += nwritten_part;
            if (nwritten_part != data.byteLength) {
              break;
            }
          }
          buffer.setUint32(nwritten_ptr, nwritten, true);
          return ERRNO_SUCCESS;
        } else {
          return ERRNO_BADF;
        }
      },
      path_create_directory(fd, path_ptr, path_len) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          return self.fds[fd].path_create_directory(path);
        } else {
          return ERRNO_BADF;
        }
      },
      path_filestat_get(fd, flags, path_ptr, path_len, filestat_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          const { ret, filestat } = self.fds[fd].path_filestat_get(flags, path);
          if (filestat != null) {
            filestat.write_bytes(buffer, filestat_ptr);
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      path_filestat_set_times(
        fd,
        flags,
        path_ptr,
        path_len,
        atim,
        mtim,
        fst_flags
      ) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          return self.fds[fd].path_filestat_set_times(
            flags,
            path,
            atim,
            mtim,
            fst_flags
          );
        } else {
          return ERRNO_BADF;
        }
      },
      path_link(
        old_fd,
        old_flags,
        old_path_ptr,
        old_path_len,
        new_fd,
        new_path_ptr,
        new_path_len
      ) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[old_fd] != void 0 && self.fds[new_fd] != void 0) {
          const old_path = new TextDecoder("utf-8").decode(
            buffer8.slice(old_path_ptr, old_path_ptr + old_path_len)
          );
          const new_path = new TextDecoder("utf-8").decode(
            buffer8.slice(new_path_ptr, new_path_ptr + new_path_len)
          );
          const { ret, inode_obj } = self.fds[old_fd].path_lookup(
            old_path,
            old_flags
          );
          if (inode_obj == null) {
            return ret;
          }
          return self.fds[new_fd].path_link(new_path, inode_obj, false);
        } else {
          return ERRNO_BADF;
        }
      },
      path_open(
        fd,
        dirflags,
        path_ptr,
        path_len,
        oflags,
        fs_rights_base,
        fs_rights_inheriting,
        fd_flags,
        opened_fd_ptr
      ) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          debug.log(path);
          const { ret, fd_obj } = self.fds[fd].path_open(
            dirflags,
            path,
            oflags,
            fs_rights_base,
            fs_rights_inheriting,
            fd_flags
          );
          if (ret != 0) {
            return ret;
          }
          self.fds.push(fd_obj);
          const opened_fd = self.fds.length - 1;
          buffer.setUint32(opened_fd_ptr, opened_fd, true);
          return 0;
        } else {
          return ERRNO_BADF;
        }
      },
      path_readlink(fd, path_ptr, path_len, buf_ptr, buf_len, nread_ptr) {
        const buffer = new DataView(self.inst.exports.memory.buffer);
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          debug.log(path);
          const { ret, data } = self.fds[fd].path_readlink(path);
          if (data != null) {
            const data_buf = new TextEncoder().encode(data);
            if (data_buf.length > buf_len) {
              buffer.setUint32(nread_ptr, 0, true);
              return ERRNO_BADF;
            }
            buffer8.set(data_buf, buf_ptr);
            buffer.setUint32(nread_ptr, data_buf.length, true);
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      path_remove_directory(fd, path_ptr, path_len) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          return self.fds[fd].path_remove_directory(path);
        } else {
          return ERRNO_BADF;
        }
      },
      path_rename(
        fd,
        old_path_ptr,
        old_path_len,
        new_fd,
        new_path_ptr,
        new_path_len
      ) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0 && self.fds[new_fd] != void 0) {
          const old_path = new TextDecoder("utf-8").decode(
            buffer8.slice(old_path_ptr, old_path_ptr + old_path_len)
          );
          const new_path = new TextDecoder("utf-8").decode(
            buffer8.slice(new_path_ptr, new_path_ptr + new_path_len)
          );
          let { ret, inode_obj } = self.fds[fd].path_unlink(old_path);
          if (inode_obj == null) {
            return ret;
          }
          ret = self.fds[new_fd].path_link(new_path, inode_obj, true);
          if (ret != ERRNO_SUCCESS) {
            if (
              self.fds[fd].path_link(old_path, inode_obj, true) != ERRNO_SUCCESS
            ) {
              throw "path_link should always return success when relinking an inode back to the original place";
            }
          }
          return ret;
        } else {
          return ERRNO_BADF;
        }
      },
      path_symlink(old_path_ptr, old_path_len, fd, new_path_ptr, new_path_len) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const old_path = new TextDecoder("utf-8").decode(
            buffer8.slice(old_path_ptr, old_path_ptr + old_path_len)
          );
          const new_path = new TextDecoder("utf-8").decode(
            buffer8.slice(new_path_ptr, new_path_ptr + new_path_len)
          );
          return ERRNO_NOTSUP;
        } else {
          return ERRNO_BADF;
        }
      },
      path_unlink_file(fd, path_ptr, path_len) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        if (self.fds[fd] != void 0) {
          const path = new TextDecoder("utf-8").decode(
            buffer8.slice(path_ptr, path_ptr + path_len)
          );
          return self.fds[fd].path_unlink_file(path);
        } else {
          return ERRNO_BADF;
        }
      },
      poll_oneoff(in_, out, nsubscriptions) {
        throw "async io not supported";
      },
      proc_exit(exit_code) {
        throw new WASIProcExit(exit_code);
      },
      proc_raise(sig) {
        throw "raised signal " + sig;
      },
      sched_yield() {},
      random_get(buf, buf_len) {
        const buffer8 = new Uint8Array(self.inst.exports.memory.buffer);
        for (let i = 0; i < buf_len; i++) {
          buffer8[buf + i] = (Math.random() * 256) | 0;
        }
      },
      sock_recv(fd, ri_data, ri_flags) {
        throw "sockets not supported";
      },
      sock_send(fd, si_data, si_flags) {
        throw "sockets not supported";
      },
      sock_shutdown(fd, how) {
        throw "sockets not supported";
      },
      sock_accept(fd, flags) {
        throw "sockets not supported";
      },
    };
  }
};

// node_modules/@bjorn3/browser_wasi_shim/dist/fd.js
var Fd = class {
  fd_allocate(offset, len) {
    return ERRNO_NOTSUP;
  }
  fd_close() {
    return 0;
  }
  fd_fdstat_get() {
    return { ret: ERRNO_NOTSUP, fdstat: null };
  }
  fd_fdstat_set_flags(flags) {
    return ERRNO_NOTSUP;
  }
  fd_fdstat_set_rights(fs_rights_base, fs_rights_inheriting) {
    return ERRNO_NOTSUP;
  }
  fd_filestat_get() {
    return { ret: ERRNO_NOTSUP, filestat: null };
  }
  fd_filestat_set_size(size) {
    return ERRNO_NOTSUP;
  }
  fd_filestat_set_times(atim, mtim, fst_flags) {
    return ERRNO_NOTSUP;
  }
  fd_pread(size, offset) {
    return { ret: ERRNO_NOTSUP, data: new Uint8Array() };
  }
  fd_prestat_get() {
    return { ret: ERRNO_NOTSUP, prestat: null };
  }
  fd_pwrite(data, offset) {
    return { ret: ERRNO_NOTSUP, nwritten: 0 };
  }
  fd_read(size) {
    return { ret: ERRNO_NOTSUP, data: new Uint8Array() };
  }
  fd_readdir_single(cookie) {
    return { ret: ERRNO_NOTSUP, dirent: null };
  }
  fd_seek(offset, whence) {
    return { ret: ERRNO_NOTSUP, offset: 0n };
  }
  fd_sync() {
    return 0;
  }
  fd_tell() {
    return { ret: ERRNO_NOTSUP, offset: 0n };
  }
  fd_write(data) {
    return { ret: ERRNO_NOTSUP, nwritten: 0 };
  }
  path_create_directory(path) {
    return ERRNO_NOTSUP;
  }
  path_filestat_get(flags, path) {
    return { ret: ERRNO_NOTSUP, filestat: null };
  }
  path_filestat_set_times(flags, path, atim, mtim, fst_flags) {
    return ERRNO_NOTSUP;
  }
  path_link(path, inode, allow_dir) {
    return ERRNO_NOTSUP;
  }
  path_unlink(path) {
    return { ret: ERRNO_NOTSUP, inode_obj: null };
  }
  path_lookup(path, dirflags) {
    return { ret: ERRNO_NOTSUP, inode_obj: null };
  }
  path_open(
    dirflags,
    path,
    oflags,
    fs_rights_base,
    fs_rights_inheriting,
    fd_flags
  ) {
    return { ret: ERRNO_NOTDIR, fd_obj: null };
  }
  path_readlink(path) {
    return { ret: ERRNO_NOTSUP, data: null };
  }
  path_remove_directory(path) {
    return ERRNO_NOTSUP;
  }
  path_rename(old_path, new_fd, new_path) {
    return ERRNO_NOTSUP;
  }
  path_unlink_file(path) {
    return ERRNO_NOTSUP;
  }
};
var Inode = class {};

// node_modules/@bjorn3/browser_wasi_shim/dist/fs_mem.js
var OpenFile = class extends Fd {
  fd_allocate(offset, len) {
    if (this.file.size > offset + len) {
    } else {
      const new_data = new Uint8Array(Number(offset + len));
      new_data.set(this.file.data, 0);
      this.file.data = new_data;
    }
    return ERRNO_SUCCESS;
  }
  fd_fdstat_get() {
    return { ret: 0, fdstat: new Fdstat(FILETYPE_REGULAR_FILE, 0) };
  }
  fd_filestat_set_size(size) {
    if (this.file.size > size) {
      this.file.data = new Uint8Array(
        this.file.data.buffer.slice(0, Number(size))
      );
    } else {
      const new_data = new Uint8Array(Number(size));
      new_data.set(this.file.data, 0);
      this.file.data = new_data;
    }
    return ERRNO_SUCCESS;
  }
  fd_read(size) {
    const slice = this.file.data.slice(
      Number(this.file_pos),
      Number(this.file_pos + BigInt(size))
    );
    this.file_pos += BigInt(slice.length);
    return { ret: 0, data: slice };
  }
  fd_pread(size, offset) {
    const slice = this.file.data.slice(
      Number(offset),
      Number(offset + BigInt(size))
    );
    return { ret: 0, data: slice };
  }
  fd_seek(offset, whence) {
    let calculated_offset;
    switch (whence) {
      case WHENCE_SET:
        calculated_offset = offset;
        break;
      case WHENCE_CUR:
        calculated_offset = this.file_pos + offset;
        break;
      case WHENCE_END:
        calculated_offset = BigInt(this.file.data.byteLength) + offset;
        break;
      default:
        return { ret: ERRNO_INVAL, offset: 0n };
    }
    if (calculated_offset < 0) {
      return { ret: ERRNO_INVAL, offset: 0n };
    }
    this.file_pos = calculated_offset;
    return { ret: 0, offset: this.file_pos };
  }
  fd_tell() {
    return { ret: 0, offset: this.file_pos };
  }
  fd_write(data) {
    if (this.file.readonly) return { ret: ERRNO_BADF, nwritten: 0 };
    if (this.file_pos + BigInt(data.byteLength) > this.file.size) {
      const old = this.file.data;
      this.file.data = new Uint8Array(
        Number(this.file_pos + BigInt(data.byteLength))
      );
      this.file.data.set(old);
    }
    this.file.data.set(data, Number(this.file_pos));
    this.file_pos += BigInt(data.byteLength);
    return { ret: 0, nwritten: data.byteLength };
  }
  fd_pwrite(data, offset) {
    if (this.file.readonly) return { ret: ERRNO_BADF, nwritten: 0 };
    if (offset + BigInt(data.byteLength) > this.file.size) {
      const old = this.file.data;
      this.file.data = new Uint8Array(Number(offset + BigInt(data.byteLength)));
      this.file.data.set(old);
    }
    this.file.data.set(data, Number(offset));
    return { ret: 0, nwritten: data.byteLength };
  }
  fd_filestat_get() {
    return { ret: 0, filestat: this.file.stat() };
  }
  constructor(file) {
    super();
    this.file_pos = 0n;
    this.file = file;
  }
};
var OpenDirectory = class extends Fd {
  fd_seek(offset, whence) {
    return { ret: ERRNO_BADF, offset: 0n };
  }
  fd_tell() {
    return { ret: ERRNO_BADF, offset: 0n };
  }
  fd_allocate(offset, len) {
    return ERRNO_BADF;
  }
  fd_fdstat_get() {
    return { ret: 0, fdstat: new Fdstat(FILETYPE_DIRECTORY, 0) };
  }
  fd_readdir_single(cookie) {
    if (debug.enabled) {
      debug.log("readdir_single", cookie);
      debug.log(cookie, this.dir.contents.keys());
    }
    if (cookie == 0n) {
      return {
        ret: ERRNO_SUCCESS,
        dirent: new Dirent(1n, ".", FILETYPE_DIRECTORY),
      };
    } else if (cookie == 1n) {
      return {
        ret: ERRNO_SUCCESS,
        dirent: new Dirent(2n, "..", FILETYPE_DIRECTORY),
      };
    }
    if (cookie >= BigInt(this.dir.contents.size) + 2n) {
      return { ret: 0, dirent: null };
    }
    const [name, entry] = Array.from(this.dir.contents.entries())[
      Number(cookie - 2n)
    ];
    return {
      ret: 0,
      dirent: new Dirent(cookie + 1n, name, entry.stat().filetype),
    };
  }
  path_filestat_get(flags, path_str) {
    const { ret: path_err, path } = Path.from(path_str);
    if (path == null) {
      return { ret: path_err, filestat: null };
    }
    const { ret, entry } = this.dir.get_entry_for_path(path);
    if (entry == null) {
      return { ret, filestat: null };
    }
    return { ret: 0, filestat: entry.stat() };
  }
  path_lookup(path_str, dirflags) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return { ret: path_ret, inode_obj: null };
    }
    const { ret, entry } = this.dir.get_entry_for_path(path);
    if (entry == null) {
      return { ret, inode_obj: null };
    }
    return { ret: ERRNO_SUCCESS, inode_obj: entry };
  }
  path_open(
    dirflags,
    path_str,
    oflags,
    fs_rights_base,
    fs_rights_inheriting,
    fd_flags
  ) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return { ret: path_ret, fd_obj: null };
    }
    let { ret, entry } = this.dir.get_entry_for_path(path);
    if (entry == null) {
      if (ret != ERRNO_NOENT) {
        return { ret, fd_obj: null };
      }
      if ((oflags & OFLAGS_CREAT) == OFLAGS_CREAT) {
        const { ret: ret2, entry: new_entry } = this.dir.create_entry_for_path(
          path_str,
          (oflags & OFLAGS_DIRECTORY) == OFLAGS_DIRECTORY
        );
        if (new_entry == null) {
          return { ret: ret2, fd_obj: null };
        }
        entry = new_entry;
      } else {
        return { ret: ERRNO_NOENT, fd_obj: null };
      }
    } else if ((oflags & OFLAGS_EXCL) == OFLAGS_EXCL) {
      return { ret: ERRNO_EXIST, fd_obj: null };
    }
    if (
      (oflags & OFLAGS_DIRECTORY) == OFLAGS_DIRECTORY &&
      entry.stat().filetype !== FILETYPE_DIRECTORY
    ) {
      return { ret: ERRNO_NOTDIR, fd_obj: null };
    }
    return entry.path_open(oflags, fs_rights_base, fd_flags);
  }
  path_create_directory(path) {
    return this.path_open(0, path, OFLAGS_CREAT | OFLAGS_DIRECTORY, 0n, 0n, 0)
      .ret;
  }
  path_link(path_str, inode, allow_dir) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return path_ret;
    }
    if (path.is_dir) {
      return ERRNO_NOENT;
    }
    const {
      ret: parent_ret,
      parent_entry,
      filename,
      entry,
    } = this.dir.get_parent_dir_and_entry_for_path(path, true);
    if (parent_entry == null || filename == null) {
      return parent_ret;
    }
    if (entry != null) {
      const source_is_dir = inode.stat().filetype == FILETYPE_DIRECTORY;
      const target_is_dir = entry.stat().filetype == FILETYPE_DIRECTORY;
      if (source_is_dir && target_is_dir) {
        if (allow_dir && entry instanceof Directory) {
          if (entry.contents.size == 0) {
          } else {
            return ERRNO_NOTEMPTY;
          }
        } else {
          return ERRNO_EXIST;
        }
      } else if (source_is_dir && !target_is_dir) {
        return ERRNO_NOTDIR;
      } else if (!source_is_dir && target_is_dir) {
        return ERRNO_ISDIR;
      } else if (
        inode.stat().filetype == FILETYPE_REGULAR_FILE &&
        entry.stat().filetype == FILETYPE_REGULAR_FILE
      ) {
      } else {
        return ERRNO_EXIST;
      }
    }
    if (!allow_dir && inode.stat().filetype == FILETYPE_DIRECTORY) {
      return ERRNO_PERM;
    }
    parent_entry.contents.set(filename, inode);
    return ERRNO_SUCCESS;
  }
  path_unlink(path_str) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return { ret: path_ret, inode_obj: null };
    }
    const {
      ret: parent_ret,
      parent_entry,
      filename,
      entry,
    } = this.dir.get_parent_dir_and_entry_for_path(path, true);
    if (parent_entry == null || filename == null) {
      return { ret: parent_ret, inode_obj: null };
    }
    if (entry == null) {
      return { ret: ERRNO_NOENT, inode_obj: null };
    }
    parent_entry.contents.delete(filename);
    return { ret: ERRNO_SUCCESS, inode_obj: entry };
  }
  path_unlink_file(path_str) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return path_ret;
    }
    const {
      ret: parent_ret,
      parent_entry,
      filename,
      entry,
    } = this.dir.get_parent_dir_and_entry_for_path(path, false);
    if (parent_entry == null || filename == null || entry == null) {
      return parent_ret;
    }
    if (entry.stat().filetype === FILETYPE_DIRECTORY) {
      return ERRNO_ISDIR;
    }
    parent_entry.contents.delete(filename);
    return ERRNO_SUCCESS;
  }
  path_remove_directory(path_str) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return path_ret;
    }
    const {
      ret: parent_ret,
      parent_entry,
      filename,
      entry,
    } = this.dir.get_parent_dir_and_entry_for_path(path, false);
    if (parent_entry == null || filename == null || entry == null) {
      return parent_ret;
    }
    if (
      !(entry instanceof Directory) ||
      entry.stat().filetype !== FILETYPE_DIRECTORY
    ) {
      return ERRNO_NOTDIR;
    }
    if (entry.contents.size !== 0) {
      return ERRNO_NOTEMPTY;
    }
    if (!parent_entry.contents.delete(filename)) {
      return ERRNO_NOENT;
    }
    return ERRNO_SUCCESS;
  }
  fd_filestat_get() {
    return { ret: 0, filestat: this.dir.stat() };
  }
  fd_filestat_set_size(size) {
    return ERRNO_BADF;
  }
  fd_read(size) {
    return { ret: ERRNO_BADF, data: new Uint8Array() };
  }
  fd_pread(size, offset) {
    return { ret: ERRNO_BADF, data: new Uint8Array() };
  }
  fd_write(data) {
    return { ret: ERRNO_BADF, nwritten: 0 };
  }
  fd_pwrite(data, offset) {
    return { ret: ERRNO_BADF, nwritten: 0 };
  }
  constructor(dir) {
    super();
    this.dir = dir;
  }
};
var PreopenDirectory = class extends OpenDirectory {
  fd_prestat_get() {
    return { ret: 0, prestat: Prestat.dir(this.prestat_name) };
  }
  constructor(name, contents) {
    super(new Directory(contents));
    this.prestat_name = name;
  }
};
var File = class extends Inode {
  path_open(oflags, fs_rights_base, fd_flags) {
    if (
      this.readonly &&
      (fs_rights_base & BigInt(RIGHTS_FD_WRITE)) == BigInt(RIGHTS_FD_WRITE)
    ) {
      return { ret: ERRNO_PERM, fd_obj: null };
    }
    if ((oflags & OFLAGS_TRUNC) == OFLAGS_TRUNC) {
      if (this.readonly) return { ret: ERRNO_PERM, fd_obj: null };
      this.data = new Uint8Array([]);
    }
    const file = new OpenFile(this);
    if (fd_flags & FDFLAGS_APPEND) file.fd_seek(0n, WHENCE_END);
    return { ret: ERRNO_SUCCESS, fd_obj: file };
  }
  get size() {
    return BigInt(this.data.byteLength);
  }
  stat() {
    return new Filestat(FILETYPE_REGULAR_FILE, this.size);
  }
  constructor(data, options) {
    super();
    this.data = new Uint8Array(data);
    this.readonly = !!options?.readonly;
  }
};
var Path = class Path2 {
  static from(path) {
    const self = new Path2();
    self.is_dir = path.endsWith("/");
    if (path.startsWith("/")) {
      return { ret: ERRNO_NOTCAPABLE, path: null };
    }
    if (path.includes("\0")) {
      return { ret: ERRNO_INVAL, path: null };
    }
    for (const component of path.split("/")) {
      if (component === "" || component === ".") {
        continue;
      }
      if (component === "..") {
        if (self.parts.pop() == void 0) {
          return { ret: ERRNO_NOTCAPABLE, path: null };
        }
        continue;
      }
      self.parts.push(component);
    }
    return { ret: ERRNO_SUCCESS, path: self };
  }
  to_path_string() {
    let s = this.parts.join("/");
    if (this.is_dir) {
      s += "/";
    }
    return s;
  }
  constructor() {
    this.parts = [];
    this.is_dir = false;
  }
};
var Directory = class extends Inode {
  path_open(oflags, fs_rights_base, fd_flags) {
    return { ret: ERRNO_SUCCESS, fd_obj: new OpenDirectory(this) };
  }
  stat() {
    return new Filestat(FILETYPE_DIRECTORY, 0n);
  }
  get_entry_for_path(path) {
    let entry = this;
    for (const component of path.parts) {
      if (!(entry instanceof Directory)) {
        return { ret: ERRNO_NOTDIR, entry: null };
      }
      const child = entry.contents.get(component);
      if (child !== void 0) {
        entry = child;
      } else {
        debug.log(component);
        return { ret: ERRNO_NOENT, entry: null };
      }
    }
    if (path.is_dir) {
      if (entry.stat().filetype != FILETYPE_DIRECTORY) {
        return { ret: ERRNO_NOTDIR, entry: null };
      }
    }
    return { ret: ERRNO_SUCCESS, entry };
  }
  get_parent_dir_and_entry_for_path(path, allow_undefined) {
    const filename = path.parts.pop();
    if (filename === void 0) {
      return {
        ret: ERRNO_INVAL,
        parent_entry: null,
        filename: null,
        entry: null,
      };
    }
    const { ret: entry_ret, entry: parent_entry } =
      this.get_entry_for_path(path);
    if (parent_entry == null) {
      return {
        ret: entry_ret,
        parent_entry: null,
        filename: null,
        entry: null,
      };
    }
    if (!(parent_entry instanceof Directory)) {
      return {
        ret: ERRNO_NOTDIR,
        parent_entry: null,
        filename: null,
        entry: null,
      };
    }
    const entry = parent_entry.contents.get(filename);
    if (entry === void 0) {
      if (!allow_undefined) {
        return {
          ret: ERRNO_NOENT,
          parent_entry: null,
          filename: null,
          entry: null,
        };
      } else {
        return { ret: ERRNO_SUCCESS, parent_entry, filename, entry: null };
      }
    }
    if (path.is_dir) {
      if (entry.stat().filetype != FILETYPE_DIRECTORY) {
        return {
          ret: ERRNO_NOTDIR,
          parent_entry: null,
          filename: null,
          entry: null,
        };
      }
    }
    return { ret: ERRNO_SUCCESS, parent_entry, filename, entry };
  }
  create_entry_for_path(path_str, is_dir) {
    const { ret: path_ret, path } = Path.from(path_str);
    if (path == null) {
      return { ret: path_ret, entry: null };
    }
    let {
      ret: parent_ret,
      parent_entry,
      filename,
      entry,
    } = this.get_parent_dir_and_entry_for_path(path, true);
    if (parent_entry == null || filename == null) {
      return { ret: parent_ret, entry: null };
    }
    if (entry != null) {
      return { ret: ERRNO_EXIST, entry: null };
    }
    debug.log("create", path);
    let new_child;
    if (!is_dir) {
      new_child = new File(new ArrayBuffer(0));
    } else {
      new_child = new Directory(/* @__PURE__ */ new Map());
    }
    parent_entry.contents.set(filename, new_child);
    entry = new_child;
    return { ret: ERRNO_SUCCESS, entry };
  }
  constructor(contents) {
    super();
    if (contents instanceof Array) {
      this.contents = new Map(contents);
    } else {
      this.contents = contents;
    }
  }
};
var ConsoleStdout = class extends Fd {
  fd_filestat_get() {
    const filestat = new Filestat(FILETYPE_CHARACTER_DEVICE, BigInt(0));
    return { ret: 0, filestat };
  }
  fd_fdstat_get() {
    const fdstat = new Fdstat(FILETYPE_CHARACTER_DEVICE, 0);
    fdstat.fs_rights_base = BigInt(RIGHTS_FD_WRITE);
    return { ret: 0, fdstat };
  }
  fd_write(data) {
    this.write(data);
    return { ret: 0, nwritten: data.byteLength };
  }
  static lineBuffered(write) {
    const dec = new TextDecoder("utf-8", { fatal: false });
    let line_buf = "";
    return new ConsoleStdout((buffer) => {
      line_buf += dec.decode(buffer, { stream: true });
      const lines = line_buf.split("\n");
      for (const [i, line] of lines.entries()) {
        if (i < lines.length - 1) {
          write(line);
        } else {
          line_buf = line;
        }
      }
    });
  }
  constructor(write) {
    super();
    this.write = write;
  }
};

// node_modules/wasm-imports-parser/index.js
function parseImports(moduleBytes) {
  if (moduleBytes instanceof Uint8Array) {
  } else if (moduleBytes instanceof ArrayBuffer) {
    moduleBytes = new Uint8Array(moduleBytes);
  } else if (moduleBytes.buffer instanceof ArrayBuffer) {
    moduleBytes = new Uint8Array(moduleBytes.buffer);
  } else {
    throw new Error(
      "Argument must be a buffer source, like Uint8Array or ArrayBuffer"
    );
  }
  const parseState = new ParseState(moduleBytes);
  parseMagicNumber(parseState);
  parseVersion(parseState);
  const types = [];
  const imports = [];
  while (parseState.hasMoreBytes()) {
    const sectionId = parseState.readByte();
    const sectionSize = parseState.readUnsignedLEB128();
    switch (sectionId) {
      case 1: {
        const typeCount = parseState.readUnsignedLEB128();
        for (let i = 0; i < typeCount; i++) {
          types.push(parseFunctionType(parseState));
        }
        break;
      }
      case 2: {
        const importCount = parseState.readUnsignedLEB128();
        for (let i = 0; i < importCount; i++) {
          const module = parseState.readName();
          const name = parseState.readName();
          const type = parseState.readByte();
          switch (type) {
            case 0:
              const index = parseState.readUnsignedLEB128();
              imports.push({
                module,
                name,
                kind: "function",
                type: types[index],
              });
              break;
            case 1:
              imports.push({
                module,
                name,
                kind: "table",
                type: parseTableType(parseState),
              });
              break;
            case 2:
              imports.push({
                module,
                name,
                kind: "memory",
                type: parseLimits(parseState),
              });
              break;
            case 3:
              imports.push({
                module,
                name,
                kind: "global",
                type: parseGlobalType(parseState),
              });
              break;
            default:
              throw new Error(`Unknown import descriptor type ${type}`);
          }
        }
        return imports;
      }
      default: {
        parseState.skipBytes(sectionSize);
        break;
      }
    }
  }
  return [];
}
var ParseState = class {
  constructor(moduleBytes) {
    this.moduleBytes = moduleBytes;
    this.offset = 0;
    this.textDecoder = new TextDecoder("utf-8");
  }
  hasMoreBytes() {
    return this.offset < this.moduleBytes.length;
  }
  readByte() {
    return this.moduleBytes[this.offset++];
  }
  skipBytes(count) {
    this.offset += count;
  }
  readUnsignedLEB128() {
    let result = 0;
    let shift = 0;
    let byte;
    do {
      byte = this.readByte();
      result |= (byte & 127) << shift;
      shift += 7;
    } while (byte & 128);
    return result;
  }
  readName() {
    const nameLength = this.readUnsignedLEB128();
    const nameBytes = this.moduleBytes.slice(
      this.offset,
      this.offset + nameLength
    );
    const name = this.textDecoder.decode(nameBytes);
    this.offset += nameLength;
    return name;
  }
  assertBytes(expected) {
    const baseOffset = this.offset;
    const expectedLength = expected.length;
    for (let i = 0; i < expectedLength; i++) {
      if (this.moduleBytes[baseOffset + i] !== expected[i]) {
        throw new Error(`Expected ${expected} at offset ${baseOffset}`);
      }
    }
    this.offset += expectedLength;
  }
};
function parseMagicNumber(parseState) {
  const expected = [0, 97, 115, 109];
  parseState.assertBytes(expected);
}
function parseVersion(parseState) {
  const expected = [1, 0, 0, 0];
  parseState.assertBytes(expected);
}
function parseTableType(parseState) {
  const elementType = parseState.readByte();
  let element;
  switch (elementType) {
    case 112:
      element = "funcref";
      break;
    case 111:
      element = "externref";
      break;
    default:
      throw new Error(`Unknown table element type ${elementType}`);
  }
  const { minimum, maximum } = parseLimits(parseState);
  if (maximum) {
    return { element, minimum, maximum };
  } else {
    return { element, minimum };
  }
}
function parseLimits(parseState) {
  const flags = parseState.readByte();
  const minimum = parseState.readUnsignedLEB128();
  const hasMaximum = flags & 1;
  const shared = (flags & 2) !== 0;
  const isMemory64 = (flags & 4) !== 0;
  const index = isMemory64 ? "i64" : "i32";
  if (hasMaximum) {
    const maximum = parseState.readUnsignedLEB128();
    return { minimum, shared, index, maximum };
  } else {
    return { minimum, shared, index };
  }
}
function parseGlobalType(parseState) {
  const value = parseValueType(parseState);
  const mutable = parseState.readByte() === 1;
  return { value, mutable };
}
function parseValueType(parseState) {
  const type = parseState.readByte();
  switch (type) {
    case 127:
      return "i32";
    case 126:
      return "i64";
    case 125:
      return "f32";
    case 124:
      return "f64";
    case 112:
      return "funcref";
    case 111:
      return "externref";
    default:
      throw new Error(`Unknown value type ${type}`);
  }
}
function parseFunctionType(parseState) {
  const form = parseState.readByte();
  if (form !== 96) {
    throw new Error(`Expected function type form 0x60, got ${form}`);
  }
  const parameters = [];
  const parameterCount = parseState.readUnsignedLEB128();
  for (let i = 0; i < parameterCount; i++) {
    parameters.push(parseValueType(parseState));
  }
  const results = [];
  const resultCount = parseState.readUnsignedLEB128();
  for (let i = 0; i < resultCount; i++) {
    results.push(parseValueType(parseState));
  }
  return { parameters, results };
}

// node_modules/wasm-imports-parser/polyfill.js
var hasWasmTypeReflectionSupport = (() => {
  const moduleBytes = new Uint8Array([
    0, 97, 115, 109, 1, 0, 0, 0, 2, 6, 1, 0, 0, 2, 0, 1,
  ]);
  const module = new WebAssembly.Module(moduleBytes);
  const imports = WebAssembly.Module.imports(module);
  const memoryImport = imports[0];
  return typeof memoryImport.type === "object";
})();
function polyfill(WebAssembly2) {
  if (hasWasmTypeReflectionSupport) {
    return WebAssembly2;
  }
  const newWebAssembly = {};
  for (const key in Object.getOwnPropertyDescriptors(WebAssembly2)) {
    newWebAssembly[key] = WebAssembly2[key];
  }
  const newModule = (newWebAssembly.Module = function (bytes) {
    const module = new WebAssembly2.Module(bytes);
    module[sourceBytesSymbol] = bytes;
    Object.setPrototypeOf(module, newModule.prototype);
    return module;
  });
  Object.setPrototypeOf(newModule.prototype, WebAssembly2.Module.prototype);
  const sourceBytesSymbol = Symbol("sourceBytes");
  newWebAssembly.compile = async (source) => {
    const module = await WebAssembly2.compile(source);
    module[sourceBytesSymbol] = source;
    return module;
  };
  if (WebAssembly2.compileStreaming) {
    newWebAssembly.compileStreaming = async (source) => {
      const response = await source;
      const clone = response.clone();
      const module = await WebAssembly2.compileStreaming(response);
      module[sourceBytesSymbol] = new Uint8Array(await clone.arrayBuffer());
      return module;
    };
  }
  newModule.imports = (module) => {
    const sourceBytes = module[sourceBytesSymbol];
    if (!sourceBytes) {
      return WebAssembly2.Module.imports(module);
    }
    return parseImports(sourceBytes);
  };
  return newWebAssembly;
}

// entrypoint/common.ts
globalThis.WebAssembly = polyfill(globalThis.WebAssembly);
var LineDecoder = class {
  constructor(onLine) {
    this.decoder = new TextDecoder("utf-8", { fatal: false });
    this.buffer = "";
    this.onLine = onLine;
  }
  decoder;
  buffer;
  onLine;
  send(chunk) {
    this.buffer += this.decoder.decode(chunk, { stream: true });
    const lines = this.buffer.split("\n");
    for (let i = 0; i < lines.length - 1; i++) {
      this.onLine(lines[i]);
    }
    this.buffer = lines[lines.length - 1];
  }
};
var WasmRunner = (rawOptions, SwiftRuntime) => {
  const options = defaultRunnerOptions(rawOptions);
  let swift;
  if (SwiftRuntime) {
    swift = new SwiftRuntime();
  }
  let stdoutLine = void 0;
  if (options.onStdoutLine != null) {
    stdoutLine = new LineDecoder(options.onStdoutLine);
  }
  const stdout = new ConsoleStdout((chunk) => {
    options.onStdout?.call(void 0, chunk);
    stdoutLine?.send(chunk);
  });
  let stderrLine = void 0;
  if (options.onStderrLine != null) {
    stderrLine = new LineDecoder(options.onStderrLine);
  }
  const stderr = new ConsoleStdout((chunk) => {
    options.onStderr?.call(void 0, chunk);
    stderrLine?.send(chunk);
  });
  const args = options.args || [];
  const fds = [
    new OpenFile(new File([])),
    stdout,
    stderr,
    new PreopenDirectory("/", /* @__PURE__ */ new Map()),
  ];
  const wasi = new WASI(args, [], fds, {
    debug: false,
  });
  const createWasmImportObject = (extraWasmImports, module) => {
    const importObject = {
      wasi_snapshot_preview1: wasi.wasiImport,
    };
    if (swift) {
      importObject.javascript_kit = swift.wasmImports;
    }
    if (extraWasmImports) {
      for (const moduleName in extraWasmImports) {
        if (!importObject[moduleName]) {
          importObject[moduleName] = {};
        }
        for (const entry in extraWasmImports[moduleName]) {
          importObject[moduleName][entry] = extraWasmImports[moduleName][entry];
        }
      }
    }
    for (const _importEntry of WebAssembly.Module.imports(module)) {
      const importEntry = _importEntry;
      if (!importObject[importEntry.module]) {
        importObject[importEntry.module] = {};
      }
      if (importObject[importEntry.module][importEntry.name]) {
        continue;
      }
      if (importEntry.kind == "function") {
        importObject[importEntry.module][importEntry.name] = () => {
          throw new Error(
            `Imported function ${importEntry.module}.${importEntry.name} not implemented`
          );
        };
      } else if (
        importEntry.kind == "memory" &&
        importEntry.module == "env" &&
        importEntry.name == "memory"
      ) {
        const type = importEntry.type;
        const descriptor = {
          initial: type.minimum,
          maximum: type.maximum,
          shared: type.shared,
        };
        importObject[importEntry.module][importEntry.name] =
          new WebAssembly.Memory(descriptor);
      }
    }
    return importObject;
  };
  return {
    async run(wasmBytes, extraWasmImports) {
      if (!extraWasmImports) {
        extraWasmImports = {};
      }
      extraWasmImports.__stack_sanitizer = {
        report_stack_overflow: () => {
          throw new Error("Detected stack buffer overflow.");
        },
      };
      const module = await WebAssembly.compile(wasmBytes);
      const importObject = createWasmImportObject(extraWasmImports, module);
      const instance = await WebAssembly.instantiate(module, importObject);
      if (swift && instance.exports.swjs_library_version) {
        swift.setInstance(instance);
      }
      if (typeof instance.exports._start === "function") {
        wasi.start(instance);
      } else if (typeof instance.exports._initialize == "function") {
        wasi.initialize(instance);
        if (swift && swift.main) {
          swift.main();
        } else {
          if (typeof instance.exports.main === "function") {
            instance.exports.main();
          } else if (typeof instance.exports.__main_argc_argv === "function") {
            instance.exports.__main_argc_argv(0, 0);
          }
        }
      }
    },
  };
};
var defaultRunnerOptions = (options) => {
  if (options.args == null) {
    options.args = ["main.wasm"];
  }
  return options;
};

// entrypoint/bundle.ts
var startWasiTask = async () => {
  const response = await fetch("app.wasm");
  const responseArrayBuffer = await response.arrayBuffer();
  let runtimeConstructor = void 0;
  try {
    const { SwiftRuntime } = await import(
      // @ts-ignore
      "./JavaScriptKit_JavaScriptKit.resources/Runtime/index.mjs"
    );
    runtimeConstructor = SwiftRuntime;
  } catch {}
  const wasmRunner = WasmRunner(
    {
      onStdoutLine(line) {
        console.log(line);
      },
      onStderrLine(line) {
        console.error(line);
      },
    },
    runtimeConstructor
  );
  const wasmBytes = new Uint8Array(responseArrayBuffer).buffer;
  await wasmRunner.run(wasmBytes);
};
async function main() {
  await startWasiTask();
}
main();

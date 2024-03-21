# lua-io-reader

[![test](https://github.com/mah0x211/lua-io-reader/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-io-reader/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-io-reader/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-io-reader)

A reader that reads data from a file or file descriptor.


## Installation

```
luarocks install io-reader
```


## Error Handling

the following functions return the `error` object created by https://github.com/mah0x211/lua-errno module.


## r, err = io.reader(f)

create a new reader instance that reads data from a file or file descriptor.

**Parameters**

- `f:file*|integer`: file or file descriptor.

**Returns**

- `r:reader`: a reader instance.
- `err:any`: error message.


## s, err, timeout = reader:read(fmt, sec)

read data from the file or file descriptor.

**Parameters**

- `fmt:integer|string`: size of data to read, or format string as follows: (`*` prefix can be omitted)
  - `*a`: reads all data.
  - `*l`: reads a line. (default)
  - `*L`: reads a line with the newline character.
- `sec:number`: timeout seconds.

**Returns**

- `s:string`: read data.
- `err:any`: error message.
- `timeout:boolean`: `true` if timed out.

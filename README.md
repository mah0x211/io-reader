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


## r, err = io.reader.new( f [, sec] )

create a new reader instance that reads data from a file or file descriptor.

**Parameters**

- `f:file*|string|integer`: file, filename or file descriptor.
- `sec:number`: timeout seconds. (default `nil` means no timeout)

**Returns**

- `r:reader`: a reader instance.
- `err:any`: error message.


**Example**

```lua
local dump = require('dump')
local reader = require('io.reader')
local f = assert(io.tmpfile())
f:write('hello\r\nio\r\nreader\nworld!')
f:seek('set')
local r = reader.new(f)

-- it can read data from a file even if passed a file has been closed.
-- cause it duplicates the file descriptor by using `dup` system call internally.
f:close()

print(dump({
    r:read(4), -- read 4 bytes
    r:read('L'), -- read a line with delimiter
    r:read(), -- read a line without delimiter as default 'l'
    r:read('a'), -- read all data from the file
}))
-- {
--     [1] = "hell",
--     [2] = "o\13\
-- ",
--     [3] = "io",
--     [4] = "reader\
-- world!"
-- }
```


## s, err, timeout = reader:read( [fmt] )

read data from the file or file descriptor.

**Parameters**

- `fmt:integer|string`: size of data to read, or format string as follows: (`*` prefix can be omitted)
  - `*l`: reads a line. (default)
  - `*L`: reads a line with the newline character.
  - `*a`: reads all data.

**Returns**

- `s:string`: read data.
- `err:any`: error message.
- `timeout:boolean`: `true` if timed out.

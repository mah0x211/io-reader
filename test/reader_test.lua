require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local fileno = require('io.fileno')
local reader = require('io.reader')
local pipe = require('os.pipe')
local gettime = require('time.clock').gettime

local TEST_TXT = 'test.txt'

function testcase.before_all()
    local f = assert(io.open(TEST_TXT, 'w'))
    f:write('hello world')
    f:close()
end

function testcase.after_all()
    os.remove(TEST_TXT)
end

function testcase.new()
    local f = assert(io.tmpfile())
    local fd = fileno(f)

    -- test that create a new reader from file
    local r, err = reader.new(f)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that create a new reader from file with timeout seconds
    r, err = reader.new(f, 1)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that create a new reader from filename
    r, err = reader.new(TEST_TXT)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that return err if file not found
    r, err = reader.new('notfound.txt')
    assert.is_nil(r)
    assert.match(err, 'ENOENT')

    -- test that create a new reader from file descriptor
    r, err = reader.new(fd)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that create a new reader from pipe file descriptor
    local pr, _, perr = pipe(true)
    assert(perr == nil, perr)
    r, err = reader.new(pr:fd())
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that return err if file descriptor is invalid
    r, err = reader.new(-1)
    assert.is_nil(r)
    assert.match(err, 'EBADF')

    -- test that return err if invalid type of argument
    r, err = reader.new(true)
    assert.is_nil(r)
    assert.match(err, 'FILE*, pathname or file descriptor expected, got boolean')

    -- test that throws an error if invalid sec argument
    err = assert.throws(reader.new, f, true)
    assert.match(err, 'sec must be number or nil')
end

function testcase.getfd()
    -- test that get file descriptor and it is duplicated from file
    local f = assert(io.tmpfile())
    local r = assert(reader.new(f))
    assert.is_uint(r:getfd())
    assert.not_equal(r:getfd(), fileno(f))

    -- test that get file descriptor and it is duplicated from file descriptor
    local pr, _, err = pipe(true)
    assert(err == nil, err)
    r = assert(reader.new(pr:fd()))
    assert.is_uint(r:getfd())
    assert.not_equal(r:getfd(), pr:fd())
end

function testcase.read_with_format_string()
    local f = assert(io.tmpfile())
    local r = assert(reader.new(f))
    f:write('foo\nbar\r\nbaz\r\nqux')
    f:seek('set')

    -- test that read a line without delimiter as default
    local s, err, again = r:read()
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'foo')

    -- test that read a line with delimiter
    s, err, again = r:read('L')
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'bar\r\n')

    -- test that read all remaining bytes
    s, err, again = r:read('a')
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'baz\r\nqux')

    -- test that return nil if eof
    s, err, again = r:read()
    assert.is_nil(s)
    assert.is_nil(err)
    assert.is_nil(again)

    -- test that throws an error if invalid type of format
    err = assert.throws(r.read, r, true)
    assert.match(err, "fmt must be integer, string or nil")

    -- test that throws an error if invalid format
    err = assert.throws(r.read, r, 'x')
    assert.match(err, "fmt must be string as 'a', 'l' or 'L'")
end

function testcase.read_nbyte()
    local f = assert(io.tmpfile())
    local r = assert(reader.new(f))
    f:write('foo\nbar\r\nbaz\r\nqux')
    f:seek('set')

    -- test that read 5 bytes
    local s, err, again = r:read(5)
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'foo\nb')

    -- test that return nil if read 0 byte
    s, err, again = r:read(0)
    assert.is_nil(s)
    assert.is_nil(err)
    assert.is_nil(again)

    -- test that throws an error if specified negative number
    err = assert.throws(r.read, r, -1)
    assert.match(err, 'negative number')
end

function testcase.read_with_timeout()
    local pr, pw, perr = pipe(true)
    assert(perr == nil, perr)

    -- test that read timeout after 0.5 second
    local r = assert(reader.new(pr:fd(), .5))
    local t = gettime()
    local s, err, again = r:read()
    t = gettime() - t
    assert.is_nil(err)
    assert.is_nil(s)
    assert.is_true(again)
    assert.is_true(t >= .5 and t < .6)

    -- test that read line from pipe
    pw:write('hello\nio-reader\nworld!\n')
    s, err, again = r:read()
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'hello')

    -- test that read line from pipe even if peer of pipe is closed
    pw:close()
    s, err, again = r:read()
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'io-reader')

    -- test that read line from pipe even if pipe is closed
    pr:close()
    s, err, again = r:read()
    assert.is_nil(err)
    assert.is_nil(again)
    assert.equal(s, 'world!')

    -- test that return nil if eof
    s, err, again = r:read()
    assert.is_nil(s)
    assert.is_nil(err)
    assert.is_nil(again)
end

function testcase.close()
    local f = assert(io.tmpfile())
    local r = assert(reader.new(f))

    -- test that close the file associated
    local ok, err = r:close()
    assert.is_nil(err)
    assert.is_true(ok)

    -- test that close can be called multiple times
    ok, err = r:close()
    assert.is_nil(err)
    assert.is_true(ok)

    -- test that read method return error if reader is closed
    ok, err = r:read()
    assert.match(err, 'EBADF')
    assert.is_nil(ok)
end

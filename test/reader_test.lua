require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local fileno = require('io.fileno')
local reader = require('io.reader')

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
    -- test that create a new reader from filename
    local r, err = reader.new(TEST_TXT)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that return err if file not found
    r, err = reader.new('notfound.txt')
    assert.is_nil(r)
    assert.match(err, 'ENOENT')
end

function testcase.new_with_file()
    -- test that create a new reader from file
    local f = assert(io.tmpfile())
    local r, err = reader.new_with_file(f)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that return err if file is not a file
    r, err = reader.new_with_file(true)
    assert.is_nil(r)
    assert.match(err, 'FILE* expected, got boolean')
end

function testcase.new_with_fd()
    -- test that create a new reader from file descriptor
    local f = assert(io.tmpfile())
    local fd = fileno(f)
    local r, err = reader.new_with_fd(fd)
    assert.is_nil(err)
    assert.match(r, '^io.reader: ', false)

    -- test that return err if file descriptor is invalid
    r, err = reader.new_with_fd(-1)
    assert.is_nil(r)
    assert.match(err, 'EBADF')
end

function testcase.read_with_format_string()
    local f = assert(io.tmpfile())
    local r = assert(reader.new_with_file(f))
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
    local r = assert(reader.new_with_file(f))
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

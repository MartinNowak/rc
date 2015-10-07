/**
   Smart refs for reference counted memory management.

   Copyright: Martin Nowak 2015 - $(YEAR)
   License: $(LINK2 http://boost.org/LICENSE_1_0.txt, Boost License 1.0)
   Authors: $(LINK2 http://code.dawg.eu, Martin Nowak)
 */
module std.experimental.rc;

import core.stdc.stdlib;

///
struct RC(T)
{
    ///
    this(Args...)(auto ref Args args)
    {
        auto p = cast(Container*).malloc(Container.sizeof);
        import core.exception : onOutOfMemoryError;
        if (p is null)
            onOutOfMemoryError();
        p.count = 1;
        p.weakCount = 0;
        p.destroy = &.destroy!T;
        import std.conv : emplace;
        emplace(&p.payload, args);
        _p = p;
    }

    ///
    this(Weak!T weak)
    {
        auto p = weak._p;
        if (p is null || !p.count)
            return;
        ++p.count;
        _p = p;
    }

    ///
    ref T get() return
    {
        return _p.payload;
    }

    ///
    alias get this;

    ///
    this(this)
    {
        if (!isNull)
            ++_p.count;
    }

    ///
    ~this()
    {
        nullify();
    }

    ///
    bool isNull() const
    {
        return _p is null;
    }

    ///
    void nullify()
    {
        if (auto p = _p)
        {
            _p = null;
            if (--p.count)
                return;
            p.destroy(p.payload);
            if (!p.weakCount)
                .free(p);
        }
    }

    ///
    uint refCount() const
    {
        return isNull ? 0 : _p.count;
    }

    ///
    uint weakCount() const
    {
        return isNull ? 0 : _p.weakCount;
    }

private:
    struct Container
    {
        uint count;
        uint weakCount;
        void function(ref T) destroy;
        T payload;
    }

    Container *_p;
}

///
unittest
{
    auto val = RC!int(12);
    assert(val == 12);
    auto val2 = val;
    assert(val.refCount == 2);
    val2 += 3;
    assert(val == 15);
}

///
struct Weak(T)
{
    ///
    this(RC!T rc)
    {
        _p = rc._p;
        if (!isNull)
            ++_p.weakCount;
    }

    ///
    this(this)
    {
        if (!isNull)
            ++_p.weakCount;
    }

    ///
    ~this()
    {
        nullify();
    }

    ///
    bool isNull() const
    {
        return _p is null;
    }

    ///
    void nullify()
    {
        if (auto p = _p)
        {
            _p = null;
            if (--p.weakCount || p.count)
                return;
            .free(p);
        }
    }

private:
    RC!T.Container *_p;
}

///
struct Unique(T)
{
}

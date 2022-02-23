#!/usr/bin/env rdmd
import std.stdio;

import std.algorithm;
import std.range;
import std.container.dlist;

struct Box
{
    string name;
    int num;
}

void main()
{
    Manager man = new Manager();
    writefln("peers = %s", man.peers.map!(p => p.num));
    man.removeOne();
    writefln("peers = %s", man.peers);
    man.addOne();
    writefln("peers = %s", man.peers);
}

class Manager
{
    DList!Box peer_list;
    uint peer_list_version = 1;

    this ()
    {
        peer_list.insertBack(Box("a", 1));
        peer_list.insertBack(Box("b", 2));
        peer_list.insertBack(Box("c", 3));
    }

    public void removeOne ()
    {
        peer_list.linearRemoveElement(Box("b", 2));
        this.peer_list_version++;
    }

    public void addOne ()
    {
        peer_list.insertBack(Box("d", 4));
        this.peer_list_version++;
    }

    public auto peers () @safe nothrow pure
    {
        return PeerRange(&this.peer_list_version, &this.peer_list);
    }
}

/// A range over the list of peers that can be invalidated
public struct PeerRange
{
    // Pointer to the `peers` version
    private uint* manager_version;

    // Pointer to the peers list NetworkManager maintains
    private DList!Box* peers;

    // version of `peers` that we sliced
    private uint range_version;

    // Range over the `peers` with version `range_version`
    private DList!Box.Range range;

    this (uint* manager_version, DList!Box* peers) nothrow @safe pure
    {
        this.manager_version = manager_version;
        this.peers = peers;
        this.range_version = *this.manager_version;
        this.range = (*this.peers)[];
    }

    public void popFront () nothrow @safe
    {
        if (!this.checkIfInvalidated())
            this.range.popFront();
    }

    public bool empty () nothrow @safe
    {
        this.checkIfInvalidated();
        return this.range.empty();
    }

    public auto front () nothrow @safe
    {
        this.checkIfInvalidated();
        return this.range.front();
    }

    private bool checkIfInvalidated () nothrow @safe
    {
        if (*this.manager_version > this.range_version)
        {
            this.range_version = *this.manager_version;
            this.range = (*this.peers)[];
            return true;
        }
        return false;
    }
}

# Trigram Bench

For use in ZLS workspace symbols.

## Problem Statement

Definitions:
- Document: A Zig file.
- Declaration: A `u32` that represents a declaration. Only a name is exposed. The rest is considered a ZLS implementation detail for practical purposes.
- Symbol / Declaration Name: A `[]const u8` that is the name of a declaration.
- Index: Preprocessed state representing a document's symbols used to perform a search.
- Query / Search: A search query that will be matched with a trigram search described below.
- Trigram: A window over a string with window size 3 and stride 1. Our trigrams are Unicode-based and not byte-based and are case sensitive.
  Example: `Counter` is composed of the trigrams `Cou`, `oun`, `unt`, `nte` `ter`.

### Indexing

We begin by obtaining 10,000 symbols extracted from `zigwin32`'s `everything.zig` found in `symbols.txt`. Each symbol is given a declaration, from `0` to `9_999`. A list `declarations : Declaration (u32) -> Symbol ([]const u8)` exists and is used for checking the correctness of a search.

Each symbol is then split into its constituent trigrams, and a mapping `trigram_to_decls : Trigram -> []const Declaration` is created. This maps trigrams to the declarations whose names contain the trigram.

Currently there is one indexing method in `common.zig`. If your query method requires a different kind of indexing, let me (Auguste) know.

### Querying

We begin by splitting our query into its constituent trigrams. Then we access `trigram_to_decls` with each trigram and obtain the intersection of each decl list.

Let's walk through a made up example. We're searching for `Alloc`, which is composed of the trigrams `All`, `llo`, and `loc`.

We access the `trigram_to_decls` mapping for each trigram and obtain the following declaration lists for each trigram:
```
All -> { 0, 1, 3, 4, 7, 8 }
llo -> { 2, 3, 5, 6, 9 }
loc -> { 0, 2, 3, 10 }
```

We perform the intersection and obtain:
```
All ∩ llo ∩ loc -> { 2, 3 }
```

To check if this result makes sense, we can access `declarations`:
```
2 -> Allocator
3 -> ArenaAllocator
```

Success!

### Challenge

Can you come up with the most effective way of indexing/querying this data? Anything is permitted as long as it replicates the test results with a reasonable balance of memory usage and performance. If a trade-off between indexing and query time appears, we'd rather make indexing faster to prevent delays for users not/rarely utilizing workspace symbols.

Please use a `std.AutoArrayHashMapUnmanaged` as it's required for the binary fuse filter (this bench only operates on a single document, but ZLS will operate on thousands, so the filter used to prevent unnecessary accesses).

## Useful Stats

Our `trigram_to_decls` mapping has 10505 elements with an average of ~21 declarations (can be repeated) per trigram.

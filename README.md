# Prototype Gem Indexer

 * `indexer.rb` this will pull down specs from the current servers, and then
   build an full example of the proposed formats.
 * `example_*.rb` these are example reader programs. As you can see,
   read_versions.rb has comparable performance to read_marshal.rb under 1.9+.
 * `example_read_deps.rb` contains an example parser for the dependency format
   implemented by indexer. This format is particularly designed for resolver
   style use cases.
 * Some comments are also in the indexer itself.

## Formats

### names.list

This is just a line separated list of names, trivial to consume with xargs(1),
and any other tool.

Names may be sorted alphabetically, but don't have to be. For example:

```
# names.list
a_gem
bees_in_my_eyes
foo
```

### versions.list

This is a key -> values list of name to `version-platform`. While this
duplicates platform information, that duplication may not be worth extra format
complexities, as it is much more rare than the omitted default `ruby` platform.
This list is designed to be able to be easily joined using tools like awk(1) to
produce standard `name-version[-platform].gem` file names. It is also easy and
quick to parse with any modern ruby (see `read_versions.rb`).

An arbitrary number of lines at the beginning of the file may be metadata, in 

For example:

```
# versions.list
---
foo 0.0.1
bees_in_my_eyes 1.0,1.0.1,1.1,2.0
nokogiri 1.0.0-x86-mswin32-60,1.0.0,1.0.1,1.0.2,1.0.3,1.0.3-x86-mswin32-60,1.0.4-x86-mswin32-60,1.0.4,1.0.5,1.0.5-x86-mswin32-60
```

### deps/*

These files have a slightly more complex format, but for consistency they begin
with an outer level format that is similar to versions.list, with a space
separated key -> values list. Note that spaces are allowed in values, but there
is only one key -> values list per line (so `split(' ', 2)`).

The values format is more complex and presently non-standard, but it is a
textual representation of runtime only Gem::Dependency objects separated by
commas. The csv value format is:

`dependency_name:requirement1&requirement2`

This makes some assumptions: there are no names or requirements containing `:`
or `&` characters. I believe this is valid today. These characters could be
exchanged for non-printable characters or path characters if necessary, although
the relative human readability is a nice to have.

In order to support ruby and rubygems version requirements, there is a
second set of requirements that may be provided on each line, separated
from the gem requirements by the | character. After searching through
every current gem name, all three of : & and | are unused in any gem
name, and are not allowed to be used in any new gem name by the
rubygems.org name validation regex.

The requirements after the | character are currently limited to ruby and
rubygems, but could be expanded to include any arbitrary requirement in
the future. Code that parses those requirements should ignore unknown
keys for future compatibility.

```
# deps/nokogiri
1.0.0
1.1.6 rake:>= 0.7.1,activesupport:= 1.3.1,activerecord:= 1.14.4,actionpack:= 1.12.5,actionmailer:= 1.2.5,actionwebservice:= 1.1.6|ruby:> 1.8.7
1.5.7.rc2 |ruby:>= 1.8.7,rubygems:> 1.3.1
1.5.7.rc3 |rubygems:> 1.3.1
1.6.0-java mini_portile:~> 0.5.0
```

## Performance

TL;DR, as good or better than existing.

Full index from cached specs:
ruby indexer.rb  136.29s user 78.71s system 117% cpu 3:03.19 total

Old version index:
ruby example_read_marshal.rb  0.70s user 0.12s system 95% cpu 0.858 total

New version index:
ruby example_read_versions.rb  0.70s user 0.13s system 99% cpu 0.838 total

Parsing the rails dependency index:
ruby example_read_deps.rb  0.08s user 0.04s system 96% cpu 0.126 total

Bandwidth:
After generic gzip transport compression, the versions.list is half the size of
the old specs.4.8 marshal format. The deps entries are 20% the size of the specs
files (202mb vs 1.1gb), and a gzip tarball of all deps files is only 2.7MB, vs
20MB for all the marshalled specs. It may be sensible to periodically preseed
clients with these tarballs, followed by periodic incremental updates of single
files.  In all cases, it's important to note that these lightweight ascii
formats compress better through gzip, and also lend themselves to progressive
updates and efficient syncing.

General:

After caching all the gemspecs, on my Macbook Air, generation of these indices
for the whole of the rubygems.org gems data set took 3 mintes. Considering that
the reader examples also allow for progressive updates as they coerce all
file formats into a Hash, merging the progressive data, this could result in
near instantaneous usage for general rubygems servers and clients. It is
possible to operate in an append-only manner in normal operation, with
periodic full rebuilds, although that may require slightly more advanced
client semantics. The idea would follow using an HTTP Range query in order to
fetch any file data after a certain size (alongside a conditional fetch). The
additional complexity to the Range approach is merely that a checksum would be
required in order to detect corruption, and a full refetch would follow. These
additional HTTP semantics are still to be fleshed out, but it should be noted
that these semantics are also very well suited to rsync based mirroring systems.

Read performance for the versions + platforms list is almost exactly equal to
that of specs.4.8 on Ruby 1.9+, and is actually faster on JRuby than the marshal
format. On 1.8, performance is significantly worse than marshal, but not
insurmountable. Coupled with the fact that 1.8 is on the way out, this is likely
to be acceptable. The reader may be able to be further optimized.

There is some difference between `specs.4.8` and versions.list, specifically
that the versions in `versions.list` are plain text, whereas they are
`Gem::Version` objects in `specs.4.8`. This may lead to some other performance
issues later on in a working pipeline, however, as `Gem::Version` construction
is presently lazy, the real world impact of this change is minimal, other than
decoupling and reducing the size of the data format quite significantly.

Client performance for clients such as Bundler that consume the deps indexes
should improve in several ways. No application server is required for dependency
lists. Dependency lists can be cached on disk, and refected with conditional and
potentially range queries. The files are not currently compressed, as this would
cause potentially unnecessary disruption for progressive updates and prevent
range queries. By contrast, using HTTP transport compression appropriately, and
potentially enabling precompression as an http server side only optimization
should both simplify client code, and still enable fast and efficient data
transfers. On disk size for clients may increase slightly, however, this is
probably negligable.

## Shortcomings & TODOs

 * There's still one big index for versions. This may want to be split out.
 * The ASCII format may be brittle to extend, but it's probably no harder to
   change than Marshal.
 * Some example client implementations are needed, especially to demonstrate
   efficient HTTP semantics for fetching and caching multiple dependency files.
 * There are no checksums being generated for the files yet, potentially .md5
   and .sha1 should be generated alongside the indices.
 * There is no consideration yet for distribution platform signatures. These may
   be able to be added as files alongside, like the checksums, or they may want
   to be embedded. Embedding may result in more complex progressive updates and
   more complex parsing, which is not desired.

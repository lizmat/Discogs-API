use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $search := $discogs.search("nirvana");

isa-ok $search, Discogs::API::SearchResults,
  'did we get a search results object';

my @results := $search.results;
is +@results, 50, 'did we get correct number of results';

for @results -> $result {
    isa-ok $result, Discogs::API::SearchResult,
      'did we get a artist release object';

    ok $result.cover-image ~~ URL, 'did get a URL for resource-url';
    ok $result.id ~~ UInt, 'did get an unsigned integer for id';
    ok $result.master-id ~~ Any, 'did get Any for master id';  # can be null
    ok $result.master-url ~~ Any, 'did get a URL for master url'; # can be null
    ok $result.resource-url ~~ URL, 'did get a URL for resource url';
    ok $result.thumb ~~ URL, 'did get a URL for thumb';
    ok $result.title ~~ Str, 'did get a string for title';
    ok $result.type ~~ Str, 'did get a string for type';
    ok $result.uri ~~ URI, 'did we get a uri for uri';

    in-user-collection-wantlist-ok($result);
}

done-testing;

# vim: expandtab shiftwidth=4

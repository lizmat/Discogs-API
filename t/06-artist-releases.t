use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $id = 108713;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $artist-releases := $discogs.artist-releases($id);

isa-ok $artist-releases, Discogs::API::ArtistReleases,
  'did we get a artist releases';

my @releases := $artist-releases.releases;
is +@releases, 50, 'did we get correct number of releases';

for @releases -> $release {
    isa-ok $release, Discogs::API::ArtistRelease,
      'did we get a artist release object';

    ok $release.artist ~~ Str, 'did get a string for artist';
    ok $release.format ~~ Str, 'did get a string for format';
    ok $release.id ~~ UInt, 'did get an unsigned integer for id';
    ok $release.label ~~ Str, 'did get a string for label';
    ok $release.resource-url ~~ URL, 'did get a URL for resource-url';
    ok $release.role ~~ Str, 'did get a string for role';
    ok $release.status ~~ Status | Nil, 'did get a status for status';
    ok $release.thumb ~~ URL, 'did get a URL for thumb';
    ok $release.title ~~ Str, 'did get a string for title';
    ok $release.type ~~ Str, 'did get a string for type';
    ok $release.year ~~ Year, 'did get a year for year';

    in-collection-wantlist-ok($release);
}

done-testing;

# vim: expandtab shiftwidth=4

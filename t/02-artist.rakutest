use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $id = 108713;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $artist := $discogs.artist($id);

isa-ok $artist, Discogs::API::Artist, 'did we get an artist';
ok $artist.data-quality ~~ Quality, 'is data-quality ok';
is $artist.data-quality, "Needs Vote", 'is data-quality ok';
is $artist.id, $id, 'is id ok';

my @images := $artist.images;
is +@images, 4, 'did we get correct number of images';
image-ok($_) for @images;

my @members := $artist.members;
is +@members, 5, 'did we get correct number of members';
member-ok($_) for @members;

my @namevariations := $artist.namevariations;
is +@namevariations, 3, 'did we get correct number of name variations';

for @namevariations -> $namevariation {
    isa-ok $namevariation, Str, 'did we get a string for name variation';
}

isa-ok $artist.profile, Str, 'did we get a profile string';
ok $artist.releases-url ~~ URL, 'did we get a releases URL';
ok $artist.resource-url ~~ URL, 'did we get a resource URL';
ok $artist.uri ~~ URL, 'did we get a generic uri';

my @urls := $artist.urls;
is +@urls, 9, 'did we get correct number of urls';

for @urls -> $url {
    ok $url ~~ URL, 'did we get a URL for the artist';
}

done-testing;

# vim: expandtab shiftwidth=4

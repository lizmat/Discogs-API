use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $id = 1000;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $release := $discogs.master-release($id);

isa-ok $release, Discogs::API::MasterRelease, 'did we get a release';

my @artists := $release.artists;
is +@artists, 1, 'did we get correct number of artists';
artist-summary-ok($_) for @artists;

ok $release.data-quality ~~ Quality, 'did we get a data quality';
is $release.data-quality, "Correct", 'did we get correct data quality';

my @genres := $release.genres;
is +@genres, 1, 'did we get correct number of genres';
for @genres -> $genre {
    ok $genre ~~ Genre, 'did we get a genre string';
}

is $release.id, $id, 'is id ok';

my @images := $release.images;
is +@images, 7, 'did we get correct number of images';
image-ok($_) for @images;

ok $release.lowest-price ~~ Price, 'did we get correct price type';
is $release.lowest-price, 15.1, 'did we get correct lowest price';

is $release.main-release, 66785, 'is main release id ok';
ok $release.main-release-url ~~ URL, 'did we get a main release URL';
is $release.main-release-url,
  "https://api.discogs.com/releases/66785",
  'did we get a right main release URL';

is $release.most-recent-release, 66785, 'is most recent release id ok';
ok $release.most-recent-release-url ~~ URL,
  'did we get a most recent release URL';
is $release.most-recent-release-url,
  "https://api.discogs.com/releases/66785",
  'did we get a right main release URL';

is $release.num-for-sale, 13, 'did we get correct number for sale';

ok $release.resource-url ~~ URL, 'did we get a resource URL';
is $release.resource-url,
  "https://api.discogs.com/masters/1000",
  'did we get a right resource URL';

my @styles := $release.styles;
is +@styles, 1, 'did we get correct number of styles';
for @styles -> $style {
    ok $style ~~ Style, 'did we get a style string';
}

is $release.title, "Stardiver", 'did we get correct title';

my @tracks := $release.tracklist;
is +@tracks, 11, 'did we get correct number of tracks';
track-ok($_) for @tracks;

ok $release.uri ~~ URL, 'did we get a uri URL';
is $release.uri,
  "https://www.discogs.com/Electric-Universe-Stardiver/master/1000",
  'did we get a right resource URL';

ok $release.versions-url ~~ URL, 'did we get a versions URL';
is $release.versions-url,
  "https://api.discogs.com/masters/1000/versions",
  'did we get a right versions URL';

my @videos := $release.videos;
is +@videos, 11, 'did we get correct number of videos';
video-ok($_) for @videos;

ok $release.year ~~ UInt, 'did we get an unsigned int for year';
is $release.year, 1997, 'did we get the right year';

done-testing;

# vim: expandtab shiftwidth=4

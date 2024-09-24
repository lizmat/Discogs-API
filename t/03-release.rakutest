use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $id = 249504;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $release := $discogs.release($id);

isa-ok $release, Discogs::API::Release, 'did we get a release';

my @artists := $release.artists;
is +@artists, 1, 'did we get correct number of artists';
artist-summary-ok($_) for @artists;

is $release.artists-sort, "Rick Astley", 'is sorted artists ok';
is $release.average, 3.59, 'is average ok';

community-ok($release.community);

my @companies := $release.companies;
is +@companies, 11, 'did we get correct number of companies';
catalog-entry-ok($_) for @companies;

my @contributors := $release.contributors;
is +@contributors, 12, 'did we get correct number of contributors';
user-ok($_) for @contributors;;

is $release.count, 137, 'did we get correct count';
ok $release.country ~~ Country, 'did we get a country';
is $release.country, "UK", 'did we get correct country';
ok $release.data-quality ~~ Quality, 'did we get a data quality';
is $release.data-quality, "Needs Vote", 'did we get correct data quality';

ok $release.date-added ~~ DateTime, 'did we get a datetime';
is $release.date-added, "2004-04-30T08:10:05-07:00",
  'did we get the right datetime';
ok $release.date-changed ~~ DateTime, 'did we get a datetime';
is $release.date-changed, "2019-08-21T23:30:18-07:00",
  'did we get the right datetime';

is $release.estimated-weight, 60, 'did we get estimated weight';

my @extraartists := $release.extraartists;
is +@extraartists, 6, 'did we get correct number of artists';
artist-summary-ok($_) for @extraartists;

is $release.format-quantity, 1, 'did we get right format quantity';

my @formats := $release.formats;
is +@formats, 1, 'did we get correct number of formats';
format-ok($_) for @formats;;

my @genres := $release.genres;
is +@genres, 2, 'did we get correct number of genres';
for @genres -> $genre {
    ok $genre ~~ Genre, 'did we get a genre string';
}

is $release.have, 1788, 'did we get correct have';
is $release.id, $id, 'is id ok';

my @identifiers := $release.identifiers;
is +@identifiers, 12, 'did we get correct number of identifiers';
identifier-ok($_) for @identifiers;

my @images := $release.images;
is +@images, 4, 'did we get correct number of images';
image-ok($_) for @images;

my @labels := $release.labels;
is +@labels, 1, 'did we get correct number of labels';
catalog-entry-ok($_) for @labels;

ok $release.lowest-price ~~ Price, 'did we get correct price type';
is $release.lowest-price, 0.57, 'did we get correct lowest price';
is $release.master-id, 96559, 'is master-id ok';
ok $release.master-url ~~ URL, 'is master url a URL';
is $release.master-url, "https://api.discogs.com/masters/96559",
  'is master url ok';
ok $release.notes ~~ Str, 'are notes a string';
is $release.notes, q:to/NOTES/, 'are notes correct';
UK Release has a black label with the text "Manufactured In England" printed on it.

Sleeve:
℗ 1987 • BMG Records (UK) Ltd. © 1987 • BMG Records (UK) Ltd.
Distributed in the UK by BMG Records •  Distribué en Europe par BMG/Ariola • Vertrieb en Europa dürch BMG/Ariola.

Center labels:
℗ 1987 Pete Waterman Ltd.
Original Sound Recording made by PWL.
BMG Records (UK) Ltd. are the exclusive licensees for the world.

Durations do not appear on the release.
NOTES

is $release.num-for-sale, 90, 'did we get correct number for sale';
is $release.released-formatted, "Jul 1987",
  'did we get correct formatted release';
is $release.released, "1987-07-00", 'did we get correct released';

ok $release.resource-url ~~ URL, 'did we get a resource URL';
is $release.resource-url, "https://api.discogs.com/releases/249504",
  'did we get a right resource URL';

my @series := $release.series;
is +@series, 0, 'did we get correct number of series';
catalog-entry-ok($_) for @series;

user-ok($release.submitter);

my @tracks := $release.tracklist;
is +@tracks, 2, 'did we get correct number of tracks';
track-ok($_) for @tracks;

my @videos := $release.videos;
is +@videos, 8, 'did we get correct number of videos';
video-ok($_) for @videos;

is $release.want, 278, 'did we get correct want';

done-testing;

# vim: expandtab shiftwidth=4

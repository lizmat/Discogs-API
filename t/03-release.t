use Test;
use Discogs::API;

my $id = 249504;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $release := $discogs.release($id);

isa-ok $release, Discogs::API::Release, 'did we get a release';

my @artists := $release.artists;
is +@artists, 1, 'did we get correct number of artists';

for @artists -> $artist {
    isa-ok $artist, Discogs::API::ArtistSummary, 'did we get a summary';
    ok $artist.anv ~~ Str, 'did we get an artist name variation';
    ok $artist.id ~~ UInt, 'did we get an unsigned int as ID';
    ok $artist.join ~~ Str, 'did we get a join string';
    ok $artist.name ~~ Str, 'did we get a name';
    ok $artist.resource-url ~~ URL, 'did we get a resource URL';
    ok $artist.role ~~ Str, 'did we get a role string';
    ok $artist.tracks ~~ Str, 'did we get a tracks string';
}

is $release.artists-sort, "Rick Astley", 'is sorted artists ok';
is $release.average, 3.59, 'is average ok';

my $community := $release.community;
isa-ok $community, Discogs::API::Community, 'did we get a community';

my @contributors := $community.contributors;
is +@contributors, 12, 'did we get correct number of contributors';

for @contributors -> $contributor {
    isa-ok $contributor, Discogs::API::User, 'did we get a user';
    ok $contributor.resource-url ~~ URL, 'did we get a URL';
    ok $contributor.username ~~ Username, 'did we get a username';
}

ok $community.data-quality ~~ Quality, 'did we get a quality';
is $community.data-quality, "Needs Vote", 'did we get the correct quality';
is $community.have, 1788, 'did we get correct have';

my $rating := $community.rating;
isa-ok $rating, Discogs::API::Rating, 'did we get a Rating';
is $rating.average, 3.59, 'did we get correct average';
is $rating.count, 137, 'did we get correct count';

ok $community.status ~~ Status, 'did we get a status';
is $community.status, "Accepted", 'did we get the right status';

my $submitter := $community.submitter;
isa-ok $submitter, Discogs::API::User, 'did we get a submitter';
ok $submitter.resource-url ~~ URL, 'did we get a URL';
is $submitter.resource-url, "https://api.discogs.com/users/memory",
  'did we get the right URL';
ok $submitter.username ~~ Username, 'did we get a username';
is $submitter.username, "memory", 'did we get the right username';

is $community.want, 278, 'did we get correct want';

my @genres := $release.genres;
is +@genres, 2, 'did we get correct number of genres';

for @genres -> $genre {
    ok $genre ~~ Genre, 'did we get a genre string';
}

=finish

is $release.id, $id, 'is id ok';

for @images -> $image {
    isa-ok $image, Discogs::API::Image, 'did we get an image';
    ok $image.height ~~ UInt, 'did we get an integer height';
    ok $image.resource-url ~~ URL, 'did we get a URL resource';
    ok $image.type ~~ Str, 'did we get a Str type';
    ok $image.uri ~~ URL, 'did we get a uri';
    ok $image.uri150 ~~ URL, 'did we get a uri150';
    ok $image.width ~~ UInt, 'did we get an integer width';
}

my @members := $release.members;
is +@members, 5, 'did we get correct number of members';

for @members -> $member {
    isa-ok $member, Discogs::API::Member, 'did we get a member';
    ok $member.active ~~ Bool, 'did we get a bool for active';
    ok $member.id ~~ UInt, 'did we get an artist id';
    ok $member.name ~~ Str, 'did we get an artist name';
    ok $member.resource-url ~~ URL, 'did we get a resource URL';
}

my @namevariations := $release.namevariations;
is +@namevariations, 3, 'did we get correct number of name variations';

for @namevariations -> $namevariation {
    isa-ok $namevariation, Str, 'did we get a string for name variation';
}

isa-ok $release.profile, Str, 'did we get a profile string';
ok $release.releases-url ~~ URL, 'did we get a releases URL';
ok $release.resource-url ~~ URL, 'did we get a resource URL';
ok $release.uri ~~ URL, 'did we get a generic uri';

my @urls := $release.urls;
is +@urls, 9, 'did we get correct number of urls';

for @urls -> $url {
    ok $url ~~ URL, 'did we get a URL for the artist';
}

done-testing;

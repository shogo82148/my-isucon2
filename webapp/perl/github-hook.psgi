use strict;
use warnings;
use Plack;
use Plack::Request;
use JSON;
use File::chdir;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $success = [200, [], ['']];

    my $payload = $req->param('payload');
    return [403, [], ['forbidden']]
        unless $req->method eq 'POST' and $payload;

    my $json = decode_json($payload);

    use Data::Dumper;
    warn Dumper $json;

    return $success unless $json->{commits};

    (my $branch = $json->{ref}) =~ s!refs/heads/!!;
    return $success if $branch =~ /refs\/tags\//;
    return $success if $json->{after} =~ /^0+$/;

    local $CWD = '/home/isu-user/isucon2';
    system 'git', qw!--git-dir=.git fetch!;
    system 'git', qw!--git-dir=.git checkout!, $branch;
    system 'git', qw!--git-dir=.git reset --hard!, "origin/$branch";
    system qw!sudo supervisorctl restart isu2webapp!;

    return $success;
};

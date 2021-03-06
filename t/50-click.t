#!perl -w
use strict;
use Test::More;
use WWW::Mechanize::Firefox;

my $mech = eval { WWW::Mechanize::Firefox->new( 
    autodie => 0,
    events => ['DOMContentLoaded', 'load', qw[DOMFrameContentLoaded DOMContentLoaded error abort stop]],
    #log => [qw[debug]],
)};

if (! $mech) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
    exit
} else {
    plan tests => 16;
};

isa_ok $mech, 'WWW::Mechanize::Firefox';
$mech->autodie(1);

$mech->get_local('50-click.html');
$mech->allow('javascript' => 1);

my ($clicked,$type,$ok);

eval {
    ($clicked, $type) = $mech->eval_in_page('clicked');
    $ok = 1;
};

if (! $clicked) {
    SKIP: { skip "Couldn't get at 'clicked'. Do you have a Javascript blocker?", 15; };
    exit;
};

ok $clicked, "We found 'clicked'";

# Xpath
$mech->get_local('50-click.html');
$mech->allow('javascript' => 1);
$mech->click({ xpath => '//*[@id="a_link"]', synchronize=>0, });
($clicked,$type) = $mech->eval_in_page('clicked');
is $clicked, 'a_link', "->click() with an xpath selector works";

# Xpath
$mech->get_local('50-click.html');
$mech->allow('javascript' => 1);
$mech->click({ xpath => '//div[@id="a_div"]', synchronize=>0, });
($clicked,$type) = $mech->eval_in_page('clicked');
is $clicked, 'a_div', "->click() with an xpath selector works";

# CSS
$mech->get_local('50-click.html');
$mech->allow('javascript' => 1);
$mech->click({ selector => '#a_link', synchronize=>0, });
($clicked,$type) = $mech->eval_in_page('clicked');
is $clicked, 'a_link', "->click() with a CSS selector works";

# CSS
$mech->get_local('50-click.html');
$mech->allow('javascript' => 1);
$mech->click({ selector => '#a_div', synchronize=>0, });
($clicked,$type) = $mech->eval_in_page('clicked');
is $clicked, 'a_div', "->click() with a CSS selector works";

# Name via options
$mech->get_local('50-click.html');
$mech->click({ name => 'Go' }); # click the "Go" button
like $mech->uri, qr/\bGo=/, "->click() the 'Go' button works via options";

# Name
$mech->get_local('50-click.html');
$mech->click('Go'); # click the "Go" button
like $mech->uri, qr/\bGo=/, "->click() the 'Go' button works";

# Name via options
$mech->get_local('50-click.html');
$mech->click({ name => '' }); # click the unnamed button
like $mech->uri, qr/\b51-mech-submit.html$/i, "->click() the unnamed button works";

# Name
$mech->get_local('50-click.html');
$mech->click(''); # click the empty button
# this weirdly raises no events in FF if it points to the same page
like $mech->uri, qr/\b51-mech-submit.html$/i, "->click() the unnamed button works";

# Non-existing link
$mech->get_local('50-click.html');
my $lives = eval { $mech->click('foobar'); 1 };
my $msg = $@;
ok !$lives, "->click() on non-existing parameter fails correctly";
like $msg, qr/No elements found for Button with name 'foobar'/,
    "... with the right error message";

# Non-existing link via CSS selector
$mech->get_local('50-click.html');
$lives = eval { $mech->click({ selector => 'foobar' }); 1 };
$msg = $@;
ok !$lives, "->click() on non-existing parameter fails correctly";
like $msg, qr/No elements found for CSS selector 'foobar'/,
    "... with the right error message";
    
# Click with undef
$mech->get_local('50-click.html');
$lives = eval { $mech->click(undef); 1 };
$msg = $@;
ok !$lives, "->click(undef) fails correctly";
like $msg, qr/->click called with undef link/,
    "... with the right error message";


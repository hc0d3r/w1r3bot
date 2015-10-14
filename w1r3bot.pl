#!/usr/bin/env perl
# @hc0d3r
# ~ ~ ~ ~ w1r3bot ~ ~ ~ ~
# you can do anything with this code, except sale it,
# is very recommend print this and use as toilet paper

BEGIN { push @INC, './lib/' }

use strict;
use warnings;
use w1r3bot;

use w1r3::utils;
use w1r3::net;

sub help_banner {
    print <<HELP;

 [+] w1rebot v@{[ &w1r3bot::VERSION ]}

  -c > irc host to connect
  -p > irc port to connect
  -t > timeout to connect
  -n > set your nickname
  -u > set username
  -r > set real username
  -p > set your password
  -j > chans to join
  -a > set admins
  -h > display this help menu

  [*] Examples:

    w1r3bot -c irc.matrix -p 6667 -n neo -p 2674rul3z -j '#morpheus,#trynity,#smith' -a master_of_puppets -4

HELP
    exit;
};

sub parser_opts {
    my $output = shift;

    for(my $i=0; $i<=$#ARGV; $i++){
        if("-c" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'host'} = $ARGV[$i];
            }
        }

        elsif("-p" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'port'} = $ARGV[$i];
            }
        }

        elsif("-n" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'nick'} = $ARGV[$i];
            }
        }

        elsif("-u" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'user'} = $ARGV[$i];
            }
        }

        elsif("-r" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'realname'} = $ARGV[$i];
            }
        }

        elsif("-p" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'password'} = $ARGV[$i];
            }
        }

        elsif("-j" eq $ARGV[$i]){
            if($ARGV[++$i]){
                @{ $$output{'chans'} } = split /,/, $ARGV[$i];
            }
        }

        elsif("-a" eq $ARGV[$i]){
            if($ARGV[++$i]){
                @{ $$output{'admins'} } = split /,/, $ARGV[$i];
            }
        }

        elsif("-t" eq $ARGV[$i]){
            if($ARGV[++$i]){
                $$output{'timeout'} = $ARGV[$i];
            }
        }

        elsif("-h" eq $ARGV[$i]){
            &help_banner;
        }

        elsif("-4" eq $ARGV[$i]){
            $$output{'ipv4'} = 1;
        }

        elsif("-6" eq $ARGV[$i]){
            $$output{'ipv6'} = 1;
        }

        else {
            warn $ARGV[$i]." Not is a valid paramter\n";
            exit;
        }

    }

}

my(%opts);
parser_opts \%opts;

if(!$opts{'host'} || !$opts{'port'}){
    warn "\nYou must set a host and port to connect\n";
    warn "Use -h to get help\n\n";
    exit;
}

print "\n\n";
print "[+] irc host: ".$opts{'host'}."\n";
print "[+] irc port: ".$opts{'port'}."\n";

if(!$opts{'nick'}){
    warn "[-] Nickname not set, using default: ".&w1r3bot::DEFAULT_NICK."\n";
}

if(!$opts{'admins'}){
    warn "[-] You not set admins, many functions needs admin priv !\n";
} else {
    print "[+] Admin list: ".(join ",",@{ $opts{'admins'} })."\n";
}

print "[+] Chan list: ".(join ",",@{ $opts{'chans'} })."\n" if($opts{'chans'});
print "[+] Connecting ...\n";
print "\n\n";


my $bot = new w1r3bot(
    nick =>  $opts{'nick'},
    realname => $opts{'realname'},
    password => $opts{'password'},
    username => $opts{'user'}
);

$bot->set_admins(@{ $opts{'admins'} });
$bot->join_chans(@{ $opts{'chans'} });

$bot->add_function(
    cmd => "!exit",
    description => "exit bot",
    admin => 1,
    function => \&exit_cmd,
    background => 0
);

$bot->add_function(
    cmd => "!join",
    description => "join chan(s) -> !join #chan1 ...",
    admin => 1,
    function => \&join_chan,
    background => 0
);

$bot->add_function(
    cmd => "!leave",
    description => "leave chan(s), -> !leave, !leave #chan1 ...",
    admin => 1,
    function => \&leave_chan,
    background => 0
);

$bot->add_function(
    cmd => "!show_adms",
    description => "return list of current admins",
    admin => 1,
    function => \&list_adms,
    background => 0
);

$bot->add_function(
    cmd => "!give_adm",
    description => "give adm privilege to users, !give_adm user1 ...",
    admin => 1,
    function => \&give_adm,
    background => 0
);

$bot->add_function(
    cmd => "!jobs",
    description => "display works in background",
    admin => 1,
    function => \&jobs_list,
    background => 0
);

$bot->add_function(
    cmd => "!kill",
    description => "kill process by id, !kill 12345",
    admin => 1,
    function => \&kill_by_id,
    background => 0
);

$bot->add_function(
    cmd => "!system",
    description => "execute commands in the local machine, !system id;pwd;ls",
    admin => 1,
    function => \&exec_cmd,
    background => 1
);

$bot->add_function(
    cmd => "!port",
    description => "check if port is open, !port 127.0.0.1 12345 ...",
    admin => 0,
    function => \&check_port,
    background => 1
);


$bot->add_function(
    cmd => "!help",
    description => "display functions help",
    admin => 0,
    function => \&bot_help,
    background => 1
);


if( $bot->xconnect(
        host => $opts{'host'},
        port => $opts{'port'},
        verbose => 1,
        timeout => $opts{'timeout'},
)){
    print "[+] Connected waiting for commands ...\n\n";
    $bot->main_loop;
} else {
    warn "[-] Failed to connect on ".$opts{'host'}.":".$opts{'port'}." (".$bot->{'w1r3socket'}->get_err.")\n\n";
}

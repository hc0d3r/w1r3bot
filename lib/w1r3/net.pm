package w1r3::net;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(check_port);

use strict;
use warnings;
use Fcntl;
use Socket qw(SOCK_STREAM AF_INET unpack_sockaddr_in unpack_sockaddr_in6 pack_sockaddr_in pack_sockaddr_in6 getaddrinfo inet_ntop SOL_SOCKET SO_ERROR);
#use w1r3socket; ::-> usar o w1r3socket dps

use constant CHECK_PORT_TIMEOUT => 4;

sub check_port {
    my($bot_class,$user,$host,$chan,$parameters ) = @_;

    my @xattr = split / /,$parameters;
    my $xhost = shift @xattr;

    if(!$xhost || !@xattr){
        return;
    }

    my %hints = (socktype => SOCK_STREAM);
    my ($err, @res) = getaddrinfo($xhost, undef, \%hints);

    if($err){
        $bot_class->xsend("PRIVMSG $chan :[ port ] $xhost error: $err\r\n");
    }

    foreach my $port(@xattr){
        $bot_class->xsend("PRIVMSG $chan :[ port ] Checking => $xhost:$port\r\n");

        foreach my $ai(@res){
            my($addr,$str_addr,$pack_con,$rin,$sock);

            if($ai->{family} == AF_INET){
                $addr = (unpack_sockaddr_in($ai->{addr}))[1];
                $pack_con = pack_sockaddr_in($port, $addr);
            } else {
                $addr = (unpack_sockaddr_in6($ai->{addr}))[1];
                $pack_con = pack_sockaddr_in6($port, $addr);
            }

            $str_addr = inet_ntop $ai->{family}, $addr;

            if( !socket( $sock, $ai->{family}, $ai->{socktype}, $ai->{protocol}) ){
                $bot_class->xsend("PRIVMSG $chan :[ $xhost ] ($str_addr:$port) > cannot create socket $!\r\n");
                next;
            }

            my $flags = fcntl($sock, F_GETFL, 0);
            $flags |= O_NONBLOCK;
            fcntl($sock, F_SETFL, $flags);
            vec($rin,fileno($sock),1) = 1;

            connect($sock, $pack_con);

            if( $! ){
               if( select($rin, $rin, $rin, CHECK_PORT_TIMEOUT) > 0){
                    my $sock_err = getsockopt($sock, SOL_SOCKET, SO_ERROR);
                    $sock_err = unpack("I", $sock_err);

                   	if( $sock_err != 0 ){
                        $bot_class->xsend("PRIVMSG $chan :[ $xhost ] ($str_addr:$port) => connection failed\r\n");
                        #print "timeout 1 \n";
                    }

                    else {
                        $bot_class->xsend("PRIVMSG $chan :[ $xhost ] ($str_addr:$port) => connection success\r\n");
                    }
                }

                else {
                     $bot_class->xsend("PRIVMSG $chan :[ $xhost ] ($str_addr:$port) => connection failed\r\n");
                }
           	}

            else {
                $bot_class->xsend("PRIVMSG $chan :[ $xhost ] ($str_addr:$port) => connection success\r\n");
            }

            close $sock;

        }
    }

    exit;


}

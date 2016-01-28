package w1r3socket;

use strict;
use warnings;

use Socket qw(SOCK_STREAM AF_INET unpack_sockaddr_in unpack_sockaddr_in6 pack_sockaddr_in pack_sockaddr_in6 getaddrinfo inet_ntop SOL_SOCKET SO_ERROR);
use Fcntl;
use IO::Select;
use Errno;

sub new {
    my $class = shift;
    my $attr = {
        err => undef,
        sockfd => undef,
    };

    bless $attr, $class;
}

sub xconnect {
    my($self,%attr) = @_;

    my %hints = (socktype => SOCK_STREAM);
    my ($err, @res) = getaddrinfo($attr{host}, undef, \%hints);

    if($err){
        $self->{'err'} = $err;
        return 0;
    }

    foreach my $ai(@res){
        my($addr,$str_addr, $pack_con);

        if($ai->{family} == AF_INET){
            $addr = (unpack_sockaddr_in($ai->{addr}))[1];
            $pack_con = pack_sockaddr_in($attr{port}, $addr);
        } else {
            $addr = (unpack_sockaddr_in6($ai->{addr}))[1];
            $pack_con = pack_sockaddr_in6($attr{port}, $addr);
        }

        $str_addr = inet_ntop $ai->{family}, $addr;
        print "[w1r3socket::xconnect] - Trying connect to $str_addr on port ".$attr{port}."\n"  if($attr{verbose});

        my $sock;
        if( ! socket( $sock, $ai->{family}, $ai->{socktype}, $ai->{protocol}) ){
            $self->{'err'} = $!;
            warn "[w1r3socket::xconnect] - socket() failed -> $!\n" if($attr{verbose});
            next;
        }

        my $flags = '';
        my $rin = '';

        $self->{'sockfd'} = $sock;

        # NON_BLOCK
        $flags = fcntl($sock, F_GETFL, 0);
        fcntl($sock, F_SETFL, $flags | O_NONBLOCK);
        vec($rin,fileno($sock),1) = 1;

        connect($sock, $pack_con);

        if( $!{EINPROGRESS} ){
           if( select($rin, $rin, $rin, $self->{'timeout'} || $attr{timeout}) > 0){
                my $sock_err = getsockopt($sock, SOL_SOCKET, SO_ERROR);
                $sock_err = unpack("I", $sock_err);

                if( $sock_err != 0 ){
                    warn "[w1r3socket::xconnect] - Timeout rechead || connection failed\n" if($attr{verbose});
                    $self->{'err'} = "Timeout rechead || connection failed";
                }

                else {
                    print "[w1r3socket::xconnect] - Connection established\n" if($attr{verbose});
                    undef $self->{'err'};
                    fcntl($sock, F_SETFL, $flags);
                    return 1;
                   }
            }

            else {
                warn "[w1r3socket::xconnect] - Timeout rechead || connection failed\n" if($attr{verbose});
                $self->{'err'} = "Timeout rechead || connection failed";
            }
        }

        else {
            warn "[w1r3socket::xconnect] - Connection failed" if($attr{verbose});
            $self->{'err'} = $!;
        }

=head
        else {
            print "[w1r3socket::xconnect] - Connection established\n" if($attr{verbose});
            undef $self->{'err'};
            fcntl($sock, F_SETFL, $flags);
            return 1;
        }
=cut

        close $sock;
        undef $self->{'sockfd'};

    }

    return 0;
}

sub get_err {
    my $self = shift;
    return $self->{'err'};
}

1;

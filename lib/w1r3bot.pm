package w1r3bot;

use strict;
use warnings;

use forkontrol;
use w1r3socket;

use constant {
    VERSION => "0.1",
    DEFAULT_NICK => "w1r3bot",
    DEFAULT_USER => "w1r3bot",
    DEFAULT_NAME => "w1r3bot"
};

sub new {
    my($self,%attr) = @_;

    my $elements = {
        functions => [],
        admins => [],
        core_modules => [],
        forkontrol => new forkontrol,
        nick => $attr{nick} || DEFAULT_NICK,
        w1r3socket => new w1r3socket,
        username => $attr{username} || DEFAULT_USER,
        realname => $attr{realname} || DEFAULT_NAME,
        password => $attr{password} || undef,
        join_chans => [],
    };

    bless $elements, $self;
}

sub set_admins {
    my $self = shift;
    my @args = @_;

    @{ $self->{'admins'} } = @args;
}

sub add_function {
    my $self = shift;
    my $args = {@_};

    push(@{ $self->{'functions'} }, $args);
}

sub check_admin {
    my $self = shift;
    my $user = shift;

    foreach(@{ $self->{'admins'} }){
      if($_ eq $user){
        return 1;
      }
    }

    return 0;
}

sub add_core_function {
    my $self = shift;
    my $function = shift;

    push(@{ $self->{'core_modules'} }, $function);
}

sub join_chans {

    my $self = shift;
    @{ $self->{'join_chans'}} = @_;

}

sub xconnect {
    my($self,%attr) = @_;

    if($self->{'w1r3socket'}->xconnect(%attr)){
      return 1;
    }

    return 0;
}

sub xsend {

    my($class, $content) = @_;

    if($class->{'w1r3socket'}->{'sockfd'}){
        return send $class->{'w1r3socket'}->{'sockfd'}, $content, 0;
    }

    return 0;

}


sub main_loop {
    my $self = shift;
    my $sock = $self->{'w1r3socket'}->{'sockfd'};

    my $forkontrol = $self->{'forkontrol'};

    $self->xsend ("NICK ".$self->{'nick'}."\r\n");
    $self->xsend ("USER ".$self->{'username'}." 8 x : ".$self->{'realname'}."\r\n");

    $| = 1;

    while(<$sock>){
        print $_;

        if($_ =~ /^PING (.+)$/){
          $self->xsend("PONG $1\r\n");
        }

        elsif($_ =~ /^.+ 443 .+/){
          $self->{'nick'} =  $self->{'nick'}."|".int rand(time);
          $self->xsend("NICK ".$self->{'nick'}."\r\n");
        }

        elsif($_ =~ /^:.+\s+001\s+.*/){
          if($self->{'password'}){
            $self->xsend("IDENTIFY ".$self->{'password'}."\r\n");
          }

          foreach(@{ $self->{'join_chans'}}){
            $self->xsend("JOIN $_\r\n");
          }

        }

        elsif($_ =~ /^:([^\!]+)\!(.+) PRIVMSG (.+) :(.+)$/){
          my $user = $1;
          my $host = $2;
          my $chan = $3;
          my $mess = $4;

          if($chan eq $self->{'nick'}){
            $chan = $user;
          }

          foreach my $functions(@{ $self->{'functions'} }){
            if($mess =~ /^$functions->{'cmd'}\s*([^\n|\r]*)/){
              if($functions->{'admin'}){
                if(!$self->check_admin($user)){
                  $self->xsend("PRIVMSG $chan :$user you dont have admin priv\r\n");
                  next;
                }
              }
              my @sad = ($user, $host, $chan, $1);

              if($functions->{'background'}){
                  $forkontrol->new_proc(
                      function => $functions->{'function'},
                      parameters => [$self, @sad],
                      user => $user,
                      description => "$mess"
                  );
              } else {
                  $functions->{'function'}([$self, @sad]);
              }
            }
          }
        }

    }


}

1;

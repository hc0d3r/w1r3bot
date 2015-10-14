package forkontrol;

use strict;
use warnings;
use POSIX ":sys_wait_h";

sub new {
    my $self = shift;
    bless {pids => []}, $self;
}


sub get_procs {

    my $self = shift;
    my @arr = @{ $self->{'pids'} };

    my @new_array;

    for(my $i=0; $i<=$#arr; $i++){
        next if(!$arr[$i]->{'pid'});
        my $check = waitpid($arr[$i]->{'pid'}, WNOHANG);

        if($check == -1){
            delete $arr[$i];
        } else {
            push(@new_array, $arr[$i]);
        }
    }

    @{ $self->{'pids'} } = @new_array;

    return \@new_array;

}

sub new_proc {
    my($self,%call) = @_;

    my $pid = fork();

    if($pid){
        push(@{ $self->{'pids'} }, {
            description => $call{'description'},
            pid => $pid,
            user => $call{'user'}
        });

        waitpid($pid, WNOHANG);

        return $pid;
    }

    elsif($pid == 0){
        $call{'function'}(@{ $call{'parameters'} });
        exit 0;
    }

    elsif ($pid == -1){
        return -1;
    }

}


sub kill_proc {
    my $self = shift;
    my $pid = shift;

    kill 'TERM', $pid;

}

sub killenall {
    my $self = shift;

    for(@{ $self->get_procs }){
        next if(!$_->{pid});
        $self->kill_proc($_->{pid});
    }

}

1;

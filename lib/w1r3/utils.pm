package w1r3::utils;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bot_help exit_cmd join_chan leave_chan give_adm list_adms jobs_list kill_by_id exec_cmd);

sub bot_help {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  $bot_class->xsend("PRIVMSG $chan :- w1r3b0t v".&w1r3bot::VERSION."\r\n");
  $bot_class->xsend("PRIVMSG $chan :- coded by \@hc0d3r\r\n");
  $bot_class->xsend("PRIVMSG $chan :- legend: x ~> admin functions  0 ~> normal user functions\r\n");
  $bot_class->xsend("PRIVMSG $chan :- function list:\r\n");

  foreach my $functions(@{ $bot_class->{'functions'} }){
    my $help_menu;

    if($functions->{admin}){
      $help_menu .= "x";
    }

    else {
      $help_menu .= "0";
    }

    $help_menu .= " ".$functions->{cmd};

    if($functions->{description}){
      $help_menu .= " --- ". $functions->{description};
    }

    $bot_class->xsend("PRIVMSG $chan :- $help_menu\r\n");

  }

  exit 0;

}

sub exit_cmd {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  $bot_class->{'forkontrol'}->killenall;

  $bot_class->xsend("QUIT\r\n");
  close $bot_class->{'w1r3socket'}->{'sockfd'};

  exit;
}

sub join_chan {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  for(split / /, $parameters){
    $bot_class->xsend("JOIN $_\r\n");
  }
}

sub leave_chan {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  if(!$parameters && $chan =~ /^#/){
    $bot_class->xsend("PART $chan\r\n");
  }

  else {
    for(split / /, $parameters){
      $bot_class->xsend("PART $_\r\n") if($_ =~ /^#/);
    }
  }
}

sub give_adm {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  chomp $parameters;

  for my $nick(split / /, $parameters){
    $nick =~ s/\n//g;
    push(@{ $bot_class->{'admins'} }, $nick);
  }
}

sub list_adms {
  my($bot_class,$user,$host,$chan,$parameters ) = @_;

  my $adm = join ",", @{ $bot_class->{'admins'} };
  $bot_class->xsend("PRIVMSG $chan :[ adms ] - $adm\r\n");

}

sub jobs_list {
    my($bot_class,$user,$host,$chan,$parameters ) = @_;
    my @proc_list = @{ $bot_class->{'forkontrol'}->get_procs };

    $bot_class->xsend("PRIVMSG $chan : [ listing process ] start !@#%\r\n");

    foreach(@proc_list){
        next if(!$_->{'pid'} || !$_->{'user'} || !$_->{'description'});
        $bot_class->xsend("PRIVMSG $chan : PID: ".$_->{'pid'}." | USER: ".$_->{'user'}." | CMD: ".$_->{'description'}."\r\n");
    }

    $bot_class->xsend("PRIVMSG $chan : [ listing process ] end\r\n");
    return;
}

sub kill_by_id {
    my($bot_class,$user,$host,$chan,$parameters ) = @_;
    my @proc_list = @{ $bot_class->{'forkontrol'}->get_procs };

    foreach(@proc_list){
        if($_->{'pid'} eq $parameters){
            $bot_class->{'forkontrol'}->kill_proc("$parameters");
            $bot_class->xsend("PRIVMSG $chan : Process $parameters Killed !\r\n");
            return;
        }
    }

    $bot_class->xsend("PRIVMSG $chan : Process $parameters not exist\r\n");
}

sub exec_cmd {
    my($bot_class,$user,$host,$chan,$parameters ) = @_;

    my $hand;

    if( !open($hand, "$parameters|") ){
        $bot_class->xsend("PRIVMSG $chan : cannot execute command $parameters\r\n");
        return;
    }

    while(<$hand>){
        $bot_class->xsend("PRIVMSG $chan :[ $parameters ] $_\r\n");
    }

    close $hand;
    exit;
}

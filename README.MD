w1rebot
===
Just another irc bot  
Current version: v0.1.3

## Help menu

```
- w1r3b0t v0.1
- coded by @hc0d3r
- legend: x ~> admin functions  0 ~> normal user functions
- function list:
- x !exit --- exit bot
- x !join --- join chan(s) -> !join #chan1 ...
- x !leave --- leave chan(s), -> !leave, !leave #chan1 ...
- x !show_adms --- return list of current admins
- x !give_adm --- give adm privilege to users, !give_adm user1 ...
- x !jobs --- display works in background
- x !kill --- kill process by id, !kill 12345
- x !system --- execute commands in the local machine, !system id;pwd;ls
- 0 !port --- check if port is open, !port 127.0.0.1 12345 ...
- 0 !help --- display functions help
```

## Add more functions

***Add functions in w1r3bot is very simple***

You can add your own functions editing the file w1r3bot.pl and
including line of codes in the following way:

```perl
$bot->add_function(
    cmd => "!COMAND",
    description => "A description for help menu",
    admin => 0, # if admin access is required or not (boolean)
    function => \&function_name,
    background => 1 # set if function will work in another process or not (boolean)
);
```
When the function as called the follow parameters are passed:

```perl
my($bot_class,$user,$host,$chan,$parameters) = @_;

# $bot_class is w1r3bot class
# $user is the name of user that send the command
# $host is the hostname info of user
# $chan is the channel to response
# $parameters is the parameters after the command
```
Example:
```perl
$bot->add_function(
    cmd => "!test",
    description => "test command",
    admin => 0,
    function => \&test_function,
    background => 1
);

sub test {
    my($bot_class,$user,$host,$chan,$parameters ) = @_;
    $bot_class->xsend("PRIVMSG $chan :user-> $user | host-> $host | chan-> $chan | parameters-> $parameters\r\n");
    sleep 50;
}


```

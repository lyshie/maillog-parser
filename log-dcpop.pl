#!/usr/local/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use LoggerConfig qw(:all);

# main message loop conditional varibale
my $LOOP         = 1;
my $HOST         = "";
my $CURRENT_HOST = "";
my $CURRENT_POS  = "";
my $CURRENT_DATE = "";
my $POS          = 0;
my $DATE         = "";

sub initialize;
sub finalize;
sub main_loop;
sub setSignal;
sub setDirectory;
sub getConfig; 
sub getLog;
sub sigHandler;
sub getDate;
sub setDateChanged;
sub cleanCache;
sub setLog;

sub cleanCache
{
}

sub getDate
{
    my $epoch = shift();
    my ($sec, $min, $hour, $day, $month, $year) = localtime($epoch);
    return sprintf("%04d/%02d/%02d", $year + 1900, $month + 1, $day);
}

sub sigHandler
{
    $LOOP = 0;
}
 
sub initialize
{
    setSignal();
    getConfig();
    setDirectory();
}

sub finalize
{
    open(FH, ">", $CURRENT_POS);
    print FH $POS;
    close(FH);
    open(FH, ">", $CURRENT_DATE);
    print FH getDate(time());
    close(FH);
    printf("%s\n", "finalize(): safely terminated.");
    $LOOP = 0;
}

sub setDateChanged
{
    my $date = getDate(time());
    if ($date ne $DATE) {
        open(LOG, "$LOG_PATH/$HOST/$DATE/$LOG_POP3D");
        seek(LOG, $POS, 0);
        my $line = "";
        while (<LOG>) {
            $line = $_;
            chomp($line);
            getLog($line);
        }
        close(LOG);

        # rename current to date
        my $dir = $DATE;
        $dir =~ s/\//\-/g; 
        if (!rename("$LOG_CACHE/$HOST/current", "$LOG_CACHE/$HOST/$dir")) {
            die("Error: Can't rename current to $dir\n"); 
        }
        else {
            if (!mkdir("$LOG_CACHE/$HOST/current")) {
                die("Error: After rename, can't create current.\n"); 
            } 
        }

        $DATE = $date;
        $POS = 0;
    }
}

sub main_loop
{
    while ($LOOP) {
        printf("%s %s\n", getDate(time()), $POS);
        setDateChanged();
        open(LOG, "$LOG_PATH/$HOST/$DATE/$LOG_POP3D");
        seek(LOG, $POS, 0);
        my $line = "";
        while (<LOG>) {
            $line = $_;
            chomp($line);
            getLog($line);
        }
        $POS = tell(LOG);
        close(LOG);
        sleep($DURATION);
    }
}

sub setSignal
{
    # don't kill me at signal -9
    $SIG{HUP}  = \&sigHandler;
    $SIG{INT}  = \&sigHandler;
    $SIG{TERM} = \&sigHandler;
}

sub setDirectory
{
    # check log cache directory
    if (!-d $LOG_CACHE) {
        die("Error: The cache dir you specified is not exist.\n");
    }
    # check logpool exist
    if (!-d $LOG_PATH) {
       die("Error: The logpool you specified is not exist.\n"); 
    }

    $CURRENT_HOST = "$LOG_CACHE/$HOST";

    if (!-d $CURRENT_HOST) {
       if (!mkdir($CURRENT_HOST)) {
           die("Error: Can't create log dir.\n");
       } 
       else {
           if (!mkdir("$CURRENT_HOST/current")) {
               die("Error: Can't create log dir (current).\n");
           }
       } 
    }
}

sub getConfig
{
    if (defined $ARGV[0]) {
        $HOST = $ARGV[0];
    } else {
         die("Error: You didn't specify a host name.\n");
    }
    $CURRENT_POS = "$LOG_CACHE/$LOG_POS-$HOST";
    $CURRENT_DATE = "$LOG_CACHE/$LOG_DATE-$HOST";

    if (!-e $CURRENT_POS) {
       open(FH, ">", $CURRENT_POS);
       print FH "0";
       close(FH);
    }
    if (!-e $CURRENT_DATE) {
       open(FH, ">", $CURRENT_DATE);
       print FH getDate(time());
       close(FH);
    }

    open(FH, $CURRENT_POS);
    $POS = <FH>;
    if (!defined($POS)) { $POS = 0; }
    chomp($POS);
    close(FH);
    open(FH, $CURRENT_DATE);
    if (!defined($DATE)) { $DATE = getDate(time()); }
    $DATE = <FH>;
    chomp($DATE); 
    close(FH);
}

sub getLog
{
    my $log = shift();
    if ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? pop3-login: Disconnected:.*? user=<(.*?)>, method=PLAIN, rip=(.*?), lip=.*?$/) {
        my ($time, $account, $source);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        setLog(("-pop-login", $account, $time, $source));
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? pop3-login: Login: user=<(.*?)>, method=PLAIN, rip=(.*?), lip=.*?$/ ) {
        my ($time, $account, $source);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        setLog(("+pop-login", $account, $time, $source));
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? pam\((.*?),(.*?)\): pam_authenticate\(\) failed: (.*?)$/ ) {
        my ($time, $account, $source, $msg);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        $msg     = (defined $4) ? $4 : "";
        if ($account ne '') {
            setLog(("-pop-auth", $account, $time, $source, $msg)); 
        }
    } 
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .* POP3\((.*?)\): (.*)$/ ) {
        my ($time, $account);
        my ($retr, $retr_size);
        my ($deleted, $original);
        my ($mailbox_size);
        if (defined $1) { $time = $1; }
        if (defined $2) {
            $account = $2; 
            if (defined $3) {
                if ($3 =~
  /^Disconnected: Logged out .* retr=(\d+)\/(\d+), del=(\d+)\/(\d+), size=(\d+)$/) {
                $retr         = (defined $1) ? $1 : 0;
                $retr_size    = (defined $2) ? $2 : 0; 
                $deleted      = (defined $3) ? $3 : 0;
                $original     = (defined $4) ? $4 : 0;
                $mailbox_size = (defined $5) ? $5 : 0;
                setLog(("+pop-logout", $account,
                        $time,
                        $retr, $retr_size, $deleted, $original, $mailbox_size
                      ));
                }
            }
        }
    }
}

sub setLog
{
    my ($type, $account, @data) = @_; 
    my $line = "$type#"; 
    foreach (@data) {
        $line .= "$_\t";
    }
    $line .= "$account\n"; 
    print $line;
    open(ACCT, ">>", "$LOG_CACHE/$HOST/current/$account");
    print ACCT $line;
    close(ACCT);
}

sub main
{
    initialize();
    main_loop();
    finalize();
}

main();

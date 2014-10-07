#!/usr/local/bin/perl -w
#
# Author       : Shie, Li-Yi
# Organization : National Tsing Hua Uiversity
# Email        : lyshie@mx.nthu.edu.tw
# License      : GPL
#
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use LoggerConfig qw(:all);

# lyshie_20071023: main message loop, global conditional varibales
my $LOOP         = 1;  # default is looping forever
my $HOST         = ""; # get the hostname from parameter
my $CURRENT_HOST = ""; # store full pathname for the host
my $CURRENT_POS  = ""; # store full filename for the file position
my $CURRENT_DATE = ""; # store full filename for the latest date
my $POS          = 0;  # store the file position
my $DATE         = ""; # store the latest date

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

# lyshie_20071023: convert unix time to YYYY/MM/DD
sub getDate
{
    my $epoch = shift();
    my ($sec, $min, $hour, $day, $month, $year) = localtime($epoch);
    return sprintf("%04d/%02d/%02d", $year + 1900, $month + 1, $day);
}

# lyshie_20071023: end the main loop
sub sigHandler
{
    $LOOP = 0;
}

# lyshie_20071023: initialize
sub initialize
{
    setSignal();    # avoid unexpected termination
    getConfig();    # load config file
    setDirectory(); # check directories and create
}

# lyshie_20071023: safely terminated and write back all information
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

# lyshie_20071023: if date changed, process the directory and other information
sub setDateChanged
{
    my $date = getDate(time());
    if ($date ne $DATE) {
        # dump out the remains
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
        # reset to default value
        $DATE = $date;
        $POS = 0;

        open(FH, ">", $CURRENT_POS);
        print FH $POS;
        close(FH);
        open(FH, ">", $CURRENT_DATE);
        print FH $DATE;
        close(FH);
    }
}

# lyshie_20071023: main loop
sub main_loop
{
    while ($LOOP) {
        printf("%s %s\n", getDate(time()), $POS);
        setDateChanged();
        open(LOG, "$LOG_PATH/$HOST/$DATE/$LOG_POP3D");
        seek(LOG, $POS, 0); # set to current position
        my $line = "";
        while (<LOG>) {
            $line = $_;
            chomp($line);
            getLog($line);
        }
        $POS = tell(LOG); # get current
        close(LOG);
        sleep($DURATION); # every $ seconds to read the log file
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
     }
     if (!-e "$CURRENT_HOST/current" && !mkdir("$CURRENT_HOST/current")) {
         die("Error: Can't create log dir (current).\n");
     }
}

# lyshie_20071023: get dynamic variables
sub getConfig
{
    # check if hostname specified
    if (defined $ARGV[0]) {
        $HOST = $ARGV[0];
    } else {
         die("Error: You didn't specify a host name.\n");
    }
    $CURRENT_POS = "$LOG_CACHE/$LOG_POS-$HOST";
    $CURRENT_DATE = "$LOG_CACHE/$LOG_DATE-$HOST";

    # if not exist, create it
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

    # load file position, latest date
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
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? cache\((.*?),(.*?)\): (Password mismatch)$/ ) {
        my ($time, $account, $source, $msg);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        $msg     = (defined $4) ? $4 : "";
        if ($account ne '') {
            setLog(("-auth", $account, $time, $source, $msg));
        }
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? passwd-file\((.*?),(.*?)\): (Password mismatch)$/ ) {
        my ($time, $account, $source, $msg);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        $msg     = (defined $4) ? $4 : "";
        if ($account ne '') {
            setLog(("-auth", $account, $time, $source, $msg));
        }
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? pam\((.*?),(.*?)\): pam_authenticate\(\) failed: (.*?)$/ ) {
        my ($time, $account, $source, $msg);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        $msg     = (defined $4) ? $4 : "";
        if ($account ne '') {
            setLog(("-auth", $account, $time, $source, $msg)); 
        }
    } 
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? POP3\((.*?)\): (.*)$/i ) {
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
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? imap-login: Login: user=<(.*?)>, method=PLAIN, rip=(.*?), lip=.*?$/ ) {
        my ($time, $account, $source);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $source  = (defined $3) ? $3 : "";
        setLog(("+imap-login", $account, $time, $source));
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? IMAP\((.*?)\): Disconnected: Logged out$/i ) {
        my ($time, $account);
        $time    = (defined $1) ? $1 : ""; 
        $account = (defined $2) ? $2 : "";
        setLog(("+imap-logout", $account, $time));
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? IMAP\((.*?)\): Connection closed$/i ) {
        my ($time, $account);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        setLog(("+imap-logout", $account, $time));
    }
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? IMAP\((.*?)\): Mailbox deleted: (.*?)$/ ) {
        my ($time, $account, $mailbox);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
        $mailbox = (defined $3) ? $3 : ""; 
        setLog(("+imap-delete-mailbox", $account, $time, $mailbox));
    } 
    elsif ( $log =~ m/^(.*?) [\w\d\-]+ dovecot: .*? IMAP\((.*?)\): expunged: .*? msgid=<(.*?)>(.*)$/ ) {
        my ($time, $account, $mailbox, $msgid);
        $time    = (defined $1) ? $1 : "";
        $account = (defined $2) ? $2 : "";
	$msgid   = (defined $3) ? $3 : "";
        if ((defined $4) && ($4 ne '')) {
            $4 =~ m/^, box=(.*?)$/;
            $mailbox = (defined $1) ? $1 : "*";
        }
        else {
            $mailbox = 'INBOX';
        } 
        setLog(("+imap-expunge", $account, $time, $mailbox, $msgid));
    }
}

# lyshie_20071023: write one line from log to user-oriented file
sub setLog
{
    my ($type, $account, @data) = @_; 
    my $line = "$type\t"; 
    foreach (@data) {
        $line .= "$_\t";
    }
    $line .= "$account\n"; 
    print $line;
    open(ACCT, ">>", "$LOG_CACHE/$HOST/current/$account");
    print ACCT $line;
    close(ACCT);
}

# lyshie_20071023: main function
sub main
{
    initialize();
    main_loop();
    finalize();
}

main();

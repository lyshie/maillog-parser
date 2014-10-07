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
use CGI qw(:standard);
use Net::POP3;
use lib "$Bin";
use CGIConfig qw(:all);
use Unicode::IMAPUtf7;

# lyshie_20071021: http parameters
my ($HOST, $ACCOUNT, $PASSWORD, $DATE, $TYPE, $LANG);
my %DIRTY_DATE;

sub getSize;
sub setError;
sub getParam;
sub getAuth;
sub getPOPCheck;
sub getHostCheck;
sub getLog;
sub setUsage;
sub getQueryInfo;
sub main;

sub getSize
{
    my $size = shift();
    if ($size < 1024) {
        return sprintf("%d Bytes", $size); 
    }
    elsif ($size < 1024 * 1024) {
        return sprintf("%.1f KB\n", $size / 1024);
    } 
    else {
        return sprintf("%.1f MB\n", $size / 1024 / 1024);
    }
}

sub getQueryInfo
{
    print <<EOF;
    <div align="center">
    <table width="0%">
    <tr>
        <td>
        $LANG{$LOCALE}{'INFO_LANG'}$LANG{$LOCALE}{'LANG'}<br />
        </td>
        <td>
        $LANG{$LOCALE}{'INFO_ACCT'}$ACCOUNT\@$HOST<br />
        </td>
        <td>
        $LANG{$LOCALE}{'INFO_DATE'}$DIRTY_DATE{$DATE}
        </td>
    </tr>
    </table>
    </div>
    <p></p>
EOF
}

# lyshie_20071021: show the usage bar
sub setUsage
{
    print <<EOF;
    <div align="center">
    <table>
        <tr>
            <td id="btn_green" onclick="toggle('green');">
                + $LANG{$LOCALE}{'POP_LOGIN'}
            </td>
            <td id="btn_yellow" onclick="toggle('yellow');">
                + $LANG{$LOCALE}{'POP_LOGOUT'}
            </td>
            <td id="btn_red" onclick="toggle('red');">
                + $LANG{$LOCALE}{'AUTH'}
            </td>
            <td id="btn_imap_green" onclick="toggle('imap_green');">
                + $LANG{$LOCALE}{'IMAP_LOGIN'}
            </td>
            <td id="btn_imap_yellow" onclick="toggle('imap_yellow');">
                + $LANG{$LOCALE}{'IMAP_LOGOUT'}
            </td>
            <td id="btn_imap_pink" onclick="toggle('imap_pink');">
                + $LANG{$LOCALE}{'IMAP_DELMB'}
            </td>
            <td id="btn_imap_gray" onclick="toggle('imap_gray');">
                + $LANG{$LOCALE}{'IMAP_EXPUNGE'}
            </td>
        </tr>
    </table>
    <hr width="40%">
    </div>
EOF
}

sub sort_datetime
{
    (split(/\t/, $a))[1] cmp (split(/\t/, $b))[1];
}

# lyshie_20071021: dump the log file
sub getLog
{
    my $ref = $LOG_HOSTS{$HOST};
    my @logfiles = @$ref;

    my @buffers = ();

    foreach my $f (@logfiles) {
        my $file = "$LOG_CACHE/" . $f . "/$DATE/$ACCOUNT";
        if (-e $file) {
            open(FH, $file);
            push(@buffers, <FH>);
            close(FH);
        }
    }

    @buffers = sort sort_datetime @buffers;

    my $type = $TYPE;
    if ($type eq "all")
    {
    }
    else # default show all kinds of log messages
    {
        if (@buffers > 0)
        {
            setUsage();
            printf("<div align=\"center\"><table width=\"50%\">\n");
            printf(  "<tr><th>$LANG{$LOCALE}{'NO'}</th>"
                   . "<th>$LANG{$LOCALE}{'DATETIME'}</th>"
                   . "<th colspan=\"3\">$LANG{$LOCALE}{'INFORMATION'}</th>"
                   . "<th>$LANG{$LOCALE}{'TYPE'}</th></tr>\n");
            my $line;
            my @field;
            my $count = 0;
            foreach (@buffers)
            {
                $line = $_;
                chomp($line);
                $line =~ s/[\r\n]//g;
                @field = split(/\t/, $line);
                if ($field[0] eq "+pop-login") # POP3 login OK
                {
                    $count++;
                    printf(
                           "<tr id=\"green\" name=\"green\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"3\">%s</td><td>%s</td></tr>\n",
                           $count, $field[1], 
                           $field[2], $LANG{$LOCALE}{'POP_LOGIN'} 
                          );
                }
                elsif ($field[0] eq "+pop-logout") # POP3 logout OK
                {
                    $count++;
                    printf(
                           "<tr id=\"yellow\" name=\"yellow\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td>%s $LANG{$LOCALE}{'POP_DELETE'}</td>"
                             . "<td>%s $LANG{$LOCALE}{'POP_LEAVE'}</td>"
                             . "<td>%s $LANG{$LOCALE}{'POP_USED'}</td><td>%s</td>"
                             . "</tr>\n",
                           $count,
                           $field[1], $field[4],
                           $field[5], getSize($field[6]),
                           $LANG{$LOCALE}{'POP_LOGOUT'}
                          );
                }
                elsif ($field[0] eq "-auth") # auth ERROR
                {
                    $count++;
                    printf(
                           "<tr id=\"red\" name=\"red\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"2\">%s</td><td>%s</td>"
                             . "<td>%s</td></tr>\n",
                           $count, 
                           $field[1], $field[2], $field[3], 
                           $LANG{$LOCALE}{'AUTH'}
                          );
                }
                elsif ($field[0] eq "+imap-login" ) # IMAP Login
                {
                    $count++;
                    printf(
                           "<tr id=\"imap_green\" name=\"imap_green\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"3\">%s</td><td>%s</td></tr>\n",
                           $count, $field[1],
                           $field[2], $LANG{$LOCALE}{'IMAP_LOGIN'}
                          );
                }
                elsif ($field[0] eq "+imap-logout") # IMAP Logout
                {
                    $count++;
                    printf(
                           "<tr id=\"imap_yellow\" name=\"imap_yellow\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"3\">&nbsp;</td>"
                             . "<td>%s</td>"
                             . "</tr>\n",
                           $count,
                           $field[1],
                           $LANG{$LOCALE}{'IMAP_LOGOUT'}
                          );
                }
                elsif ($field[0] eq "+imap-delete-mailbox") # IMAP del mailbox
                {
                    $count++;
                    my $utf7 = Unicode::IMAPUtf7->new();
                    printf(
                           "<tr id=\"imap_pink\" name=\"imap_pink\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"3\">%s%s</td>"
                             . "<td>%s</td>"
                             . "</tr>\n",
                           $count,
                           $field[1],
                           $LANG{$LOCALE}{'IMAP_DEL'},
                           $utf7->decode($field[2]),
                           $LANG{$LOCALE}{'IMAP_DELMB'}
                          );
                }
                elsif ($field[0] eq "+imap-expunge") # IMAP expunge
                {
                    $count++;
                    my $utf7 = Unicode::IMAPUtf7->new();
                    printf(
                           "<tr id=\"imap_gray\" name=\"imap_gray\">"
                             . "<td>%s</td><td>%s</td>"
                             . "<td colspan=\"3\">%s (%s - %s)</td>"
                             . "<td>%s</td>"
                             . "</tr>\n",
                           $count,
                           $field[1],
                           $LANG{$LOCALE}{'IMAP_EXP'},
                           $utf7->decode($field[2]),
                           $field[3],
                           $LANG{$LOCALE}{'IMAP_EXPUNGE'}
                          );
                }
            }
            printf(
                   "<tr><th colspan=\"5\">$LANG{$LOCALE}{'RECORDS'}</th>"
                     . "<th id=\"count\">%s</th></tr>\n",
                   $count
                  );
            printf("</table></div>\n");
        }
        else
        {
            setError($LANG{$LOCALE}{'ERR_OPENLOG'});
        }
    }
}

# lyshie_20071021: show the error message
sub setError
{
    my $msg = shift();
    printf(
           "<div align=\"center\">"
             . "<h3 style=\"color: red;\">$LANG{$LOCALE}{'ERR'}%s</h3>"
             . "</div>\n",
           $msg
          );
}

# lyshie_20071021: check POP3 auth
sub getPOPCheck
{
    if (($ACCOUNT eq '') || ($PASSWORD eq '')) { return 0; }
    my $pop = Net::POP3->new("pop.$HOST", Timeout => 5);
    if (defined($pop->login($ACCOUNT, $PASSWORD))) {
        $pop->quit();
        return 1;
    }
    else {
        return 0;
    }
}

# lyshie_20071021: check the host name
sub getHostCheck
{
    if ($HOST eq '') { return 0; }
    if (!defined($LOG_HOSTS{$HOST})) { return 0; }
    return 1;
}

# lyshie_20071021: check for security
sub getAuth
{
    if (getPOPCheck())
    {
        if (getHostCheck())
        {
            getLog();
        }
        else
        {
            setError($LANG{$LOCALE}{'ERR_HOST'});
        }
    }
    else
    {
        setError($LANG{$LOCALE}{'ERR_POP3'});
    }
}

# lyshie_20071021: get the global http parameters and check its valid format
sub getParam
{
    $HOST = lc(param("host")) || "";
    $HOST =~ s/[^a-zA-Z0-9\.]//g;    # only for alphabet and digits
    $ACCOUNT  = param("account")  || "";
    $ACCOUNT  =~ s/[^a-zA-Z0-9\.\-\_]//g;
    $PASSWORD = param("password") || "";
    $DATE     = param("date")     || "current";
    $DATE =~ s/[^a-zA-Z0-9\-]//g;    # only for digits and `-`
    $TYPE = lc(param("type")) || "";
    $LANG = lc(param("lang")) || "";
    $LANG =~ s/[^a-zA-Z]//g;
    if ($DATE eq 'current') {
        $DIRTY_DATE{$DATE} = '今天 (Today)';
    }
    else {
        $DIRTY_DATE{$DATE} = $DATE;
    }
}

sub main
{
    getParam();
    htmlLanguage($LANG);
    htmlHeader();
    htmlTitle($LANG{$LOCALE}{'TITLE'});
    getQueryInfo();
    getAuth();
    htmlFooter();
}

main();

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
use CGIConfig qw(:all);

sub main;
sub serForm;
sub getDate;

# lyshie_20071021: convert unix time to YYYY/MM/DD format
sub getDate
{
    my $epoch = shift();
    my ($sec, $min, $hour, $day, $month, $year) = localtime($epoch);
    return sprintf("%04d/%02d/%02d", $year + 1900, $month + 1, $day);
}

sub setForm
{
    print <<EOF;
    <div align="center">
    <table>
    <form action="query.cgi" method="post">
        <tr>
            <th>語言 (Language)</th>
            <td style="text-align: left;">
                <select name="lang" size="1">
EOF
    foreach (sort { $b cmp $a } (keys(%LANG)))
    {
        printf("<option value=\"%s\">%s</option>\n", $_, $LANG{$_}{'LANG'});
    }
    print <<EOF;
                </select>
            </td>
        </tr>
        <tr>
            <th>帳號 (Account)</th>
            <td style="text-align: left;">
                <input type="text" name="account" size="8" />@ oz.nthu.edu.tw
                <input type="hidden" name="host" value="oz.nthu.edu.tw">
<!--
                <select name="host" size="1">
EOF
    foreach(@LOG_HOSTS_ARRAY)
    {
        printf("<option value=\"%s\">%s</option>\n", $_, $_);
    }
    print <<EOF;
                </select>
-->
            </td>
        </tr>
        <tr>
            <th>密碼 (Password)</th>
            <td style="text-align: left;">
                <input type="password" name="password" size="8" />
            </td>
        </tr>
        <tr>
            <th>日期 (Date)</th>
            <td style="text-align: left;">
                <select name="date" size="1">
                <option value="current">今天 (today)</option>
EOF
    my $now = time();
    my $date;
    # lyshie_20071021: list the latest 6 days
    for (my $i = 1 ; $i < 7 ; $i++)
    {
        $now -= 86400;
        $date = getDate($now);
        $date =~ s/\//\-/g;
        printf("<option value=\"%s\">%s</option>\n", $date, $date);
    }
    print <<EOF;
                </select>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <input type="submit" value="查詢 (Query)" />
                <input type="reset" value="重設 (Reset)" />
            </td>
        </tr>
    </form>
    </table>
    </div>
EOF
}

sub main
{
#    htmlLanguage();
    htmlHeader("$LANG{'tw'}{'TITLE'} ($LANG{'en'}{'TITLE'})");
    htmlTitle("$LANG{'tw'}{'TITLE'} ($LANG{'en'}{'TITLE'})");
    setForm();
    htmlFooter();
}

main();

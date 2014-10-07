package CGIConfig;
#
# Author       : Shie, Li-Yi
# Organization : National Tsing Hua Uiversity
# Email        : lyshie@mx.nthu.edu.tw
# License      : GPL
#
use Exporter;
use CGI qw(:standard);
use FindBin qw($Bin);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [
        qw($LOG_CACHE %LOG_HOSTS @LOG_HOSTS_ARRAY
          htmlHeader htmlFooter htmlTitle htmlLanguage
          %LANG $LOCALE
          )
    ]
);
our @EXPORT    = ();
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

# lyshie_20071012: mail logs
our $LOG_CACHE = "/home/logger/tmp";

# lyshie_20071022: FQDN list
our @LOG_HOSTS_ARRAY = ('oz.nthu.edu.tw',
#                        'mx.nthu.edu.tw',
#                        'my.nthu.edu.tw',
#                        'cc.nthu.edu.tw',
#                        'inn.nthu.edu.tw',
#                        'ust.edu.tw',
#                        'net.nthu.edu.tw',
                       );
# lyshie_20071022: FQDN to path name
our %LOG_HOSTS = (
                  'oz.nthu.edu.tw'  => ['imap1-oz', 'imap2-oz'],
#                  'mx.nthu.edu.tw'  => 'mx',
#                  'my.nthu.edu.tw'  => 'my',
#                  'cc.nthu.edu.tw'  => 'cc',
#                  'inn.nthu.edu.tw' => 'inn',
#                  'ust.edu.tw'      => 'thccy31',
#                  'net.nthu.edu.tw' => 's92',
                 );

# lyshie_20071021: language resource
our %LANG   = ();

# lyshie_20071021: default language is traditional chinese
our $LOCALE = 'tw';

sub htmlHeader;
sub htmlFooter;
sub htmlTitle;
sub htmlLanguage;

# lyshie_20071021: set the language
sub htmlLanguage
{
    my $locale = shift();
    if ($LANG{$locale})
    {
        $LOCALE = $locale;
    }
}

sub htmlTitle
{
    my $title = shift();
    printf("<div align=\"center\"><h2>%s</h2></div>\n", $title);
}

sub htmlHeader
{
    my $title = shift();
    if (!defined $title) { $title = $LANG{$LOCALE}{'TITLE'}; }
    print header(-charset => 'utf-8');
    print <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
    <title>$title</title>
    <style>
        body {
                font-size: 10pt;
                font-family: Tahoma;
        }
        table {
                border-width: 1px;
                border-style: solid;
                border-color: black;
                border-collapse: collapse;
                background-color: white;
        }
        th {
                border-width: 1px;
                padding-top: 4px;
                padding-bottom: 4px;
                padding-left: 4px;
                padding-right: 4px;
                padding: 4px;
                border-style: solid;
                border-color: black;
                background-color: white;
                text-align: center;
                background-color: #afffaf;
                font-size: 10pt;
                white-space: nowrap;
        }
        td {
                border-width: 1px;
                padding-top: 4px;
                padding-bottom: 4px;
                padding-left: 4px;
                padding-right: 4px;
                padding: 4px;
                border-style: solid;
                border-color: black;
                background-color: white;
                text-align: center;
                background-color: #dfffdf;
                font-size: 10pt;
                white-space: nowrap;
        }
        tr#green > td, td#green, td#btn_green {
                background-color: rgb(200, 240, 240);
                white-space: nowrap;
        }
        tr#yellow > td, td#yellow, td#btn_yellow {
                background-color: rgb(240, 240, 200);
                white-space: nowrap;
        }
        tr#red > td, td#red, td#btn_red {
                background-color: rgb(240, 200, 240);
                white-space: nowrap;
        }
        tr#imap_green > td, td#imap_green, td#btn_imap_green {
                background-color: lime;
                white-space: nowrap;
        }
        tr#imap_yellow > td, td#imap_yellow, td#btn_imap_yellow {
                background-color: orange;
                white-space: nowrap;
        }
        tr#imap_pink > td, td#imap_pink, td#btn_imap_pink {
                background-color: pink;
                white-space: nowrap;
        }
        tr#imap_gray > td, td#imap_gray, td#btn_imap_gray {
                background-color: gray;
                white-space: nowrap;
        }
    </style>
    <script language="javascript">
        function toggle(id) {
            // lyshie_20071024: toggle enable/disable
            var btn = document.getElementById('btn_' + id);
            var str =
                btn.innerHTML.replace(/\^\\s*/g, '').replace(/\\s*\$/g, ''); 
            if (str.substr(0, 1) == '+') {
                str = str.replace(/\^\\+/, '-');
            }
            else if (str.substr(0, 1) == '-') { 
                str = str.replace(/\^\\-/, '+');
            }
            btn.innerHTML = str;

            // lyshie_20071024: toggle display
            var objs = document.getElementsByName(id);
            var num = document.getElementById('count').innerHTML;
            for (var i = 0; i < objs.length; i++) {
                if (objs[i].style.display == '') {
                    objs[i].style.display = 'none';
                    num--;
                }
                else {
                    objs[i].style.display = '';
                    num++;
                }
            }
            // lyshie_20071024: show the number of records
            document.getElementById('count').innerHTML = num;
        }
    </script>
</head>
<body>
EOF
}

sub htmlFooter
{
    print <<EOF;
<div align="center">
    <hr width="40%">
    $LANG{$LOCALE}{"FOOTER"}
</div>
</body>
</html>
EOF
}

# lyshie_20071021: language usage is `$LANG{'tw'}{'TITLE'}`
%LANG = (
         'en' => {
                  'LANG'   => 'English',
                  'FOOTER' => 'Computer and Communication Center<br />'
                    . 'National Tsing Hua University',
                  'TITLE'       => 'POP Log Query',
                  'NO'          => 'No.',
                  'TYPE'        => 'Type',
                  'DATETIME'    => 'Date Time',
                  'INFORMATION' => 'Information',
                  'USER'        => 'User',
                  'ERR'         => 'Error: ',
                  'ERR_HOST'    => 'The host you specified doesn\'t exist!',
                  'ERR_POP3'    => 'POP3 check failed!',
                  'ERR_OPENLOG' => 'Can\'t open the mail log!',
                  'RECORDS'     => 'Number of records',
                  'POP_LOGIN'   => 'POP3 Login',
                  'POP_LOGOUT'  => 'POP3 Logout',
                  'AUTH'        => 'Auth Failed',
                  'POP_DELETE'  => '(delete)',
                  'POP_LEAVE'   => '(leave)',
                  'POP_USED'    => '(used before deleting)',
                  'INFO_LANG'   => 'Language: ',
                  'INFO_ACCT'   => 'Account: ',
                  'INFO_DATE'   => 'Date: ',
                  'IMAP_LOGIN'  => 'IMAP Login',
                  'IMAP_LOGOUT' => 'IMAP Logout',
                  'IMAP_DELMB'  => 'IMAP Delete Mailbox',
                  'IMAP_DEL'    => 'Delete Mailbox: ',
                  'IMAP_EXPUNGE'=> 'IMAP Expunge',
                  'IMAP_EXP'    => 'Expunge Mail',
                 },
         'tw' => {
                  'LANG'   => '正體中文',
                  'FOOTER' => '網路系統組<br />'
                    . '國立清華大學 計算機與通訊中心',
                  'TITLE'       => 'POP 郵件記錄查詢系統',
                  'NO'          => '編號',
                  'TYPE'        => '類型',
                  'DATETIME'    => '日期時間',
                  'INFORMATION' => '資訊',
                  'USER'        => '使用者',
                  'ERR'         => '錯誤：',
                  'ERR_HOST'    => '指定的主機名稱不存在！',
                  'ERR_POP3'    => 'POP3 驗證失敗！',
                  'ERR_OPENLOG' => '無法開啟指定的記錄檔！',
                  'RECORDS'     => '記錄筆數',
                  'POP_LOGIN'   => 'POP3 登入',
                  'POP_LOGOUT'  => 'POP3 登出',
                  'AUTH'        => '驗證失敗',
                  'POP_DELETE'  => '(刪除)',
                  'POP_LEAVE'   => '(保留)',
                  'POP_USED'    => '(刪除前使用空間)',
                  'INFO_LANG'   => '語言：',
                  'INFO_ACCT'   => '帳戶名稱：',
                  'INFO_DATE'   => '日期：',
                  'IMAP_LOGIN'  => 'IMAP 登入',
                  'IMAP_LOGOUT' => 'IMAP 登出',
                  'IMAP_DELMB'  => 'IMAP 刪除信箱',
                  'IMAP_DEL'    => '刪除信箱：',
                  'IMAP_EXPUNGE'=> 'IMAP 刪除信件',
                  'IMAP_EXP'    => '刪除信件',
                 },
#         'cn' => {
#                  'LANG'   => '简体中文',
#                  'FOOTER' => '网路系统组<br />'
#                    . '国立清华大学 计算机与通讯中心',
#                  'TITLE'       => 'POP 邮件记录查询系统',
#                  'NO'          => '编号',
#                  'TYPE'        => '类型',
#                  'DATETIME'    => '日期时间',
#                  'INFORMATION' => '资讯',
#                  'USER'        => '使用者',
#                  'ERR'         => '错误：',
#                  'ERR_HOST'    => '指定的主机名称不存在！',
#                  'ERR_POP3'    => 'POP3 验证失败！',
#                  'ERR_OPENLOG' => '无法开启指定的记录档！',
#                  'RECORDS'     => '记录笔数',
#                  'POP_LOGIN'   => 'POP3 登入',
#                  'POP_LOGOUT'  => 'POP3 登出',
#                  'AUTH'        => '验证失败',
#                  'POP_DELETE'  => '(删除)',
#                  'POP_LEAVE'   => '(保留)',
#                  'POP_USED'    => '(删除前使用空间)',
#                  'INFO_LANG'   => '语言：',
#                  'INFO_ACCT'   => '帐户名称：',
#                  'INFO_DATE'   => '日期：',
#                  'IMAP_LOGIN'  => 'IMAP 登入',
#                  'IMAP_LOGOUT' => 'IMAP 登出',
#                  'IMAP_DELMB'  => 'IMAP 删除信箱',
#                  'IMAP_DEL'    => '删除信箱：',
#                  'IMAP_EXPUNGE'=> 'IMAP 删除信件',
#                  'IMAP_EXP'    => '删除信件',
#                 }
        );
1;

package LoggerConfig;
#
# Author       : Shie, Li-Yi
# Organization : National Tsing Hua Uiversity
# Email        : lyshie@mx.nthu.edu.tw
# License      : GPL
#
use Exporter;
use FindBin qw($Bin);

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw($LOG_PATH $LOG_POP3D $LOG_CACHE
                                   $LOG_POS $LOG_DATE $DURATION) ] );
our @EXPORT      = ();
our @EXPORT_OK   = @{ $EXPORT_TAGS{'all'} };

# lyshie_20071012: the default log pool
our $LOG_PATH  = "/logpool/HOSTS";

# lyshie_20071019: the dovecot-pop3d log file
our $LOG_POP3D = "local5";

# lyshie_20071012: the qmail-pop3d log file
#our $LOG_POP3D = "local0";

# lyshie_20071012: tmp
our $LOG_CACHE = "/home/logger/tmp";

# lyshie_20071023: file position
our $LOG_POS   = "current";

#lyshie_20071023: latest date
our $LOG_DATE  = "date";

# lyshie_20071023: every $ seconds to read the log file
our $DURATION  = 3;

1;

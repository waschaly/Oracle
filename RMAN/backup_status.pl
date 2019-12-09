#!/oracle/1120/perl/bin/perl -w

#
##
## Systemweite Includes
##
#
use strict;
use Oraperl;
use Env;
use FileHandle;
use Getopt::Long;
use Pod::Usage;

# 
##
## ProjectIncludes
##
#
use vars qw( %ErrorList $ErrorCode );

use db_io;

#
##
## End Include
##
#

#
##
## Variablendeklaration 
##
#

my ( $database );
my ( $sql_select, $dbhandle );
my ( $linecount, $fieldSeparator ) = ( 0, ',' );

my ( %cmdLine ) = ();
my ( %connect ) = (
	user 	=>		'',
	passwd	=>		'',
	host	=>		'',
	instanz	=>		'',
	tcpport	=>		1521	
);

my ( %backup ) = (
	'online'	=>		'DB FULL',
	'offline'	=>		'DB FULL',
	'archive'	=>		'ARCHIVELOG'
);

#
## Datenbank Spaltennamen Variablen 
#

my ( $START_TIME, $END_TIME, $INPUT_BYTES, $OUTPUT_BYTES, $OBJECT_TYPE, $STATUS );

#
##
## End Variablendeklaration 
##
#

GetOptions ( 
	\%cmdLine,
	"instanz=s",
	"backup_type=s",
	"start_time",
	"fs=s"
);

if ( defined $cmdLine { 'instanz' } ) {
	$connect { 'instanz' } = $cmdLine { 'instanz' };
}

if ( defined $cmdLine { 'backup_type' } ) {
	$OBJECT_TYPE = $cmdLine { 'backup_type' };
}

if ( defined $cmdLine { 'fs' } ) {
	$fieldSeparator = $cmdLine { 'fs' };
}

if ( defined $cmdLine { 'start_time' } ) {
	$START_TIME = $cmdLine { 'start_time' };
}


$database = db_connect ( %connect );

if ( ! defined $database ) {

	print $ErrorList { $ErrorCode } . "\n";
	print DBI::errstr () . "\n";

	exit ( 1 );

}

$sql_select = qq{
	SELECT
		START_TIME, END_TIME, INPUT_BYTES, OUTPUT_BYTES, OBJECT_TYPE,
		STATUS
	FROM
		V\$RMAN_STATUS
	WHERE
		START_TIME >= SYSDATE - 1
	AND
		OBJECT_TYPE = :OBJECT_TYPE
	AND
		OPERATION = 'BACKUP'
	AND
	RECID = (
		SELECT
			MAX ( RECID ) MAX_RECID
		FROM
			V\$RMAN_STATUS
		WHERE
			OBJECT_TYPE = :OBJECT_TYPE
		AND
			OPERATION = 'BACKUP'
	)
	ORDER BY
		END_TIME
};

$dbhandle = $database->prepare ( $sql_select );
if ( ! $dbhandle ) {
        print "REP prepare Error\n";
        exit ( 1 );
}

$dbhandle->bind_param (
	":OBJECT_TYPE", $backup { $OBJECT_TYPE }
);

$dbhandle->execute ()
	or die "Can't execute : $DBI::errstr\n";

$dbhandle->bind_columns (
	undef, \$START_TIME, \$END_TIME, \$INPUT_BYTES, \$OUTPUT_BYTES, \$OBJECT_TYPE, \$STATUS
);

while ( $dbhandle->fetch () ) {

	$linecount++;

	print 
		$START_TIME . $fieldSeparator .
		$END_TIME . $fieldSeparator .
		$INPUT_BYTES . $fieldSeparator .
		$OUTPUT_BYTES . $fieldSeparator .
		$OBJECT_TYPE . $fieldSeparator .
		$STATUS;

}

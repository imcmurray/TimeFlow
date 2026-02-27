/// CSV test fixtures for ServerFlow tests.

const validCsvAllColumns =
    '''host,command,start_time,user,category,duration,schedule,os,end_time
web-prod-01,/usr/bin/backup.sh,2025-01-15T02:30:00Z,root,backup,3600,0 2 * * *,linux,
db-prod-01,/opt/scripts/vacuum.sh,2025-01-15T03:00:00Z,postgres,maintenance,1800,0 3 * * 0,linux,
web-prod-02,/usr/local/bin/deploy.sh,2025-01-15T10:00:00Z,deploy,deployment,0,once,linux,2025-01-15T10:30:00Z''';

const validCsvMandatoryOnly = '''host,command,start_time,user
web-prod-01,/usr/bin/backup.sh,2025-01-15T02:30:00Z,root
db-prod-01,/opt/scripts/vacuum.sh,2025-01-15T03:00:00Z,postgres''';

const validCsvSemicolonDelimited = '''host;command;start_time;user
web-prod-01;/usr/bin/backup.sh;2025-01-15T02:30:00Z;root
db-prod-01;/opt/scripts/vacuum.sh;2025-01-15T03:00:00Z;postgres''';

const validCsvTabDelimited = 'host\tcommand\tstart_time\tuser\n'
    'web-prod-01\t/usr/bin/backup.sh\t2025-01-15T02:30:00Z\troot\n'
    'db-prod-01\t/opt/scripts/vacuum.sh\t2025-01-15T03:00:00Z\tpostgres';

const validCsvCaseInsensitiveHeaders = '''Host,COMMAND,Start_Time,USER
web-prod-01,/usr/bin/backup.sh,2025-01-15T02:30:00Z,root''';

const csvMissingHostColumn = '''command,start_time,user
/usr/bin/backup.sh,2025-01-15T02:30:00Z,root''';

const csvMissingMultipleColumns = '''host,start_time
web-prod-01,2025-01-15T02:30:00Z''';

const csvUnparseableStartTime = '''host,command,start_time,user
web-prod-01,/usr/bin/backup.sh,not-a-date,root
db-prod-01,/opt/scripts/vacuum.sh,2025-01-15T03:00:00Z,postgres''';

const csvEndTimeOverridesDuration =
    '''host,command,start_time,user,duration,end_time
web-prod-01,/usr/bin/backup.sh,2025-01-15T02:30:00Z,root,3600,2025-01-15T04:00:00Z''';

const csvEmptyOptionalDefaults =
    '''host,command,start_time,user,category,duration,schedule,os
web-prod-01,/usr/bin/backup.sh,2025-01-15T02:30:00Z,root,,,,''';

const csvEmptyContent = '';

const csvHeaderOnly = '''host,command,start_time,user''';

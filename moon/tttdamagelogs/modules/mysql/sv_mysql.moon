require('mysqloo')

hook.Add 'TTTDamagelogsDatabaseConnected', 'TTTDamagelogs_InitRequest', () ->
    initRequests = file.Read('addons/tttdamagelogs/sql/init.sql', 'GAME')
    query = dmglog.db\query(initRequests)
    query\start!

ConnectToDatabase = () ->
    mysqlConfig = dmglog.IncludeServerFile('sv_mysql_config.lua')
    with dmglog.db = mysqloo.connect(mysqlConfig.host, mysqlConfig.username, mysqlConfig.password, mysqlConfig.db_name, mysqlConfig.db_port)
        \setMultiStatements(true)
        .onConnected = () =>
            hook.Run('TTTDamagelogsDatabaseConnected')
        \connect!

ConnectToDatabase!
require('mysqloo')

dmglog.IncludeServerFile('sv_mysql_config.lua')

db = mysqloo.connect(mysql_config.host, mysql_config.username, mysql_config.password, mysql_config.db_name, mysql_config.db_port)
init_requests = file.Read('addons/tttdamagelogs/lua/tttdamagelogs/modules/mysql/init.sql', 'GAME')

onInitSuccess = ->
    dmglog.db = db

db.onConnected = (self) ->
    query = db\query(init_requests)
    query.onSuccess = onInitSuccess
    query\start!
    
db\setMultiStatements(true)
db\connect!
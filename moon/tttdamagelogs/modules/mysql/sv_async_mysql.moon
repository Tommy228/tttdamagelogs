dmglog.mysql = 

    Query: (query) ->
        return Promise (resolve) ->
            query.onSuccess = () =>
                resolve(false)
            query.onError = (sql, err) =>
                resolve(true)
            query\start!
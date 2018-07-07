dmglog.mysql = 

    Query: (query) ->
        return Promise (resolve, reject) ->
            query.onSuccess = () =>
                resolve(false)
            query.onError = (sql, err) =>
                reject(err)
            query\start!
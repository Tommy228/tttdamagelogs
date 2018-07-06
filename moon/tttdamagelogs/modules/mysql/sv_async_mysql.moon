dmglog.mysql = 

    QueryAndGetData: (query) ->
        print('returning promise')
        return Promise (resolve) ->
            print('promise start')
            query.onSuccess = () =>
                print('success')
                resolve(@getData!)
            query.onError = (sql, err) =>
                print('fail lol')
                resolve(false)
            query\start!
dmglog.table = 

    Find: (tbl, predicate) ->
        for key, item in pairs(tbl)
            return item if predicate(item)

    FindKey: (tbl, predicate) ->
        for key, item in pairs(tbl)
            return key if predicate(item)
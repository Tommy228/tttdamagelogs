export class Promise

    new: (func) =>
        @func = func

    start: () =>
        baseCoroutine = coroutine.running!
        startFunc = () ->
            resolve = (...) ->
                coroutine.resume(baseCoroutine, ...)
            self.func(resolve)
        subCoroutine = coroutine.create(startFunc)
        coroutine.resume(subCoroutine)
        return coroutine.yield!

export async = (func) ->
    return (...) ->
        args = {...}
        coroutineFunc = () ->
            func(unpack(args))
        c = coroutine.create(coroutineFunc)
        coroutine.resume(c)

export await = (promise) ->
    return promise\start!
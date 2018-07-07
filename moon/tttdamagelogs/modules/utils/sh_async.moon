export class Promise

    new: (func) =>
        @func = func

    @reject = (msg) ->
        error(msg)

    Start: () =>
        baseCoroutine = coroutine.running!
        startFunc = () ->
            resolve = (...) ->
                coroutine.resume(baseCoroutine, ...)
            self.func(resolve, @@reject)
        subCoroutine = coroutine.create(startFunc)
        coroutine.resume(subCoroutine)
        return coroutine.yield!

export async = (func) ->
    return (...) ->
        args = {...}
        coroutineFunc = () ->
            func(unpack(args))
        c = coroutine.create(coroutineFunc)
        succeeded, errors = coroutine.resume(c)
        if not succeeded
            error(errors)

export await = (promise) ->
    return promise\Start!
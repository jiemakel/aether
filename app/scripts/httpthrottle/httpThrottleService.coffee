'use strict'

angular.module('fi.seco.httpthrottle',[])
  .value('maxRequests',10)
  .factory("httpThrottler", ($q, maxRequests, $log) ->
    status = {}
    retryHttpRequest = (config, deferred) ->
      if config?
        deferred.resolve(config)
    httpBuffer =
      append: (config, deferred) ->
        status[config.url].buffer.push(
          config: config
          deferred: deferred
        )
      retryOne: (url) ->
        if status[url].buffer.length > 0
          req = status[url].buffer.pop()
          retryHttpRequest(req.config, req.deferred)
    {
    request: (config) ->
      if (!status[config.url]) then status[config.url] = { buffer: [], reqCount : 0}
      if status[config.url].reqCount >= maxRequests
        deferred = $q.defer()
        httpBuffer.append(config, deferred)
        return deferred.promise
      else
        status[config.url].reqCount++
        return config || $q.when(config)
    requestError: (rejection) ->
      status[rejection.config.url].reqCount--
      httpBuffer.retryOne(rejection.config.url)
      return $q.reject(rejection)
    responseError: (rejection) ->
      status[rejection.config.url].reqCount--
      httpBuffer.retryOne(rejection.config.url)
      return $q.reject(rejection)
    response: (response) ->
      status[response.config.url].reqCount--
      httpBuffer.retryOne(response.config.url)
      return response || $q.when(response)
    }
  )
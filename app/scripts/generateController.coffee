'use strict'

angular.module('fi.seco.aether')
  .controller('GenerateCtrl', ($stateParams,$window,$scope,$modal,$timeout,sparql,voidService) ->
    $scope.Math=$window.Math
    $scope.errors=[]
    handleError = (data,status,headers,config) ->
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.data ? config.params.query, error: data })
    $scope.stats = voidService.generateStats
    $scope.main = { processed : 0, total : $scope.stats.length }
    $scope.statFilter = () ->
      (item) ->
        voidService.partitionStatInfo[item]?
    $scope.statStatus = {}
    $scope.subStatStatus = {}
    calculateStatistic = (track,statName,limitStat,limitTarget,retries) ->
      voidService.calculateStatistic($stateParams.sparqlEndpoint,$stateParams.graphIRI,statName,limitStat,limitTarget).success((data,status,headers,config) ->
        if (!data.head?.vars?)
          if (retries>0)
            calculateStatistic(track,statName,limitStat,limitTarget,retries-1)
          else
            if (limitStat=='none')
              $scope.statStatus[statName]='error'
              $scope.main.errors++
            else if (!track.errored)
              track.errored = true
              $scope.subStatStatus[limitStat].errors++
            $scope.total.errors+=2
            handleError(data,status+', but bad data',headers,config)
        else
          $scope.total.processed++
          if ($stateParams.doSelections==true && limitStat=='none' && voidService.partitionStatInfo[statName])
            info = { errors: 0, processed: 0, total : data.results.bindings.length}
            $scope.subStatStatus[statName] = info
            $scope.total.total += data.results.bindings.length*2*$scope.stats.length
            for binding in data.results.bindings
              calculateStatistics(statName,sparql.bindingToString(binding[voidService.partitionStatInfo[statName].binding]))
          voidService.insertReadyStatistic($stateParams.sparulEndpoint,$stateParams.updateGraphIRI,$stateParams.datasetIRI,statName,limitStat,limitTarget,data).success((data) ->
            if (limitStat=='none')
              $scope.statStatus[statName]='ok'
              $scope.main.processed++
            else if (++track.successfulParts==$scope.stats.length) then $scope.subStatStatus[limitStat].processed++
            $scope.total.processed++
          ).error((data,status,headers,config) ->
            if (limitStat=='none')
              $scope.statStatus[statName]='error'
              $scope.main.errors++
            else if (!track.errored)
              track.errored = true
              $scope.subStatStatus[limitStat].errors++
            $scope.total.errors++
            handleError(data,status,headers,config)
          )
      ).error((data,status,headers,config) ->
        if (limitStat=='none')
          $scope.main.errors++
          $scope.statStatus[statName]='error'
        else if (!track.errored)
          track.errored = true
          $scope.subStatStatus[limitStat].errors++
        $scope.total.errors+=2
        handleError(data,status,headers,config)
      )
    calculateStatistics = (limitStat,limitTarget) ->
      track = { successfulParts : 0, errored : false }
      for statName in voidService.generateStats then do (statName) ->
        calculateStatistic(track,statName,limitStat,limitTarget,3)
    $scope.startTime = new Date()
    $scope.total = {
      processed : 0, errors : 0, total : 2*$scope.stats.length
    }
    timer = null
    updateDate = () ->
      $scope.curTime = new Date()
      timer = $timeout(updateDate,1000)
    updateDate()
    voidService.insertMetadata($stateParams.sparulEndpoint,$stateParams.updateGraphIRI,"<#{$stateParams.sparqlEndpoint}>",$stateParams.graphIRI,"<#{$stateParams.datasetIRI}>",$scope.startTime.toISOString(),window.user_ip_address).success((data) ->
      calculateStatistics('none',null)
    ).error(handleError)
    $scope.sparqlEndpoint = $stateParams.sparulEndpoint.replace('update','sparql')
    $scope.graphIRI = $stateParams.updateGraphIRI
    $scope.datasetIRI = $stateParams.datasetIRI
    $scope.doSelections = $stateParams.doSelections
    $scope.$watchCollection('[ total.processed, total.errors ]', () ->
      if ($scope.total)
        if ($scope.total.processed + $scope.total.errors == $scope.total.total)
          $timeout.cancel(timer)
          $scope.endTime = new Date()
          voidService.insertEndTime($stateParams.sparulEndpoint,$stateParams.updateGraphIRI,"<#{$stateParams.datasetIRI}>",$scope.endTime.toISOString()).success((data) ->
            $modal.open({scope:$scope,template:'''
              <div class="modal-header">
                  <h3>Generation Complete</h3>
              </div>
              <div class="modal-body">
                  VoID statistic generation complete in {{((endTime - startTime) / 1000) % (60 * 60 * 24) / (60 * 60) | number: 0}}:{{((endTime - startTime) / 1000) % (60 * 60) / 60 | number: 0}}:{{((endTime - startTime) / 1000) % 60 | number: 0}} with a total of {{total.processed}} successful and {{total.errors}} failed queries.
              </div>
              <div class="modal-footer">
                <button class="btn btn-primary" ng-click="$close()" ui-sref-opts="{location: 'replace'}" ui-sref="view({sparqlEndpoint:sparqlEndpoint,graphIRI:graphIRI,datasetIRI:datasetIRI})">See Results</button>
              </div>
            '''})
          ).error(handleError)
    )
  )


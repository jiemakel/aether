angular.module('app')
  .controller('GenerateCtrl', ($stateParams,$window,$scope,$modal,$timeout,sparql,voidService) ->
    $scope.Math=$window.Math
    $scope.errors=[]
    function handleError(data,status,headers,config)
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.data ? config.params.query, error: data })
    $scope.partitionStats = voidService.tripleStats
    $scope.schemaStats =
      'Subject Type'
      'Subject Namespace'
      'Property'
      'Object Type'
      'Object Namespace'
    $scope.sschemaStats =
      'Subject Type'
      'Subject Namespace'
      'Object Type'
      'Object Namespace'
    $scope.stats = voidService.allStats
    $scope.main = { processed : 0, total : $scope.stats.length }
    $scope.statStatus = {}
    $scope.subStatStatus = {}
    secondaryStats = {}
    function calculateStatistic(track,statName,limits,retries)
      voidService.calculateStatistic($stateParams.sparqlEndpoint,$stateParams.graphIRI,statName,limits).success((data,status,headers,config) ->
        if (!data.head?.vars?)
          if (retries>0)
            calculateStatistic(track,statName,limits,retries-1)
          else
            if (!limits)
              $scope.statStatus[statName]='error'
              $scope.main.errors++
            else if (!track.errored)
              track.errored = true
              limitStat = [limit.stat for limit in limits].join('-')
              $scope.subStatStatus[limitStat].errors++
            $scope.total.errors+=2
            handleError(data,status+', but bad data',headers,config)
        else
          $scope.total.processed++
          voidService.insertReadyStatistic($stateParams.sparulEndpoint,$stateParams.updateGraphIRI,$stateParams.datasetIRI,statName,limits,data).success(!->
            if limits==null
              if ($stateParams.doAllSingleSelections && voidService.partitionStatInfo[statName]) || ($stateParams.doSchemaSelections && statName in $scope.schemaStats)
                info = { errors: 0, processed: 0, total : data.results.bindings.length}
                $scope.subStatStatus[statName] = info
                for binding in data.results.bindings
                  value = sparql.bindingToString(binding[voidService.partitionStatInfo[statName].binding])
                  $scope.total.total += calculateStatistics([{stat:statName,value:value}])
            else if limits.length==1 && $stateParams.doSchemaSelections && ((limits[0].stat=='Property' && statName in $scope.sschemaStats) || (limits[0].stat in $scope.sschemaStats && statName=='Property'))
              sstatName = 'Property-' + (if (statName=='Property') then limits[0].stat else statName)
              if (!$scope.subStatStatus[sstatName]) then $scope.subStatStatus[sstatName] = { errors: 0, processed: 0, total : 0}
              for binding in data.results.bindings
                value = sparql.bindingToString(binding[voidService.partitionStatInfo[statName].binding])
                if (value!="UNDEF")
                  nlimits = if (statName=='Property') then [{stat:statName,value},limits[0]] else [limits[0],{stat:statName,value}]
                  nlimits2 = nlimits[0].stat+"|"+nlimits[0].value+"|"+nlimits[1].stat+"|"+nlimits[1].value
                  if (!secondaryStats[nlimits2])
                    secondaryStats[nlimits2]=1
                    $scope.total.total += calculateStatistics(nlimits)
                    $scope.subStatStatus[sstatName].total++
            if (!limits)
              $scope.statStatus[statName]='ok'
              $scope.main.processed++
            else if (++track.successfulParts==track.total)
              limitStat = [limit.stat for limit in limits].join('-')
              $scope.subStatStatus[limitStat].processed++
            $scope.total.processed++
          ).error((data,status,headers,config) !->
            if (!limits)
              $scope.statStatus[statName]='error'
              $scope.main.errors++
            else if (!track.errored)
              track.errored = true
              limitStat = [limit.stat for limit in limits].join('-')
              $scope.subStatStatus[limitStat].errors++
            $scope.total.errors++
            handleError(data,status,headers,config)
          )
      ).error((data,status,headers,config) !->
        if (!limits)
          $scope.main.errors++
          $scope.statStatus[statName]='error'
        else if (!track.errored)
          track.errored = true
          limitStat = [limit.stat for limit in limits].join('-')
          $scope.subStatStatus[limitStat].errors++
        $scope.total.errors+=2
        handleError(data,status,headers,config)
      )
    function calculateStatistics(limits)
      banned = {}
      if (limits) then for limit in limits
        banned[limit.stat]=true
        if (voidService.banList[limit.stat]) then for bannedStat in voidService.banList[limit.stat]
          banned[bannedStat]=true
      track = { successfulParts : 0, errored : false, total : 0 }
      statsToCalculate = if !limits then voidService.allStats else voidService.tripleStats
      for statName in statsToCalculate when !banned[statName]
        calculateStatistic(track,statName,limits,3)
        track.total++
      track.total*2
    $scope.startTime = new Date()
    $scope.total = {
      processed : 0, errors : 0, total : 2*$scope.stats.length
    }
    timer = null
    function updateDate
      $scope.curTime = new Date()
      timer = $timeout(updateDate,1000)
    updateDate()
    voidService.insertMetadata($stateParams.sparulEndpoint,$stateParams.updateGraphIRI,"<#{$stateParams.sparqlEndpoint}>",$stateParams.graphIRI,"<#{$stateParams.datasetIRI}>",$scope.startTime.toISOString(),window.user_ip_address).success((data) ->
      calculateStatistics(null)
    ).error(handleError)
    $scope.sparqlEndpoint = $stateParams.sparulEndpoint.replace('update','sparql')
    $scope.graphIRI = $stateParams.updateGraphIRI
    $scope.datasetIRI = $stateParams.datasetIRI
    $scope.doAllSingleSelections = $stateParams.doAllSingleSelections
    $scope.doSchemaSelections = $stateParams.doSchemaSelections
    $scope.$watchCollection('[ total.processed, total.errors ]', ->
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


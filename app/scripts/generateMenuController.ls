angular.module('fi.seco.aether')
  .controller('GenerateMenuCtrl', ($rootScope,$http,$q,$scope,$location,$stateParams,sparql) ->
    $scope.errors=[]
    handleError = (data,status,headers,config) ->
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.data ? config.params.query, error: data })
    sparqlEndpointInputCheckCanceler = null
    $scope.$watch('sparqlEndpointInput', (newVal) ->
      if (newVal!=null)
        if sparqlEndpointInputCheckCanceler? then sparqlEndpointInputCheckCanceler.resolve!
        sparqlEndpointInputCheckCanceler = $q.defer!
        sparql.check(newVal,{timeout: sparqlEndpointInputCheckCanceler.promise}).then((valid) ->
          $scope.sparqlEndpointInputValid = valid
        ,->
          $scope.sparqlEndpointInputValid = false
        )
    )
    sparulEndpointInputCheckCanceler = null
    $scope.$watch('sparulEndpointInput', (newVal) ->
      if (newVal!=null)
        if sparulEndpointInputCheckCanceler? then sparulEndpointInputCheckCanceler.resolve!
        sparulEndpointInputCheckCanceler = $q.defer!
        sparql.checkUpdate(newVal,{timeout: sparulEndpointInputCheckCanceler.promise}).then((valid) ->
          $scope.sparulEndpointInputValid = valid
        ,->
          $scope.sparulEndpointInputValid = false
        )
    )
    $scope.$watch('graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('graphIRI',graphIRI).replace!
        if (!$stateParams.datasetIRI?)
          if (graphIRI?)
            if (graphIRI.charAt(graphIRI.length-1)!='/') then graphIRI += '/'
            $scope.datasetIRI = graphIRI+"void/Dataset@"+new Date().toISOString!
          else
            $scope.datasetIRI = $scope.sparqlEndpoint.replace(/sparql\/?$/,'void')+'/Dataset@'+new Date().toISOString!
    )
    $scope.$watch('datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        if (datasetIRI=='') then datasetIRI = null
        $location.search('datasetIRI',datasetIRI).replace!
    )
    $scope.$watch('updateGraphIRI', (updateGraphIRI,oldUpdateGraphIRI) ->
      if (updateGraphIRI!=oldUpdateGraphIRI)
        if (updateGraphIRI=='') then updateGraphIRI = null
        $location.search('updateGraphIRI',updateGraphIRI).replace!
    )
    $scope.$watch('sparulEndpoint', (sparulEndpoint,oldSparulEndpoint) ->
      if (sparulEndpoint!=oldSparulEndpoint)
        if (sparulEndpoint=='') then sparulEndpoint = null
        $location.search('sparulEndpoint',sparulEndpoint).replace!
        $scope.sparulEndpointInput = sparulEndpoint
    )
    fetchGraphsCanceler = null
    fetchGraphs = ->
      $scope.graphIRIFetching=true
      if (fetchGraphsCanceler?) then fetchGraphsCanceler.resolve!
      $scope.graphs = null
      fetchGraphsCanceler = $q.defer!
      response <-! sparql.query($scope.sparqlEndpoint,'''
        SELECT ?graphIRI (COUNT(*) AS ?triples) {
          {
            GRAPH ?graphIRI { ?s ?p ?o }
          } UNION {
            ?s ?p ?o
          }
        }
	      GROUP BY ?graphIRI
      ''',{timeout: fetchGraphsCanceler.promise}).then(_,handleError)
      $scope.graphIRIFetching=false
      found = false
      for binding in response.data.results.bindings
        if (binding.graphIRI?.value==$scope.graphIRI) then found = true
      if (!found) then delete $scope.graphIRI
      $scope.graphs = response.data.results.bindings
    $scope.$watch 'sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $location.search('sparqlEndpoint',sparqlEndpoint).replace!
        $scope.sparqlEndpointInput = sparqlEndpoint
        $scope.datasetIRI = sparqlEndpoint.replace(/sparql\/?$/,'void')+'/Dataset@'+new Date().toISOString!
        $scope.updateGraphIRI = sparqlEndpoint.replace(/sparql\/?$/,'void/')
        fetchGraphs!
    $scope.$watch 'doAllSingleSelections', (cur,prev) ->
      if (cur!=prev) then $location.search('doAllSingleSelections',cur).replace!
    $scope.$watch 'doSchemaSelections', (cur,prev) ->
      if (cur!=prev) then $location.search('doSchemaSelections',cur).replace!
    for param,value of $stateParams
      if (value=="true") then value = true
      else if (value=="false") then value = false
      $scope[param]=value
    $scope.sparulEndpointInput = $scope.sparulEndpoint
    if ($scope.sparqlEndpoint)
      $scope.sparqlEndpointInput = $scope.sparqlEndpoint
      fetchGraphs!
  )
'use strict'

angular.module('fi.seco.aether')
  .controller('GenerateMenuCtrl', ($q,$scope,$location,$stateParams,sparql) ->
    $scope.errors=[]
    handleError = (data,status,headers,config) ->
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.data ? config.params.query, error: data })
    $scope.$watch('sparqlEndpointInput', (newVal) ->
      if (newVal!=null)
        sparql.query(newVal,"ASK {}").success((data) ->
          $scope.sparqlEndpointInputValid = data.boolean?
        ).error(() ->
          $scope.sparqlEndpointInputValid = false
        )
    )
    $scope.$watch('sparulEndpointInput', (newVal) ->
      if (newVal!=null)
        sparql.update(newVal,"INSERT DATA {}").success((data, status) ->
          $scope.sparulEndpointInputValid = status == 204
        ).error(() ->
          $scope.sparulEndpointInputValid = false
        )
    )
    $scope.$watch('graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('graphIRI',graphIRI).replace() #$state.go($state.current.name,{graphIRI:graphIRI},{location:'replace'})
        if (!$stateParams.datasetIRI?)
          if (graphIRI?)
            if (graphIRI.charAt(graphIRI.length-1)!='/') then graphIRI += '/'
            $scope.datasetIRI = graphIRI+"void/Dataset@"+new Date().toISOString()
          else
            $scope.datasetIRI = $scope.sparqlEndpoint.replace(/sparql\/?$/,'void')+'/Dataset@'+new Date().toISOString()
    )
    $scope.$watch('datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        if (datasetIRI=='') then datasetIRI = null
        $location.search('datasetIRI',datasetIRI).replace() #$state.go($state.current.name,{datasetIRI:datasetIRI},{location:'replace'})
    )
    $scope.$watch('updateGraphIRI', (updateGraphIRI,oldUpdateGraphIRI) ->
      if (updateGraphIRI!=oldUpdateGraphIRI)
        if (updateGraphIRI=='') then updateGraphIRI = null
        $location.search('updateGraphIRI',updateGraphIRI).replace() #$state.go($state.current.name,{updateGraphIRI:updateGraphIRI},{location:'replace'})
    )
    $scope.$watch('sparulEndpoint', (sparulEndpoint,oldSparulEndpoint) ->
      if (sparulEndpoint!=oldSparulEndpoint)
        if (sparulEndpoint=='') then sparulEndpoint = null
        $location.search('sparulEndpoint',sparulEndpoint).replace() #$state.go($state.current.name,{sparulEndpoint:sparulEndpoint},{location:'replace'})
        $scope.sparulEndpointInput = sparulEndpoint
    )
    canceler = null
    fetchGraphs = () ->
      $scope.graphIRIFetching=true
      if (canceler?) then canceler.resolve()
      $scope.graphs = null
      canceler = $q.defer()
      sparql.query($scope.sparqlEndpoint,'''
        SELECT ?graphIRI (COUNT(*) AS ?triples) {
          {
            GRAPH ?graphIRI { ?s ?p ?o }
          } UNION {
            ?s ?p ?o
          }
        }
	      GROUP BY ?graphIRI
      ''',{timeout: canceler.promise}).success((data) ->
        $scope.graphIRIFetching=false
        found = false
        for binding in data.results.bindings
          if (binding.graphIRI?.value==$scope.graphIRI) then found = true
        if (!found) then delete $scope.graphIRI
        $scope.graphs = data.results.bindings
      )
    $scope.$watch('sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $location.search('sparqlEndpoint',sparqlEndpoint).replace() #$state.go($state.current.name,{sparqlEndpoint:sparqlEndpoint},{location:'replace'})
        $scope.sparqlEndpointInput = sparqlEndpoint
        $scope.datasetIRI = sparqlEndpoint.replace(/sparql\/?$/,'void')+'/Dataset@'+new Date().toISOString()
        $scope.updateGraphIRI = sparqlEndpoint.replace(/sparql\/?$/,'void/')
        fetchGraphs()
    )
    $scope.$watch('doSelections', (doSelections,oldDoSelections) ->
      if (doSelections!=oldDoSelections)
        $location.search('doSelections',doSelections).replace() #$state.go($state.current.name,{doSelections:doSelections},{location:'replace'})
    )
    for param,value of $stateParams
      $scope[param]=value
    $scope.sparulEndpointInput = $scope.sparulEndpoint
    if ($scope.sparqlEndpoint)
      $scope.sparqlEndpointInput = $scope.sparqlEndpoint
      fetchGraphs()
  )
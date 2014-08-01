angular.module('fi.seco.httpthrottle').value('maxRequests',8)

angular.module('fi.seco.aether', [ 'ngAnimate', 'ui.router', 'ui.bootstrap', 'nvd3ChartDirectives', 'fi.seco.sparql', 'fi.seco.void', 'fi.seco.prefix', 'fi.seco.httpthrottle' ])
  .config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
    $urlRouterProvider.when('/latest?voidEndpoint&voidGraphIRI&graphIRI&sparqlEndpoint', ['$match', 'sparql', '$state', ($match, sparql, $state) ->
      query = """
        PREFIX prov: <http://www.w3.org/ns/prov#>
        PREFIX void: <http://rdfs.org/ns/void#>
        PREFIX sd: <http://www.w3.org/ns/sparql-service-description#>
        SELECT ?datasetIRI {
          |ENDPOINTINFO|
          |GRAPHIRIINFO|
          ?datasetIRI prov:generatedBy ?a .
          ?a prov:startedAtTime ?time .
        }
        ORDER BY DESC(?time)
        LIMIT 2
      """.replace('|GRAPHIRIINFO|',if ($match.graphIRI) then "?datasetIRI sd:name <#{$match.graphIRI}> ." else "").replace("|ENDPOINTINFO|",if ($match.sparqlEndpoint) then "?datasetIRI void:sparqlEndpoint <#{$match.sparqlEndpoint}> ." else "")
      sparql.query($match.voidEndpoint,query).success((data) ->
        datasetIRI=data.results.bindings[0].datasetIRI.value
        if (data.results.bindings.length>1) then compare_datasetIRI=data.results.bindings[1].datasetIRI.value else compare_datasetIRI=datasetIRI
        $state.go('view',{sparqlEndpoint:$match.voidEndpoint,graphIRI:$match.voidGraphIRI,datasetIRI:datasetIRI,compare_sparqlEndpoint:$match.voidEndpoint,compare_graphIRI:$match.voidGraphIRI,compare_datasetIRI:compare_datasetIRI},{location:'replace'})
      )
    ])
    $stateProvider.state('view', {
      url: '/view?sparqlEndpoint&datasetIRI&graphIRI&compare_sparqlEndpoint&compare_datasetIRI&compare_graphIRI&limitStat&limitObject'
      templateUrl: 'partials/view.html'
      controller:'ViewCtrl'
      reloadOnSearch: false
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Viewer";
      ]
    })
    $stateProvider.state('index', {
      url: '/'
      templateUrl: 'partials/index.html'
      controller:'IndexCtrl'
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Tool";
      ]
    })
    $stateProvider.state('generate', {
      url: '/generate?sparqlEndpoint&graphIRI&sparulEndpoint&updateGraphIRI&datasetIRI&doSelections'
      templateUrl: 'partials/generate.html'
      controller:'GenerateCtrl'
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
      ]
    })
    $stateProvider.state('generate-menu', {
      url: '/generate-menu?sparqlEndpoint&graphIRI&sparulEndpoint&updateGraphIRI&datasetIRI'
      templateUrl: 'partials/generateMenu.html'
      controller:'GenerateMenuCtrl'
      reloadOnSearch: false
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
      ]
    })
  .config ($httpProvider) ->
    $httpProvider.interceptors.push('httpThrottler')
angular.module('fi.seco.httpthrottle').value('maxRequests',8)

angular.module('app', [ 'http-auth-interceptor', 'ngAnimate', 'ui.router', 'ui.bootstrap', 'nvd3ChartDirectives', 'fi.seco.sparql', 'fi.seco.void', 'fi.seco.prefix', 'fi.seco.httpthrottle' ])
  .run ($rootScope,$modal,$http,authService) ->
    $rootScope.$on 'event:auth-loginRequired', ->
      $modal.open({
        templateUrl:'login.html'
      }).result.then (auth) ->
        $rootScope.username = auth.username
        $rootScope.password = auth.password
        $http.defaults.headers.common['Authorization'] = 'Basic '+btoa(auth.username+':'+auth.password)
        authService.loginConfirmed()
  .config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
    $urlRouterProvider.when('/latest?{voidEndpoint:any}&{voidGraphIRI:any}&{graphIRI:any}&{sparqlEndpoint:any}', ['$match', 'sparql', '$state', ($match, sparql, $state) ->
      query = """
        PREFIX prov: <http://www.w3.org/ns/prov#>
        PREFIX void: <http://rdfs.org/ns/void#>
        PREFIX sd: <http://www.w3.org/ns/sparql-service-description#>
        SELECT ?datasetIRI {
          |ENDPOINTINFO|
          |GRAPHIRIINFO|
          ?datasetIRI prov:wasGeneratedBy ?a .
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
      url: '/view?{sparqlEndpoint:any}&{datasetIRI:any}&{graphIRI:any}&{compare_sparqlEndpoint:any}&{compare_datasetIRI:any}&{compare_graphIRI:any}&{subjectLimitStat:any}&{subjectLimitValue:any}&{propertyLimitStat:any}&{propertyLimitValue:any}&{objectLimitStat:any}&{objectLimitValue:any}&{fullView:any}'
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
      url: '/generate?{sparqlEndpoint:any}&{graphIRI:any}&{sparulEndpoint:any}&{updateGraphIRI:any}&{datasetIRI:any}&{doAllSingleSelections:any}&{doSchemaSelections:any}'
      templateUrl: 'partials/generate.html'
      controller:'GenerateCtrl'
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
      ]
    })
    $stateProvider.state('generate-menu', {
      url: '/generate-menu?{sparqlEndpoint:any}&{graphIRI:any}&{sparulEndpoint:any}&{updateGraphIRI:any}&{datasetIRI:any}&{doAllSingleSelections:any}&{doSchemaSelections:any}'
      templateUrl: 'partials/generateMenu.html'
      controller:'GenerateMenuCtrl'
      reloadOnSearch: false
      onEnter: ['$rootScope', ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
      ]
    })
  .config ($httpProvider) ->
    $httpProvider.interceptors.push('httpThrottler')

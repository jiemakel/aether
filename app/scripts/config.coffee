'use strict'

angular.module('fi.seco.httpthrottle').value('maxRequests',4)

angular.module('fi.seco.voidViewer', [ 'ngAnimate', 'ui.router', 'ui.bootstrap', 'nvd3ChartDirectives', 'fi.seco.sparql', 'fi.seco.void', 'fi.seco.prefix', 'fi.seco.httpthrottle' ])
  .config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
    $stateProvider.state('view', {
      url: '/view?sparqlEndpoint&datasetIRI&graphIRI&compare_sparqlEndpoint&compare_datasetIRI&compare_graphIRI'
      templateUrl: 'views/view.html'
      controller:'ViewCtrl'
      reloadOnSearch: false
      onEnter: ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Viewer";
    })
    $stateProvider.state('index', {
      url: '/'
      templateUrl: 'views/index.html'
      controller:'IndexCtrl'
      onEnter: ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Tool";
    })
    $stateProvider.state('generate', {
      url: '/generate?sparqlEndpoint&graphIRI&sparulEndpoint&updateGraphIRI&datasetIRI&doSelections'
      templateUrl: 'views/generate.html'
      controller:'GenerateCtrl'
      onEnter: ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
    })
    $stateProvider.state('generate-menu', {
      url: '/generate-menu?sparqlEndpoint&graphIRI&sparulEndpoint&updateGraphIRI&datasetIRI'
      templateUrl: 'views/generateMenu.html'
      controller:'GenerateMenuCtrl'
      onEnter: ($rootScope) ->
        $rootScope.title = "Aether VoID Statistics Generator";
      reloadOnSearch: false
    })
  .config ($httpProvider) ->
    $httpProvider.interceptors.push('httpThrottler')
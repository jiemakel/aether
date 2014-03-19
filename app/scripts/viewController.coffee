'use strict'

angular.module('fi.seco.aether')
  .controller('ViewCtrl', ($scope,$q,$location,$timeout,voidService,sparql,$window,$anchorScroll,$stateParams,prefixService) ->
    $scope.Math = $window.Math
    $scope.scrollTo = (id) ->
      $location.hash(id)
      $anchorScroll()
    $scope.errors=[]
    clearData = () ->
      $scope.errors = []
      delete $scope.iriLengthInfo1
      delete $scope.iriLengthInfo2
      delete $scope.iriLengthInfo3
      delete $scope.iriLengthInfos
      delete $scope.literalLengthInfo1
      delete $scope.literalLengthInfo2
      delete $scope.literalLengthInfo3
      delete $scope.literalLengthInfos
      delete $scope.allRDFNodes
      delete $scope.subjectRDFNodes
      delete $scope.objectRDFNodes
      $scope.results = {}
      $scope.compare_results = {}
      delete $scope.compare_allRDFNodes
      delete $scope.compare_subjectRDFNodes
      delete $scope.compare_objectRDFNodes
      delete $scope['results_Subject']
      delete $scope.subjectInfo
      delete $scope.subjectInfoTotalTriples
      delete $scope.compare_results_subject
      delete $scope['results_Property']
      delete $scope.propertyInfo
      delete $scope.propertyInfoTotalTriples
      delete $scope.compare_results_property
      delete $scope['results_Resource Object']
      delete $scope.resourceObjectInfo
      delete $scope.resourceObjectInfoTotalTriples
      delete $scope.compare_results_objectResource
      delete $scope['results_Literal Object']
      delete $scope.literalObjectInfo
      delete $scope.literalObjectInfoTotalTriples
      delete $scope.compare_results_objectLiteral
      delete $scope['results_Subject Namespace']
      delete $scope.subjectNamespaceInfo
      delete $scope.subjectNamespaceInfoTotalSubjects
      delete $scope.compare_results_subjectNamespace
      delete $scope['results_Subject Type']
      delete $scope.subjectTypeInfo
      delete $scope.subjectTypeInfoTotalSubjects
      delete $scope.compare_results_subjectType
      delete $scope['results_Property Namespace']
      delete $scope.propertyNamespaceInfo
      delete $scope.propertyNamespaceInfoTotalProperties
      delete $scope.compare_results_propertyNamespace
      delete $scope['results_Property Type']
      delete $scope.propertyTypeInfo
      delete $scope.propertyTypeInfoTotalProperties
      delete $scope.compare_results_propertyType
      delete $scope['results_Object Namespace']
      delete $scope.objectNamespaceInfo
      delete $scope.objectNamespaceInfoTotalObjects
      delete $scope.compare_results_objectNamespace
      delete $scope['results_Object Type']
      delete $scope.objectTypeInfo
      delete $scope.objectTypeInfoTotalObjects
      delete $scope.compare_results_objectType
      delete $scope['results_Object Datatype']
      delete $scope.datatypeInfo
      delete $scope.datatypeInfoTotalLiterals
      delete $scope.compare_results_datatype
      delete $scope['results_Object Language']
      delete $scope.languageInfo
      delete $scope.languageInfoTotalLiterals
      delete $scope.compare_results_language
    shortForm = (uri) ->
      ret = prefixService.shortForm(uri)
      $scope.seenNs = prefixService.getSeenPrefixNsMap();
      ret
    handleError = (data,status,headers,config) ->
      $scope.queries--
      if (status==0) then return
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.query ? config.data, error: data })
    dFormat = d3.format(',d')
    pFormat = d3.format(',.2f')
    $scope.queries = 0
    $scope.xTickFormat = (ivalue) ->
      if (ivalue.charAt(0)=='▲' || ivalue.charAt(0)=='▼') then value=ivalue.substring(1)
      else value=ivalue
      if (value=='<http://www.w3.org/2000/01/rdf-schema#Resource>') then 'no type'
      else if (value.charAt(0)=='"')
        if (value.indexOf('<')!=-1 && value.indexOf('>')!=-1)
          dt = value.substring(value.indexOf('<'),value.indexOf('>')+1)
          sdt = shortForm(dt)
          ivalue.split(dt).join(sdt)
        else ivalue
      else
        if (ivalue!=value) then ivalue.charAt(0)+shortForm(value)
        else shortForm(value)
    $scope.yTickFormat = (value) ->
      dFormat(Math.abs(value))
    $scope.switchCompare = () ->
      ls = $location.search()
      if (ls.compare_datasetIRI)
        tmp=ls.datasetIRI
        ls.datasetIRI=ls.compare_datasetIRI
        ls.compare_datasetIRI=tmp
      if (ls.compare_graphIRI)
        tmp=ls.graphIRI
        ls.graphIRI=ls.compare_graphIRI
        ls.compare_graphIRI=tmp
      if (ls.compare_sparqlEndpoint)
        tmp=ls.sparqlEndpoint
        ls.sparqlEndpoint=ls.compare_sparqlEndpoint
        ls.compare_sparqlEndpoint=tmp
      $location.search(ls)
    rdfNodeTooltipContent = (prefix, key, x, y, graph) ->
      ret = """
        <h3>#{key}</h3>
        <p>#{x}
      """
      if ($scope['compare_'+prefix+'RDFNodes']?[key] && $scope['compare_'+prefix+'RDFNodes']?[key]!=y.value)
        if ($scope['compare_'+prefix+'RDFNodes']?[key]<y.value) then ret+=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(y.value-$scope['compare_'+prefix+'RDFNodes'][key])} (#{pFormat((y.value-$scope['compare_'+prefix+'RDFNodes'][key])*100/y.value)}%)"""
        else ret+=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(y.value-$scope['compare_'+prefix+'RDFNodes'][key])} (#{pFormat(($scope['compare_'+prefix+'RDFNodes'][key]-y.value)*100/y.value)}%)"""
      ret + """
      </p>
      """
    $scope.rdfNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('all',key,x,e,graph)
    $scope.subjectRDFNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('subject',key,x,e,graph)
    $scope.objectRDFNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('object',key,x,e,graph)
    $scope.tooltipContent = (key, x, y, e, graph) ->
      if (x.charAt(0)=='▲' || x.charAt(0)=='▼')
        mkey = e.point[0].substring(1)
        compare = $scope['compare_results_'+graph.container.parentNode.id.replace(/Info[123]?$/,'')]
        if (compare)
          if (x.charAt(0)=='▲')
            if (compare[mkey])
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(e.value-compare[mkey])} (#{pFormat((e.value-compare[mkey])*100/e.value)}%)"""
            else
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""
          else add=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(e.value-compare[mkey])} (#{pFormat((compare[mkey]-e.value)*100/e.value)}%)"""
        else add=''
        x = x.substring(1)
      else add=''
      """
        <h3>#{x.replace(/</g,'&lt;').replace(/>/g,'&gt;')}</h3>
        <p>#{y}#{add}</p>
      """
    $scope.propertyTooltipContent = (key, x, y, e, graph) ->
      if (x.charAt(0)=='▲' || x.charAt(0)=='▼')
        x = x.substring(1)
        mkey = e.point[0].substring(1)
      else
        mkey = e.point[0]
      i = e.pointIndex
      values = {
        triples : -($scope.propertyInfo[4].values[i][1]+$scope.propertyInfo[5].values[i][1]+$scope.propertyInfo[6].values[i][1])
        distinctIRIReferenceObjects : $scope.propertyInfo[0].values[i][1]
        distinctLiteralObjects : $scope.propertyInfo[1].values[i][1]
        distinctBlankNodeObjects : $scope.propertyInfo[2].values[i][1]
        distinctIRIReferenceSubjects : -$scope.propertyInfo[4].values[i][1]
        distinctBlankNodeSubjects : -$scope.propertyInfo[5].values[i][1]
      }
      add = {
        triples : ''
        distinctIRIReferenceObjects : ''
        distinctLiteralObjects : ''
        distinctBlankNodeObjects : ''
        distinctIRIReferenceSubjects : ''
        distinctBlankNodeSubjects : ''
      }
      compare = $scope['compare_results_property']
      if (compare)
        for key in ['triples','distinctIRIReferenceObjects','distinctLiteralObjects','distinctBlankNodeObjects','distinctIRIReferenceSubjects','distinctBlankNodeSubjects']
          if (compare[mkey])
            if (!compare[mkey][key])
              add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""
            else if (compare[mkey][key]<values[key])
              add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(values[key]-compare[mkey][key])} (#{pFormat((values[key]-compare[mkey][key])*100/values[key])}%)"""
            else if (compare[mkey][key]>values[key])
              add[key]=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(values[key]-compare[mkey][key])} (#{pFormat((compare[mkey][key]-values[key])*100/values[key])}%)"""
          else
            add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""

      ret = """
        <h3>#{x.replace(/</g,'&lt;').replace(/>/g,'&gt;')}</h3>
        <p>
        Triples : #{$scope.yTickFormat(values.triples)}#{add.triples}<br />
      """
      if (values.distinctIRIReferenceObjects>0 || compare?[mkey]?.distinctIRIReferenceObjects>0) then ret = ret + """
        Object IRI References: #{$scope.yTickFormat(values.distinctIRIReferenceObjects)}#{add.distinctIRIReferenceObjects}<br />
      """
      if (values.distinctLiteralObjects>0 || compare?[mkey]?.distinctLiteralObjects>0) then ret = ret + """
        Object Literals: #{$scope.yTickFormat(values.distinctLiteralObjects)}#{add.distinctLiteralObjects}<br />
      """
      if (values.distinctBlankNodeObjects>0 || compare?[mkey]?.distinctBlankNodeObjects>0) then ret = ret + """
        Object Blank Nodes: #{$scope.yTickFormat(values.distinctBlankNodeObjects)}#{add.distinctBlankNodeObjects}<br />
      """
      if (values.distinctIRIReferenceSubjects>0 || compare?[mkey]?.distinctIRIReferenceSubjects>0) then ret = ret + """
        Subject IRI References: #{$scope.yTickFormat(values.distinctIRIReferenceSubjects)}#{add.distinctIRIReferenceSubjects}<br />
      """
      if (values.distinctBlankNodeSubjects>0 || compare?[mkey]?.distinctBlankNodeSubjects>0) then ret = ret + """
        Subject Blank Nodes: #{$scope.yTickFormat(values.distinctBlankNodeSubjects)}#{add.distinctBlankNodeSubjects}<br />
      """
      ret + """
      </p>
      """
    clickTimeout = null
    $scope.$on('elementClick.directive', (event, data) ->
      if (data.point[0].charAt(0)=='▲' || data.point[0].charAt(0)=='▼') then value=data.point[0].substring(1) else value=data.point[0]
      if ($timeout.cancel(clickTimeout))
        if ($scope.dataset_sparqlEndpoint)
          if ($scope.dataset_graphIRI)
            GB = "GRAPH <#{$scope.dataset_graphIRI}> {"
            GE = "}"
          else 
            GB = ""
            GE = ""
          switch event.targetScope.id
            when "propertyInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s #{value} ?o #{GE}} LIMIT 100"))
            when "subjectInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} #{value} ?p ?o #{GE}} LIMIT 100"))
            when "resourceObjectInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { #{GB} ?s ?property #{value} #{GE}} GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
            when "literalObjectInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { #{GB} ?s ?property #{value} #{GE}} GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
            when "datatypeInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s ?p ?o FILTER(datatype(?o) = #{value}) #{GE}} LIMIT 100"))
            when "languageInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s ?p ?o FILTER(lang(?o) = #{value}) #{GE}} LIMIT 100"))
            when "subjectTypeInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s a #{value} #{GE}} LIMIT 100"))
            when "objectTypeInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { #{GB} ?s ?p ?o . ?o a #{value} #{GE}} LIMIT 100"))
            when "propertyTypeInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { #{GB} ?s ?p ?o . ?p a #{value} #{GE}} LIMIT 100"))
            when "propertyNamespaceInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?p),'#{value.substring(1,value.length-1)}')) #{GE}} LIMIT 100"))
            when "subjectNamespaceInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?s { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?s),'#{value.substring(1,value.length-1)}')) #{GE}} LIMIT 100"))
            when "objectNamespaceInfo" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?o),'#{value.substring(1,value.length-1)}')) #{GE}} LIMIT 100"))
      else
        clickTimeout = $timeout(() ->
          limitStat = switch event.targetScope.id
            when "propertyInfo" then 'Property'
            when "subjectInfo" then 'Subject'
            when "resourceObjectInfo" then 'Object Resource'
            when "literalObjectInfo" then 'Object Literal'
            when "datatypeInfo" then 'Object Datatype'
            when "languageInfo" then 'Object Language'
            when "subjectTypeInfo" then 'Subject Type'
            when "propertyTypeInfo" then 'Property Type'
            when "objectTypeInfo" then 'Object Type'
            when "subjectNamespaceInfo" then 'Subject Namespace'
            when "propertyNamespaceInfo" then 'Property Namespace'
            when "objectNamespaceInfo" then 'Object Namespace'
          $scope.limit = { limitObject:value, limitStat:limitStat }
          $scope.$apply()
        ,500)
    )
    checkInput = (sparqlEndpointInput) ->
      if ($scope[sparqlEndpointInput])
        $scope.queries++
        sparql.query($scope[sparqlEndpointInput],"ASK {}").success((data) ->
          $scope.queries--
          $scope[sparqlEndpointInput+'Valid'] = data.boolean?
        ).error(() ->
          $scope.queries--
          $scope[sparqlEndpointInput+'Valid'] = false
        )
    $scope.$watch('sparqlEndpointInput', () ->
      checkInput('sparqlEndpointInput')
    )
    $scope.$watch('compare_sparqlEndpointInput', () ->
      checkInput('compare_sparqlEndpointInput')
    )
    cancelers = {}
    fetchGraphs = (prefix) ->
      $scope.errors=[]
      $scope[prefix+'graphIRIFetching']=true
      $scope[prefix+'graphs'] = null
      if (prefix=='' && $scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint)
        $scope.compare_graphs=null
        $scope.compare_graphIRIFetching=true
      if (cancelers[prefix+'graphIRI']?) then cancelers[prefix+'graphIRI'].resolve()
      cancelers[prefix+'graphIRI'] = $q.defer()
      $scope.queries++
      sparql.query($scope[prefix+'sparqlEndpoint'],'''
        SELECT ?graphIRI (COUNT(?s) AS ?datasets) (COUNT(?s2) AS ?triples) {
         {
           ?s2 ?p ?o
         }
         UNION
         {
           GRAPH ?graphIRI { ?s2 ?p ?o }
         }
         UNION
         {
           GRAPH ?graphIRI {
             ?s a <http://rdfs.org/ns/void#Dataset>
           }
          } UNION {
           ?s a <http://rdfs.org/ns/void#Dataset>
          }
        }
        GROUP BY ?graphIRI
      ''',{timeout: cancelers[prefix+'graphIRI'].promise}).success((data) ->
        $scope.queries--
        found = false
        for binding in data.results.bindings
          if (binding.graphIRI?.value==$scope[prefix+'graphIRI']) then found = true
        if (!found) then delete $scope[prefix+'graphIRI']
        $scope[prefix+'graphIRIFetching']=false
        $scope[prefix+'graphs'] = data.results.bindings
        if (prefix=='' && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint)
          if (!found) then delete $scope.compare_graphIRI
          $scope.compare_graphIRIFetching=false
          $scope.compare_graphs = data.results.bindings
        fetchDatasets(prefix)
      ).error(handleError)
    $scope.$watch('sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $scope.sparqlEndpointInput = sparqlEndpoint
        $scope.errors = []
        for key, value of cancelers
          value.resolve()
        $location.search('sparqlEndpoint',sparqlEndpoint)
        if ($scope.compare_sparqlEndpoint==oldSparqlEndpoint || !$scope.compare_sparqlEndpoint? || $scope.compare_sparqlEndpoint=='') then $scope.compare_sparqlEndpoint=sparqlEndpoint
        fetchGraphs('')
    )
    $scope.$watch('compare_sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $scope.compare_sparqlEndpointInput = sparqlEndpoint
        if (sparqlEndpoint==$scope.sparqlEndpoint) then sparqlEndpoint=null
        $location.search('compare_sparqlEndpoint',sparqlEndpoint)
        fetchGraphs('compare_')
    )
    fetchDatasets = (prefix) ->
      $scope.errors=[]
      $scope[prefix+'datasetIRIFetching']=true
      if (prefix=='' && $scope.compare_datasetIRI==$scope.datasetIRI && $scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint) then $scope.compare_datasetIRIFetching=true
      if (cancelers[prefix+'datasetIRI']?) then cancelers[prefix+'datasetIRI'].resolve()
      $scope[prefix+'datasets'] = null
      cancelers[prefix+'datasetIRI'] = $q.defer()
      if ($scope[prefix+'graphIRI'])
        query = """
          SELECT DISTINCT ?datasetIRI ?sparqlEndpoint ?graphIRI {
            GRAPH <#{$scope[prefix+'graphIRI']}> {
              ?datasetIRI a <http://rdfs.org/ns/void#Dataset> .
              OPTIONAL {
                ?datasetIRI <http://www.w3.org/ns/prov#generatedBy> ?activity .
                ?activity <http://www.w3.org/ns/prov#startedAtTime> ?time
              }
              OPTIONAL { ?datasetIRI <http://rdfs.org/ns/void#sparqlEndpoint> ?sparqlEndpoint . }
              OPTIONAL { ?datasetIRI <http://www.w3.org/ns/sparql-service-description#name> ?graphIRI . }
            }
          }
          ORDER BY DESC(?time)"""
      else
        query = '''
          SELECT DISTINCT ?datasetIRI ?sparqlEndpoint ?graphIRI {
            ?datasetIRI a <http://rdfs.org/ns/void#Dataset> .
            OPTIONAL {
              ?datasetIRI <http://www.w3.org/ns/prov#generatedBy> ?activity .
              ?activity <http://www.w3.org/ns/prov#startedAtTime> ?time
            }
            OPTIONAL { ?datasetIRI <http://rdfs.org/ns/void#sparqlEndpoint> ?sparqlEndpoint . }
            OPTIONAL { ?datasetIRI <http://www.w3.org/ns/sparql-service-description#name> ?graphIRI . }
          }
          ORDER BY DESC(?time)'''
      $scope.queries++
      sparql.query($scope[prefix+'sparqlEndpoint'],query,{timeout: cancelers[prefix+'datasetIRI'].promise}).success((data) ->
        $scope.queries--
        found = false
        for binding in data.results.bindings
          if (binding.datasetIRI?.value==$scope[prefix+'datasetIRI']) then found = true
        if (!found) then delete $scope[prefix+'datasetIRI']
        if (!$scope[prefix+'datasetIRI']? && data.results.bindings.length>0)
          $scope[prefix+'datasetIRI']=data.results.bindings[0].datasetIRI?.value
        $scope[prefix+'datasetIRIFetching']=false
        $scope[prefix+'datasets'] = data.results.bindings
        if (prefix=='' && $scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint)
          $scope.compare_datasetIRIFetching = false
          $scope.compare_datasets = data.results.bindings
          found = false
          for binding in data.results.bindings
            if (binding.datasetIRI?.value==$scope.compare_datasetIRI) then found = true
          if (!found) then delete $scope.compare_datasetIRI
          if (!$scope.compare_datasetIRI? && data.results.bindings.length>0)
            $scope.compare_datasetIRI=data.results.bindings[0].datasetIRI?.value
          if ($scope.compare_datasetIRI!=$scope.datasetIRI)
            fetchStatistics('compare_')
        fetchStatistics(prefix)
      ).error(handleError)
    $scope.$watch('graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('graphIRI',graphIRI)
        fetchDatasets('')
        if ($scope.compare_graphIRI==oldGraphIRI || !$scope.compare_graphIRI?) then $scope.compare_graphIRI=graphIRI
    )
    $scope.$watch('compare_graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('compare_graphIRI',graphIRI)
        if ($scope.compare_graphIRI!=$scope.graphIRI || $scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint) then fetchDatasets('compare_')
    )
    updateLimits = () ->
      $scope.queries++
      $scope.limits = []
      voidService.getPossibleLimits($scope.sparqlEndpoint,$scope.graphIRI,'<' + $scope.datasetIRI + '>').success((data) ->
        $scope.queries--
        for binding in data.results.bindings
          los = sparql.bindingToString(binding.limitObject)
          lo = {limitName: shortForm(los), limitStat : binding.limitStat.value, limitObject : los }
          $scope.limits.push(lo)
          if ($stateParams['limitStat']==binding.limitStat.value && $stateParams['limitObject']==los) then $scope.limit=lo
      ).error(handleError)
    $scope.$watch('datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('datasetIRI',datasetIRI)
        if ($scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint == $scope.sparqlEndpoint && !$scope.compare_datasetIRI?) then $scope.compare_datasetIRI=datasetIRI
        clearData()
        updateLimits()
        fetchStatistics('')
        if ($scope.compare_datasetIRI!=$scope.datasetIRI || $scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint || $scope.compare_graphIRI!=$scope.graphIRI)
          fetchStatistics('compare_')
    )
    $scope.$watch('compare_datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('compare_datasetIRI',datasetIRI)
        if ($scope.compare_datasetIRI!=$scope.datasetIRI || $scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint || $scope.compare_graphIRI!=$scope.graphIRI)
          fetchStatistics('compare_')
    )
    processCompareLength = (outKey,bindings) ->
      obj = {}
      for binding in bindings
        if (binding.length?)
          key = binding.length.value
        else
          key = binding.minLength.value + '-' + (binding.maxLength?.value ? '')
        obj[key]=parseInt(binding['entities'].value)
      $scope['compare_results_'+outKey] = obj
    processCompare = (outKey,key,value,bindings) ->
      obj = {}
      for binding in bindings
        obj[sparql.bindingToString(binding[key])]=parseInt(binding[value].value)
      $scope['compare_results_'+outKey] = obj
    processCompareData = {
      'IRI Length' : (bindings) -> processCompareLength('iriLength',bindings)
      'Literal Length' : (bindings) -> processCompareLength('literalLength',bindings)
      'Property Namespace' : (bindings) -> processCompare('propertyNamespace','propertyNamespace','entities',bindings)
      'Property Type' : (bindings) -> processCompare('propertyType','propertyClass','entities',bindings)
      'Subject Namespace' : (bindings) -> processCompare('subjectNamespace','subjectNamespace','entities',bindings)
      'Subject Type' : (bindings) -> processCompare('subjectType','class','entities',bindings)
      'Subject' : (bindings) -> processCompare('subject','s','triples',bindings)
      'Object Namespace' : (bindings) -> processCompare('objectNamespace','objectNamespace','entities',bindings)
      'Object Type' : (bindings) -> processCompare('objectType','objectClass','entities',bindings)
      'Object Datatype' : (bindings) -> processCompare('datatype','datatype','entities',bindings)
      'Object Language' : (bindings) -> processCompare('language','language','entities',bindings)
      'Object Resource' : (bindings) -> processCompare('resourceObject','o','triples',bindings)
      'Object Literal' : (bindings) -> processCompare('literalObject','o','triples',bindings)
      'Property' : (bindings) ->
        obj = {}
        for binding in bindings
          obj2 = {
            triples : parseInt(binding.triples.value)
            distinctIRIReferenceSubjects : if (binding.distinctIRIReferenceSubjects?) then parseInt(binding.distinctIRIReferenceSubjects.value) else 0
            distinctBlankNodeSubjects : if (binding.distinctBlankNodeSubjects?) then parseInt(binding.distinctBlankNodeSubjects.value) else 0
            distinctIRIReferenceObjects : if (binding.distinctIRIReferenceObjects?) then parseInt(binding.distinctIRIReferenceObjects.value) else 0
            distinctBlankNodeObjects : if (binding.distinctBlankNodeObjects?) then parseInt(binding.distinctBlankNodeObjects.value) else 0
            distinctLiteralObjects : if (binding.distinctLiterals?) then parseInt(binding.distinctLiterals.value) else 0
          }
          obj[sparql.bindingToString(binding.p)]=obj2;
        $scope['compare_results_property'] = obj
      }
    handleLength = (stat,outStat,valueType2) ->
      if (!$scope['results_'+stat]) then return
      entities1 = []
      entities2 = []
      entities3 = []
      tentities = 0
      for binding in $scope['results_'+stat]
        count = parseInt(binding.entities.value)
        tentities += count
        if (binding.length?)
          key = binding.length.value
        else
          key = binding.minLength.value + '-' + (binding.maxLength?.value ? '')
        if ($scope['compare_results_'+outStat]?)
          if($scope['compare_results_'+outStat][key])
            count2 = $scope['compare_results_'+outStat][key]
            if (count2<count) then key = '▲' + key
            else if (count2>count) then key = '▼' + key
          else
            key = '▲' + key
        if (binding.length?)
          v1 = v2 = 0
        else 
          v1 = parseInt(binding.minLength.value)
          v2 = if (binding.maxLength?) then parseInt(binding.maxLength.value) else 2000
        if (v2-v1<9) then entities1.push([key, count])
        else if (v2-v1<99) then entities2.push([key,count])
        else entities3.push([key,count])
      $scope[outStat+'InfoTotal'+valueType2]=tentities
      infos = 0
      if (entities1.length!=0)
        infos++
        $scope[outStat+'Info1'] = [ { "key" : valueType2 , values : entities1 } ]
      else 
        delete $scope[outStat+'Info1']
      if (entities2.length!=0)
        infos++
        $scope[outStat+'Info2'] = [ { "key" : valueType2 , values : entities2 } ]
      else 
        delete $scope[outStat+'Info2']
      if (entities3.length!=0)
        infos++
        $scope[outStat+'Info3'] = [ { "key" : valueType2 , values : entities3 } ]
      else 
        delete $scope[outStat+'Info3']
      $scope[outStat+'Infos']=infos
    handle = (stat,outStat,keyType,valueType1, valueType2) ->
      if (!$scope['results_'+stat]) then return
      entities = []
      tentities = 0
      for binding in $scope['results_'+stat]
        count = parseInt(binding[valueType1].value)
        tentities += count
        key = sparql.bindingToString(binding[keyType])
        if ($scope['compare_results_'+outStat]?)
          if($scope['compare_results_'+outStat][key])
            count2 = $scope['compare_results_'+outStat][key]
            if (count2<count) then key = '▲' + key
            else if (count2>count) then key = '▼' + key
          else
            key = '▲' + key
        entities.push([key, count])
      $scope[outStat+'InfoTotal'+valueType2]=tentities
      $scope[outStat+'Info'] = [ { "key" : valueType2 , values : entities } ]
    updateData = {
      'IRI Length' : () -> handleLength('IRI Length','iriLength','IRIs')
      'Literal Length' : () -> handleLength('Literal Length','literalLength','Literals')
      'Property Namespace' : () -> handle('Property Namespace','propertyNamespace','propertyNamespace','entities','Properties')
      'Property Type' : () -> handle('Property Type','propertyType','propertyClass','entities','Properties')
      'Subject Namespace' : () -> handle('Subject Namespace','subjectNamespace','subjectNamespace','entities','Subjects')
      'Subject Type' : () -> handle('Subject Type','subjectType','class','entities','Subjects')
      'Subject' : () -> handle('Subject','subject','s','triples','Triples')
      'Object Namespace' : () -> handle('Object Namespace','objectNamespace','objectNamespace','entities','Objects')
      'Object Type' : () -> handle('Object Type','objectType','objectClass','entities','Objects')
      'Object Datatype' : () -> handle('Object Datatype','datatype','datatype','entities','Literals')
      'Object Language' : () -> handle('Object Language','language','language','entities','Literals')
      'Object Resource' : () -> handle('Object Resource','resourceObject','o','triples','Triples')
      'Object Literal' : () -> handle('Object Literal','literalObject','o','triples','Triples')
      'Property' : () ->
        if (!$scope['results_Property']) then return
        distinctIRIReferenceSubjects = []
        distinctBlankNodeSubjects = []
        distinctIRIReferenceObjects = []
        distinctBlankNodeObjects = []
        distinctLiterals = []
        triples = []
        triples2 = []
        ttriples = 0
        for binding in $scope['results_Property']
          property = sparql.bindingToString(binding.p)
          if (binding.triples?)
            ttriples=ttriples + parseInt(binding.triples.value)
            nrtriples1 = parseInt(binding.triples.value)
            nrtriples2 = nrtriples1
          else
            nrtriples1 = 0
            nrtriples2 = 0
          if ($scope['compare_results_property'])
            if ($scope['compare_results_property']?[property])
              count2 = $scope['compare_results_property'][property].triples
              if (count2<nrtriples1) then property = '▲' + property
              else if (count2>nrtriples1) then property = '▼' + property
            else
              property = '▲' + property
          if (binding.distinctIRIReferenceSubjects?) then distinctIRIReferenceSubjects.push([property, -parseInt(binding.distinctIRIReferenceSubjects.value)])
          else distinctIRIReferenceSubjects.push([property,0])
          if (binding.distinctBlankNodeSubjects?) then distinctBlankNodeSubjects.push([property, -parseInt(binding.distinctBlankNodeSubjects.value)])
          else distinctBlankNodeSubjects.push([property,0])
          if (binding.distinctIRIReferenceSubjects) then nrtriples1 = nrtriples1 - parseInt(binding.distinctIRIReferenceSubjects.value)
          if (binding.distinctBlankNodeSubjects) then nrtriples1 = nrtriples1 - parseInt(binding.distinctBlankNodeSubjects.value)
          if (binding.distinctIRIReferenceObjects) then nrtriples2 = nrtriples2 - parseInt(binding.distinctIRIReferenceObjects.value)
          if (binding.distinctBlankNodeObjects) then nrtriples2 = nrtriples2 - parseInt(binding.distinctBlankNodeObjects.value)
          if (binding.distinctLiterals) then nrtriples2 = nrtriples2 - parseInt(binding.distinctLiterals.value)
          triples.push([property, -nrtriples1])
          triples2.push([property, nrtriples2])
          if (binding.distinctIRIReferenceObjects?) then distinctIRIReferenceObjects.push([property, parseInt(binding.distinctIRIReferenceObjects.value)])
          else distinctIRIReferenceObjects.push([property,0])
          if (binding.distinctBlankNodeObjects?) then distinctBlankNodeObjects.push([property, parseInt(binding.distinctBlankNodeObjects.value)])
          else distinctBlankNodeObjects.push([property,0])
          if (binding.distinctLiterals?) then distinctLiterals.push([property, parseInt(binding.distinctLiterals.value)])
          else distinctLiterals.push([property,0])
        $scope.propertyInfoTotalTriples = ttriples
        $scope.propertyInfo = [
          { "key" : "IRI Reference Objects", values : distinctIRIReferenceObjects }
          { "key" : "Literal Objects", values : distinctLiterals }
          { "key" : "Blank Node Objects", values : distinctBlankNodeObjects }
          { "key" : "Triples", values : triples2 }
          { "key" : "IRI Reference Subjects", values : distinctIRIReferenceSubjects }
          { "key" : "Blank Node Subjects", values : distinctBlankNodeSubjects }
          { "key" : "Triples", values : triples }
        ]
    }
    calculateGeneralStatistics = (prefix,endpoint,graphIRI) ->
      for query in voidService.generalStatQueries
        if cancelers[prefix+query]? then cancelers[prefix+query].resolve()
        cancelers[prefix+query] = $q.defer()
        $scope.queries++
        voidService.calculateStatistic(endpoint,graphIRI,query,limit?.limitStat,limit?.limitObject,{timeout: cancelers[prefix+query].promise}).success((data) ->
          $scope.queries--
          processGeneralStatistics(prefix,data)).error(handleError)
    processGeneralStatistics = (prefix,data) ->
      for stat, value of data.results.bindings[0]
        if (stat!='sparqlEndpoint' && stat!='graphIRI')
          $scope[prefix+'results'][stat]=parseInt(value.value)
        else
          $scope[prefix+'results'][stat]=value.value
      if (prefix=='compare_')
        if ($scope[prefix+'results']['distinctIRIReferences']? && $scope[prefix+'results']['distinctBlankNodes']? && $scope[prefix+'results']['distinctLiterals']?)
          $scope.compare_allRDFNodes = {
            'IRI References': $scope[prefix+'results']['distinctIRIReferences']
            'Blank Nodes':$scope[prefix+'results']['distinctBlankNodes']
            'Literals':$scope[prefix+'results']['distinctLiterals']
          }
        if ($scope[prefix+'results']['distinctIRIReferenceSubjects']? && $scope[prefix+'results']['distinctBlankNodeSubjects']?)
          $scope.compare_subjectRDFNodes = {
            'IRI References': $scope[prefix+'results']['distinctIRIReferenceSubjects']
            'Blank Nodes':$scope[prefix+'results']['distinctBlankNodeSubjects']
          }
        if ($scope[prefix+'results']['distinctIRIReferenceObjects']? && $scope[prefix+'results']['distinctBlankNodeObjects']? && $scope[prefix+'results']['distinctLiterals']?)
          $scope.compare_objectRDFNodes = {
            'IRI References': $scope[prefix+'results']['distinctIRIReferenceObjects']
            'Blank Nodes':$scope[prefix+'results']['distinctBlankNodeObjects']
            'Literals':$scope[prefix+'results']['distinctLiterals']
          }
      else 
        if ($scope[prefix+'results']['distinctIRIReferences']? && $scope[prefix+'results']['distinctBlankNodes']? && $scope[prefix+'results']['distinctLiterals']?)
          $scope.allRDFNodes = [['IRI References',$scope[prefix+'results']['distinctIRIReferences']],['Blank Nodes',$scope[prefix+'results']['distinctBlankNodes']],['Literals',$scope[prefix+'results']['distinctLiterals']]]
        if ($scope[prefix+'results']['distinctIRIReferenceSubjects']? && $scope[prefix+'results']['distinctBlankNodeSubjects']?)
          $scope.subjectRDFNodes = [['IRI References',$scope[prefix+'results']['distinctIRIReferenceSubjects']],['Blank Nodes',$scope[prefix+'results']['distinctBlankNodeSubjects']]]
        if ($scope[prefix+'results']['distinctIRIReferenceObjects']? && $scope[prefix+'results']['distinctBlankNodeObjects']? && $scope[prefix+'results']['distinctLiterals']?)
          $scope.objectRDFNodes = [['IRI References',$scope[prefix+'results']['distinctIRIReferenceObjects']],['Blank Nodes',$scope[prefix+'results']['distinctBlankNodeObjects']],['Literals',$scope[prefix+'results']['distinctLiterals']]]
    processStatistics = (prefix,stat,data) ->
      if (prefix=='compare_')
        processCompareData[stat](data.results.bindings)
      else
        $scope[prefix+'results_'+stat]=data.results.bindings
      updateData[stat]()
    fetchStatistics = (prefix) ->
      if (!$scope[prefix+'datasets']) then return
      $scope.errors=[]
      $scope[prefix+'results'] = {}
      if (prefix=='compare_')
        $scope.compare_allRDFNodes = null
        $scope.compare_subjectRDFNodes = null
        $scope.compare_objectRDFNodes = null
      else
        $scope.allRDFNodes = null
        $scope.subjectRDFNodes = null
        $scope.objectRDFNodes = null
      $scope.dataset_sparqlEndpoint = null
      $scope.dataset_graphIRI = null
      if (prefix=='' && $scope['datasetIRI'])
        for binding in $scope['datasets']
          if $scope['datasetIRI']==binding.datasetIRI.value 
            $scope.dataset_sparqlEndpoint=binding.sparqlEndpoint?.value
            $scope.dataset_graphIRI=binding.graphIRI?.value
      if ($scope[prefix+'datasetIRI'])
        if cancelers[prefix+'General']? then cancelers[prefix+'General'].resolve()
        cancelers[prefix+'General'] = $q.defer()
        $scope.queries++
        voidService.getStatistic($scope[prefix+'sparqlEndpoint'],$scope[prefix+'graphIRI'],$scope[prefix+'datasetIRI'],'General',$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+'General'].promise}).success((data) ->
          $scope.queries--
          if (data.results.bindings.length>0 || !$scope.dataset_sparqlEndpoint)
            processGeneralStatistics(prefix,data)
          else calculateGeneralStatistics(prefix,$scope.dataset_sparqlEndpoint,$scope.dataset_graphIRI)
        ).error(handleError)
      else calculateGeneralStatistics(prefix,$scope[prefix+'sparqlEndpoint'],$scope[prefix+'graphIRI'])
      for stat of updateData
        if cancelers[prefix+stat]? then cancelers[prefix+stat].resolve()
        cancelers[prefix+stat] = $q.defer()
        $scope.queries++
        do (stat) ->
          if ($scope[prefix+'datasetIRI'])
            voidService.getStatistic($scope[prefix+'sparqlEndpoint'],$scope[prefix+'graphIRI'],$scope[prefix+'datasetIRI'],stat,$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+stat].promise}).success((data) ->
              $scope.queries--
              if (data.results.bindings.length>0 || !$scope.dataset_sparqlEndpoint)
                processStatistics(prefix,stat,data)
              else
                $scope.queries++
                voidService.calculateStatistic($scope.dataset_sparqlEndpoint,$scope.dataset_graphIRI,stat,$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+stat].promise}).success((data) ->
                  $scope.queries--
                  processStatistics(prefix,stat,data)).error(handleError)
            ).error(handleError)
          else
            voidService.calculateStatistic($scope[prefix+'sparqlEndpoint'],$scope[prefix+'graphIRI'],stat,$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+stat].promise}).success((data) ->
              $scope.queries--
              processStatistics(prefix,stat,data)).error(handleError)
    $scope.$watch('limit', (limit,oldLimit) ->
      if (limit==oldLimit) then return
      if (limit == "")
        delete $scope.limit
        return
      if (!limit?) 
        $location.search('limitStat', null)
        $location.search('limitObject', null)
      else
        $location.search('limitStat', limit.limitStat)
        $location.search('limitObject', limit.limitObject)
      fetchStatistics('')
      if ($scope.compare_datasetIRI!=$scope.datasetIRI || $scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint || $scope.compare_graphIRI!=$scope.graphIRI)
        fetchStatistics('compare_')
    )
    for param,value of $stateParams
      $scope[param]=value
    if (!$scope.compare_graphIRI) then $scope.compare_graphIRI = $scope.graphIRI
    if (!$scope.compare_datasetIRI) then $scope.compare_datasetIRI = $scope.datasetIRI
    if ($scope.sparqlEndpoint)
      if (!$scope.compare_sparqlEndpoint) then $scope.compare_sparqlEndpoint = $scope.sparqlEndpoint
      $scope.sparqlEndpointInput = $scope.sparqlEndpoint
      fetchGraphs('')
    if ($scope.compare_sparqlEndpoint) 
      $scope.compare_sparqlEndpointInput = $scope.compare_sparqlEndpoint
      if ($scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint)
        fetchGraphs('compare_')
      else if ($scope.compare_graphIRI!=$scope.graphIRI)
        fetchDatasets('compare_')
    if ($scope.datasetIRI) then updateLimits()
    $scope.$on('$locationChangeSuccess', () ->
      for param,value of $location.search()
        $scope[param]=value
      if ($location.search().limitStat && $location.search().limitObject)
        limitStat = $location.search().limitStat
        limitObject = $location.search().limitObject
        for limit in $scope.limits
          if (limitStat==limit.limitStat && limitObject==limit.limitObject) then $scope.limit=limit
      else delete $scope.limit
    )
    if ($location.hash())
      unregister = $scope.$watch('queries', (queries) ->
        if (queries==0)
          $anchorScroll()
          unregister()
      )
      
  )


  	
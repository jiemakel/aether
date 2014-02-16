'use strict'

angular.module('fi.seco.voidViewer')
  .controller('ViewCtrl', ($scope,$q,$location,$timeout,voidService,sparql,$window,$anchorScroll,$stateParams,prefixService) ->
    $scope.scrollTo = (id) ->
      $location.hash(id)
      $anchorScroll()
    $scope.errors=[]
    shortForm = (uri) ->
      ret = prefixService.shortForm(uri)
      $scope.seenNs = prefixService.getSeenPrefixNsMap();
      ret
    handleError = (data,status,headers,config) ->
      $scope.queries--
      if (status==0) then return
      $scope.errors.push({ errorSource : config.url, errorStatus : status, query : config.query ? config.data, error: data })
    dFormat = d3.format(',d')
    pFormat = d3.format(',2f')
    $scope.queries = 0
    $scope.xTickFormat = (ivalue) ->
      if (ivalue.charAt(0)=='▲' || ivalue.charAt(0)=='▼') then value=ivalue.substring(1)
      else value=ivalue
      if (value=='<http://www.w3.org/2000/01/rdf-schema#Resource>') then 'no type'
      else if (value.charAt(0)=='"')
        if (value.indexOf('&lt;')!=-1 && value.indexOf('&gt;')!=-1)
          dt = value.substring(value.indexOf('&lt;')+4,value.indexOf('&gt;'))
          sdt = shortForm(dt)
          ivalue.split(dt).join(sdt).replace(/&lt;/,'<').replace(/&gt;/,'>')
        else ivalue
      else
        if (ivalue!=value) then ivalue.charAt(0)+shortForm(value)
        else shortForm(value)
    $scope.yTickFormat = (value) ->
      dFormat(Math.abs(value))
    $scope.rdfNodeTooltipContent = (key, x, y, e, graph) ->
      ret = """
        <h3>#{key}</h3>
        <p>#{x}
      """
      if ($scope.compareRDFNodes?[key] && $scope.compareRDFNodes?[key]!=y.value)
        if ($scope.compareRDFNodes?[key]<y.value) then ret+=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(#{dFormat($scope.compareRDFNodes[key])})"""
        else ret+=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>(#{dFormat($scope.compareRDFNodes[key])})"""
      ret + """
      </p>
      """
    $scope.tooltipContent = (key, x, y, e, graph) ->
      if (x.charAt(0)=='▲' || x.charAt(0)=='▼')
        mkey = e.point[0].substring(1)
        compare = $scope['compare_results_'+e.e.relatedTarget.id.replace('Info','')]
        if (compare)
          if (x.charAt(0)=='▲')
            if (compare[mkey])
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(#{dFormat(compare[mkey])})"""
            else
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""
          else add=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>(#{dFormat(compare[mkey])})"""
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
              add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(#{dFormat(compare[mkey][key])})"""
            else if (compare[mkey][key]>values[key])
              add[key]=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>(#{dFormat(compare[mkey][key])})"""
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
      if ($timeout.cancel(clickTimeout))
        sparqlEndpoint = $scope.results?.sparqlEndpoint ? $scope.sparqlEndpoint
        switch event.targetScope.id
          when "propertyInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { ?s #{data.point[0]} ?o } LIMIT 100"))
          when "subjectInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{data.point[0]} ?p ?o } LIMIT 100"))
          when "resourceObjectInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { ?s ?property #{data.point[0]} } GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
          when "literalObjectInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { ?s ?property #{data.point[0]} } GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
          when "datatypeInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { ?s ?p ?o FILTER(datatype(?o) = #{data.point[0]}) } LIMIT 100"))
          when "languageInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { ?s ?p ?o FILTER(lang(?o) = #{data.point[0]}) } LIMIT 100"))
          when "subjectTypeInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { ?s a #{data.point[0]} } LIMIT 100"))
          when "objectTypeInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { ?s ?p ?o . ?o a #{data.point[0]} } LIMIT 100"))
          when "propertyTypeInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { ?s ?p ?o . ?p a #{data.point[0]} } LIMIT 100"))
          when "propertyNamespaceInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { ?s ?p ?o . FILTER (STRSTARTS(STR(?p),'#{data.point[0].substring(1,data.point[0].length-1)}')) } LIMIT 100"))
          when "subjectNamespaceInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?s { ?s ?p ?o . FILTER (STRSTARTS(STR(?s),'#{data.point[0].substring(1,data.point[0].length-1)}')) } LIMIT 100"))
          when "objectNamespaceInfo" then $window.open("#{sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { ?s ?p ?o . FILTER (STRSTARTS(STR(?o),'#{data.point[0].substring(1,data.point[0].length-1)}')) } LIMIT 100"))
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
          $scope.limit = { limitObject:data.point[0], limitStat:limitStat }
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
        if (sparqlEndpoint==$scope.sparqlEndpoint) then sparqlEndpoint=null
        $location.search('compare_sparqlEndpoint',sparqlEndpoint)
        fetchGraphs('compare_')
    )
    fetchDatasets = (prefix) ->
      $scope[prefix+'datasetIRIFetching']=true
      if (prefix=='' && $scope.compare_datasetIRI==$scope.datasetIRI && $scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint) then $scope.compare_datasetIRIFetching=true
      if (cancelers[prefix+'datasetIRI']?) then cancelers[prefix+'datasetIRI'].resolve()
      $scope[prefix+'datasets'] = null
      cancelers[prefix+'datasetIRI'] = $q.defer()
      if ($scope[prefix+'graphIRI'])
        query = """
          SELECT DISTINCT ?datasetIRI ?sparqlEndpoint {
            GRAPH <#{$scope[prefix+'graphIRI']}> {
              ?datasetIRI a <http://rdfs.org/ns/void#Dataset> .
              OPTIONAL {
                ?datasetIRI <http://www.w3.org/ns/prov#generatedBy> ?activity .
                ?activity <http://www.w3.org/ns/prov#startedAtTime> ?time
              }
              OPTIONAL {
                ?datasetIRI <http://rdfs.org/ns/void#sparqlEndpoint> ?sparqlEndpoint .
              }
            }
          }
          ORDER BY DESC(?time)"""
      else
        query = '''
          SELECT DISTINCT ?datasetIRI ?sparqlEndpoint {
            ?datasetIRI a <http://rdfs.org/ns/void#Dataset> .
            OPTIONAL {
              ?datasetIRI <http://www.w3.org/ns/prov#generatedBy> ?activity .
              ?activity <http://www.w3.org/ns/prov#startedAtTime> ?time
            }
            OPTIONAL {
              ?datasetIRI <http://rdfs.org/ns/void#sparqlEndpoint> ?sparqlEndpoint .
            }
          }
          ORDER BY DESC(?time)'''
      $scope.queries++
      sparql.query($scope[prefix+'sparqlEndpoint'],query,{timeout: cancelers[prefix+'datasetIRI'].promise}).success((data) ->
        $scope.queries--
        found = false
        for binding in data.results.bindings
          if (binding.datasetIRI?.value==$scope[prefix+'datasetIRI']) then found = true
        if (!found) then delete $scope[prefix+'datasetIRI']
        $scope[prefix+'datasetIRIFetching']=false
        $scope[prefix+'datasets'] = data.results.bindings
        if (prefix=='' && $scope.compare_graphIRI==$scope.graphIRI && $scope.compare_sparqlEndpoint==$scope.sparqlEndpoint)
          $scope.compare_datasetIRIFetching = false
          $scope.compare_datasets = data.results.bindings
          if (!found) then delete $scope.compare_datasetIRI
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
      voidService.getPossibleLimits($scope.sparqlEndpoint,$scope.graphIRI,'<' + $scope.datasetIRI + '>').success((data) ->
        $scope.queries--
        $scope.limits = []
        for binding in data.results.bindings
          los = sparql.bindingToString(binding.limitObject)
          $scope.limits.push({limitName: shortForm(los), limitStat : binding.limitStat.value, limitObject : los })
      ).error(handleError)
    $scope.$watch('datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('datasetIRI',datasetIRI)
        if ($scope.compare_datasetIRI==oldDatasetIRI || !$scope.compare_datasetIRI?) then $scope.compare_datasetIRI=datasetIRI
        updateLimits()
        fetchStatistics('')
    )
    $scope.$watch('compare_datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('compare_datasetIRI',datasetIRI)
        if ($scope.compare_datasetIRI!=$scope.datasetIRI || $scope.compare_sparqlEndpoint!=$scope.sparqlEndpoint || $scope.compare_graphIRI!=$scope.graphIRI)
          fetchStatistics('compare_')
    )
    processCompare = (outKey,key,value,bindings) ->
      obj = {}
      for binding in bindings
        obj[sparql.bindingToString(binding[key])]=parseInt(binding[value].value)
      $scope['compare_results_'+outKey] = obj
    processCompareData = {
      'Property Namespace' : (bindings) -> processCompare('propertyNamespace','propertyNamespace','entities',bindings)
      'Property Type' : (bindings) -> processCompare('propertyType','propertyClass','entities',bindings)
      'Subject Namespace' : (bindings) -> processCompare('subjectNamespace','subjectNamespace','entities',bindings)
      'Subject Type' : (bindings) -> processCompare('subjectType','class','entities',bindings)
      'Subject' : (bindings) -> processCompare('subject','s','triples',bindings)
      'Object Namespace' : (bindings) -> processCompare('objectNamespace','objectNamespace','entities',bindings)
      'Object Type' : (bindings) -> processCompare('objectType','objectClass','entities',bindings)
      'Object Datatype' : (bindings) -> processCompare('datatype','datatype','entities',bindings)
      'Object Language' : (bindings) -> processCompare('language','language','entities',bindings)
      'Object Resource' : (bindings) -> processCompare('objectResource','o','triples',bindings)
      'Object Literal' : (bindings) -> processCompare('objectLiteral','o','triples',bindings)
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
            key = '▲' + sparql.bindingToString(binding[keyType])
        else
          key = sparql.bindingToString(binding[keyType])
        entities.push([key, count])
      $scope[outStat+'InfoTotal'+valueType2]=tentities
      $scope[outStat+'Info'] = [ { "key" : valueType2 , values : entities } ]
    updateData = {
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
        if (stat!='sparqlEndpoint')
          $scope[prefix+'results'][stat]=parseInt(value.value)
        else
          $scope[prefix+'results'][stat]=value.value
      if (prefix=='compare_')
        if ($scope[prefix+'results']['distinctIRIReferences']? && $scope[prefix+'results']['distinctBlankNodes']? && $scope[prefix+'results']['distinctLiterals']?)
          $scope.compareRDFNodes = {
            'IRI References': $scope[prefix+'results']['distinctIRIReferences']
            'Blank Nodes':$scope[prefix+'results']['distinctBlankNodes']
            'Literals':$scope[prefix+'results']['distinctLiterals']
          }
      else if ($scope[prefix+'results']['distinctIRIReferences']? && $scope[prefix+'results']['distinctBlankNodes']? && $scope[prefix+'results']['distinctLiterals']?)
        $scope.rdfNodes = [['IRI References',$scope[prefix+'results']['distinctIRIReferences']],['Blank Nodes',$scope[prefix+'results']['distinctBlankNodes']],['Literals',$scope[prefix+'results']['distinctLiterals']]]
    processStatistics = (prefix,stat,data) ->
      if (prefix=='compare_')
        processCompareData[stat](data.results.bindings)
      else
        $scope[prefix+'results_'+stat]=data.results.bindings
      updateData[stat]()
    fetchStatistics = (prefix) ->
      $scope[prefix+'results'] = {}
      if (prefix=='compare_')
        $scope.compareRDFNodes = null
      else
        $scope.rdfNodes = null
      sparqlEndpoint = null
      if ($scope[prefix+'datasetIRI'])
        for binding in $scope[prefix+'datasets']
          if $scope[prefix+'datasetIRI']==binding.datasetIRI.value then sparqlEndpoint=binding.sparqlEndpoint?.value
      if ($scope[prefix+'datasetIRI'])
        if cancelers[prefix+'General']? then cancelers[prefix+'General'].resolve()
        cancelers[prefix+'General'] = $q.defer()
        $scope.queries++
        voidService.getStatistic($scope[prefix+'sparqlEndpoint'],$scope[prefix+'graphIRI'],$scope[prefix+'datasetIRI'],'General',$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+'General'].promise}).success((data) ->
          $scope.queries--
          if (data.results.bindings.length>0 || !sparqlEndpoint)
            processGeneralStatistics(prefix,data)
          else calculateGeneralStatistics(prefix,sparqlEndpoint,$scope[prefix+'graphIRI'])
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
              if (data.results.bindings.length>0 || !sparqlEndpoint)
                processStatistics(prefix,stat,data)
              else
                $scope.queries++
                voidService.calculateStatistic(sparqlEndpoint,$scope[prefix+'graphIRI'],stat,$scope.limit?.limitStat,$scope.limit?.limitObject,{timeout: cancelers[prefix+stat].promise}).success((data) ->
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
        $scope.limit = null
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
    if ($scope.compare_sparqlEndpoint) then $scope.compare_sparqlEndpointInput = $scope.compare_sparqlEndpoint
    if ($scope.datasetIRI) then updateLimits()
    $scope.$on('$locationChangeSuccess', () ->
      for param,value of $location.search()
        $scope[param]=value
      if ($location.search().limitStat && $location.search().limitObject)
        limitStat = $location.search().limitStat
        limitObject = $location.search().limitObject
        for limit in $scope.limits
          if (limitStat==limit.limitStat && limitObject==limit.limitObject) then $scope.limit=limit
      else $scope.limit = null
    )
  )


  	
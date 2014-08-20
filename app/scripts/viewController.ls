angular.module('fi.seco.aether')
  .controller('ViewCtrl', ($scope,$q,$location,$timeout,voidService,sparql,$window,$anchorScroll,$stateParams,prefixService) ->
    $scope.Math = $window.Math
    $scope.scrollTo = (id) ->
      $location.hash(id)
      $anchorScroll!
    $scope.errors=[]
    !function clearData
      $scope.main.stats = { general: {}, triple:{} }
      $scope.compare.stats = { general: {}, triple:{} }
      $scope.errors = []
    cancelers = { main: {}, compare: {} }
    function shortForm(uri)
      ret = prefixService.shortForm(uri)
      $scope.seenNs = prefixService.getSeenPrefixNsMap!;
      ret
    !function handleError(data,status,headers,config)
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
    $scope.switchCompare = ->
      ls = $location.search!
      if (ls.compare.datasetIRI)
        tmp=ls.datasetIRI
        ls.datasetIRI=ls.compare.datasetIRI
        ls.compare.datasetIRI=tmp
      if (ls.compare.graphIRI)
        tmp=ls.graphIRI
        ls.graphIRI=ls.compare.graphIRI
        ls.compare.graphIRI=tmp
      if (ls.compare.sparqlEndpoint)
        tmp=ls.sparqlEndpoint
        ls.sparqlEndpoint=ls.compare.sparqlEndpoint
        ls.compare.sparqlEndpoint=tmp
      $location.search(ls)
    graphs = []
    !function highlight(limitId)
      if($scope.limits[limitId]?)
        angular.element('#'+$scope.limits[limitId].stat.replace(' ','_')).find('g').filter(->this.className.baseVal.indexOf("nv-group nv-series")!=-1).each((i,e) !->
          angular.element(angular.element(e).find('rect')[$scope.limits[limitId].index]).attr("class",(i,val) -> (val ? "")+' selected')
        )
        value = shortForm($scope.limits[limitId].value)
        angular.element('#'+$scope.limits[limitId].stat.replace(' ','_')).find('text').filter(->this.textContent==value).attr("class",(i,val) -> (val ? "")+' selected')
    !function updateHighlights
      angular.element('svg rect').attr("class",(i,val) -> val?.replace("selected",""))
      angular.element('svg text').attr("class",(i,val) -> val?.replace("selected",""))
      highlight("subject")
      highlight("property")
      highlight("object")
    nv.dispatch.on('render_end', updateHighlights)
    var highlightTimeout
    $scope.$on('beforeUpdate.directive', !->
      if (highlightTimeout) then $timeout.cancel(highlightTimeout)
      highlightTimeout := $timeout(updateHighlights,200)
    )
    $scope.registerGraph = (graph) ->
      graphs.push(graph)
    $scope.updateGraphs = ->
      $timeout(!-> 
        for graph in graphs then graph.update!
        if (highlightTimeout) then $timeout.cancel(highlightTimeout)
        highlightTimeout := $timeout(updateHighlights,200)
      ,10)
    function rdfNodeTooltipContent(prefix, key, x, y, graph)
      ret = """
        <h3>#{key}</h3>
        <p>#{x}
      """
      if ($scope.compare.stats.general[prefix+'RDFNodes']?[key] && $scope.compare.stats.general[prefix+'RDFNodes']?[key]!=y.value)
        if ($scope.compare.stats.general[prefix+'RDFNodes']?[key]<y.value) then ret+=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(y.value - $scope.compare.stats.general[prefix+'RDFNodes'][key])} (#{pFormat((y.value - $scope.compare.stats.general[prefix+'RDFNodes'][key]) * 100 / y.value)}%)"""
        else ret+=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(y.value - $scope.compare.stats.general[prefix+'RDFNodes'][key])} (#{pFormat(($scope.compare.stats.general[prefix+'RDFNodes'][key] - y.value) * 100 / y.value)}%)"""
      ret + """
      </p>
      """
    $scope.rdfNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('all',key,x,e,graph)
    $scope.subjectRDFNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('subject',key,x,e,graph)
    $scope.objectRDFNodeTooltipContent = (key, x, e, graph) -> rdfNodeTooltipContent('object',key,x,e,graph)
    $scope.tooltipContent = (key, x, y, e, graph) ->
      if (x.charAt(0)=='▲' || x.charAt(0)=='▼')
        mkey = e.point[0].substring(1)
        id = graph.container.parentNode.id.replace(/_/g," ").replace(/[123]$/,"")
        compare = if(id == "IRI Length" or id == "Literal Length") then $scope.compare.stats.main[id] else $scope.compare.stats.triple[id]
        if (compare)
          if (x.charAt(0)=='▲')
            if (compare[mkey])
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(e.value - compare[mkey])} (#{pFormat((e.value - compare[mkey])*100/e.value)}%)"""
            else
              add=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""
          else add=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(e.value - compare[mkey])} (#{pFormat((compare[mkey]-e.value)*100/e.value)}%)"""
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
        triples : -($scope.main.stats.triple.Property.graphData[4].values[i][1]+$scope.main.stats.triple.Property.graphData[5].values[i][1]+$scope.main.stats.triple.Property.graphData[6].values[i][1])
        distinctIRIReferenceObjects : $scope.main.stats.triple.Property.graphData[0].values[i][1]
        distinctLiteralObjects : $scope.main.stats.triple.Property.graphData[1].values[i][1]
        distinctBlankNodeObjects : $scope.main.stats.triple.Property.graphData[2].values[i][1]
        distinctIRIReferenceSubjects : -$scope.main.stats.triple.Property.graphData[4].values[i][1]
        distinctBlankNodeSubjects : -$scope.main.stats.triple.Property.graphData[5].values[i][1]
      }
      add = {
        triples : ''
        distinctIRIReferenceObjects : ''
        distinctLiteralObjects : ''
        distinctBlankNodeObjects : ''
        distinctIRIReferenceSubjects : ''
        distinctBlankNodeSubjects : ''
      }
      compare = $scope.compare.stats.triple.Property
      if (compare)
        for key in ['triples','distinctIRIReferenceObjects','distinctLiteralObjects','distinctBlankNodeObjects','distinctIRIReferenceSubjects','distinctBlankNodeSubjects']
          if (compare[mkey])
            if (!compare[mkey][key])
              add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>(?)"""
            else if (compare[mkey][key]<values[key])
              add[key]=""" <span class="glyphicon text-success glyphicon-chevron-up"></span>+#{dFormat(values[key] - compare[mkey][key])} (#{pFormat((values[key] - compare[mkey][key])*100/values[key])}%)"""
            else if (compare[mkey][key]>values[key])
              add[key]=""" <span class="glyphicon text-danger glyphicon-chevron-down"></span>#{dFormat(values[key] - compare[mkey][key])} (#{pFormat((compare[mkey][key] - values[key])*100/values[key])}%)"""
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
            when "Property" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s #{value} ?o #{GE}} LIMIT 100"))
            when "Subject" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} #{value} ?p ?o #{GE}} LIMIT 100"))
            when "Object_Resource" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { #{GB} ?s ?property #{value} #{GE}} GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
            when "Object_Literal" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT ?property (COUNT(?s) AS ?subjectCount) (SAMPLE(?s) AS ?sampleSubject) { #{GB} ?s ?property #{value} #{GE}} GROUP BY ?property ORDER BY DESC(?subjectCount) LIMIT 100"))
            when "Object_Datatype" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s ?p ?o FILTER(datatype(?o) = #{value}) #{GE}} LIMIT 100"))
            when "Object_Language" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s ?p ?o FILTER(lang(?o) = #{value}) #{GE}} LIMIT 100"))
            when "Subject_Type" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT * { #{GB} ?s a #{value} #{GE}} LIMIT 100"))
            when "Object_Type" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { #{GB} ?s ?p ?o . ?o a #{value} #{GE}} LIMIT 100"))
            when "Property_Type" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { #{GB} ?s ?p ?o . ?p a #{value} #{GE}} LIMIT 100"))
            when "Property_Namespace" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?p { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?p),'#{value.substring(1,value.length - 1)}')) #{GE}} LIMIT 100"))
            when "Subject_Namespace" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?s { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?s),'#{value.substring(1,value.length - 1)}')) #{GE}} LIMIT 100"))
            when "Object_Namespace" then $window.open("#{$scope.dataset_sparqlEndpoint}?output=text&query="+encodeURIComponent("SELECT DISTINCT ?o { #{GB} ?s ?p ?o . FILTER (STRSTARTS(STR(?o),'#{value.substring(1,value.length - 1)}')) #{GE}} LIMIT 100"))
      else
        clickTimeout := $timeout(->
          stat = event.targetScope.id.replace(/_/g," ")
          if (stat in voidService.subjectStats)
            if $scope.limits.subject.value==value && $scope.limits.subject.stat==stat then $scope.limits.subject = void else $scope.limits.subject = { value, stat }
          else if (stat in voidService.propertyStats)
            if $scope.limits.property.value==value && $scope.limits.property.stat==stat then $scope.limits.property = void else $scope.limits.property = { value, stat }
          else if (stat in voidService.objectStats)
            if $scope.limits.object.value==value && $scope.limits.object.stat==stat then $scope.limits.object = void else $scope.limits.object = { value, stat }
          else return
          $scope.$apply!
        ,500)
    )
    sparqlEndpointInputCheckCanceler = {}
    !function checkInput(section)
      if ($scope[section].sparqlEndpointInput)
        $scope.queries++
        if sparqlEndpointInputCheckCanceler[section]? then sparqlEndpointInputCheckCanceler[section].resolve!
        sparqlEndpointInputCheckCanceler[section] = $q.defer!
        sparql.check($scope[section].sparqlEndpointInput,{timeout: sparqlEndpointInputCheckCanceler[section].promise}).then((valid) ->
          $scope.queries--
          $scope[section].sparqlEndpointInputValid = valid
        ,->
          $scope.queries--
          $scope[section].sparqlEndpointInputValid = false
        )
    $scope.$watch('main.sparqlEndpointInput', ->
      checkInput('main')
    )
    $scope.$watch('compare.sparqlEndpointInput', ->
      checkInput('compare')
    )
    !function fetchGraphs(section)
      $scope.errors=[]
      $scope[section].graphIRIFetching = true
      $scope[section].graphs = null
      if (section=='main' && $scope.compare.graphIRI==$scope.main.graphIRI && $scope.compare.sparqlEndpoint==$scope.main.sparqlEndpoint)
        $scope.compare.graphs=null
        $scope.compare.graphIRIFetching=true
      if (cancelers[section].graphs?) then cancelers[section].graphs.resolve!
      cancelers[section].graphs = $q.defer!
      $scope.queries++
      sparql.query($scope[section].sparqlEndpoint,'''
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
      ''',{timeout: cancelers[section].graphs.promise}).success((data) ->
        $scope.queries--
        found = false
        for binding in data.results.bindings
          if (binding.graphIRI?.value==$scope[section].graphIRI) then found = true
        if (!found) then delete $scope[section].graphIRI
        $scope[section].graphIRIFetching=false
        $scope[section].graphs = data.results.bindings
        if (section=='main' && $scope.compare.sparqlEndpoint==$scope.main.sparqlEndpoint)
          if (!found) then delete $scope.compare.graphIRI
          $scope.compare.graphIRIFetching=false
          $scope.compare.graphs = data.results.bindings
        fetchDatasets(section)
      ).error(handleError)
    $scope.$watch('main.sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $scope.main.sparqlEndpointInput = sparqlEndpoint
        $scope.errors = []
        for key, value of cancelers
          value.resolve!
        $location.search('sparqlEndpoint',sparqlEndpoint)
        if ($scope.compare.sparqlEndpoint==oldSparqlEndpoint || !$scope.compare.sparqlEndpoint? || $scope.compare.sparqlEndpoint=='') then $scope.compare.sparqlEndpoint=sparqlEndpoint
        fetchGraphs('main')
    )
    $scope.$watch('compare.sparqlEndpoint', (sparqlEndpoint,oldSparqlEndpoint) ->
      if (sparqlEndpoint!=oldSparqlEndpoint)
        $scope.compare.sparqlEndpointInput = sparqlEndpoint
        if (sparqlEndpoint==$scope.main.sparqlEndpoint) then sparqlEndpoint=null
        $location.search('compare_sparqlEndpoint',sparqlEndpoint)
        fetchGraphs('compare')
    )
    !function fetchDatasets(section)
      $scope.errors=[]
      $scope[section].datasetIRIFetching=true
      if (section=='main' && $scope.compare.datasetIRI==$scope.main.datasetIRI && $scope.compare.graphIRI==$scope.main.graphIRI && $scope.compare.sparqlEndpoint==$scope.main.sparqlEndpoint) then $scope.compare.datasetIRIFetching=true
      if (cancelers[section].datasets?) then cancelers[section].datasets.resolve!
      $scope[section].datasets = null
      cancelers[section].datasets = $q.defer!
      if ($scope[section].graphIRI)
        query = """
          SELECT DISTINCT ?datasetIRI ?sparqlEndpoint ?graphIRI {
            GRAPH <#{$scope[section].graphIRI}> {
              ?datasetIRI a <http://rdfs.org/ns/void\#Dataset> .
              OPTIONAL {
                ?datasetIRI <http://www.w3.org/ns/prov\#generatedBy> ?activity .
                ?activity <http://www.w3.org/ns/prov\#startedAtTime> ?time
              }
              OPTIONAL { ?datasetIRI <http://rdfs.org/ns/void\#sparqlEndpoint> ?sparqlEndpoint . }
              OPTIONAL { ?datasetIRI <http://www.w3.org/ns/sparql-service-description\#name> ?graphIRI . }
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
      sparql.query($scope[section].sparqlEndpoint,query,{timeout: cancelers[section].datasets.promise}).success((data) ->
        $scope.queries--
        found = false
        for binding in data.results.bindings
          if (binding.datasetIRI?.value==$scope[section].datasetIRI) then found = true
        if (!found) then delete $scope[section].datasetIRI
        if (!$scope[section].datasetIRI? && data.results.bindings.length>0)
          $scope[section].datasetIRI=data.results.bindings[0].datasetIRI?.value
        $scope[section].datasetIRIFetching=false
        $scope[section].datasets = data.results.bindings
        if (section=='main' && $scope.compare.graphIRI==$scope.main.graphIRI && $scope.compare.sparqlEndpoint==$scope.main.sparqlEndpoint)
          $scope.compare.datasetIRIFetching = false
          $scope.compare.datasets = data.results.bindings
          found = false
          for binding in data.results.bindings
            if (binding.datasetIRI?.value==$scope.compare.datasetIRI) then found = true
          if (!found) then delete $scope.compare.datasetIRI
          if (!$scope.compare.datasetIRI? && data.results.bindings.length>0)
            $scope.compare.datasetIRI=data.results.bindings[0].datasetIRI?.value
          if ($scope.compare.datasetIRI!=$scope.main.datasetIRI)
            fetchStatistics('compare',true)
        fetchStatistics(section,true)
      ).error(handleError)
    $scope.$watch('main.graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('graphIRI',graphIRI)
        fetchDatasets('main')
        if ($scope.compare.graphIRI==oldGraphIRI || !$scope.compare.graphIRI?) then $scope.compare.graphIRI=graphIRI
    )
    $scope.$watch('compare.graphIRI', (graphIRI,oldGraphIRI) ->
      if (graphIRI!=oldGraphIRI)
        $location.search('compare_graphIRI',graphIRI)
        if ($scope.compare.graphIRI!=$scope.main.graphIRI || $scope.compare.sparqlEndpoint!=$scope.main.sparqlEndpoint) then fetchDatasets('compare')
    )
    !function updateLimits
      $scope.queries++
      $scope.availableLimits = { subject:[],property:[],object:[]}
      voidService.getPossibleLimits($scope.main.sparqlEndpoint,$scope.main.graphIRI,'<' + $scope.main.datasetIRI + '>').success((data) ->
        $scope.queries--
        for binding in data.results.bindings
          los = sparql.bindingToString(binding.value)
          lo = {name: shortForm(los), stat : binding.stat.value, value : los }
          if (lo.stat in voidService.subjectStats) 
            $scope.availableLimits.subject.push(lo)
            if ($stateParams['subjectLimitStat']==lo.stat && $stateParams['subjectLimitValue']==los) then $scope.limits.subject=lo
          else if (lo.stat in voidService.propertyStats) 
            $scope.availableLimits.property.push(lo)
            if ($stateParams['propertyLimitStat']==lo.stat && $stateParams['propertyLimitValue']==los) then $scope.limits.property=lo
          else if (lo.stat in voidService.objectStats)
            $scope.availableLimits.object.push(lo)
            if ($stateParams['objectLimitStat']==lo.stat && $stateParams['objectLimitValue']==los) then $scope.limits.object=lo
      ).error(handleError)
    $scope.$watch('main.datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('datasetIRI',datasetIRI)
        if ($scope.compare.graphIRI==$scope.main.graphIRI && $scope.compare.sparqlEndpoint == $scope.main.sparqlEndpoint && !$scope.compare.datasetIRI?) then $scope.compare.datasetIRI=datasetIRI
        clearData!
        updateLimits!
        fetchStatistics('main',true)
        if ($scope.compare.datasetIRI!=$scope.main.datasetIRI || $scope.compare.sparqlEndpoint!=$scope.main.sparqlEndpoint || $scope.compare.graphIRI!=$scope.main.graphIRI)
          fetchStatistics('compare',true)
    )
    $scope.$watch('compare.datasetIRI', (datasetIRI,oldDatasetIRI) ->
      if (datasetIRI!=oldDatasetIRI)
        $location.search('compare.datasetIRI',datasetIRI)
        if ($scope.compare.datasetIRI!=$scope.main.datasetIRI || $scope.compare.sparqlEndpoint!=$scope.main.sparqlEndpoint || $scope.compare.graphIRI!=$scope.main.graphIRI)
          fetchStatistics('compare',true)
    )
    !function processCompareLength(outKey,bindings)
      obj = {}
      for binding in bindings
        if (binding.length?)
          key = binding.length.value
        else
          key = binding.minLength.value + '-' + (binding.maxLength?.value ? '')
        obj[key]=parseInt(binding['entities'].value)
      $scope.compare.stats.general[outKey] = obj
    !function processCompare(outKey,key,value,bindings)
      obj = {}
      for binding in bindings
        obj[sparql.bindingToString(binding[key])]=parseInt(binding[value].value)
      $scope.compare.stats.triple[outKey] = obj
    processCompareData = {
      'IRI Length' : (bindings) -> processCompareLength('iriLength',bindings)
      'Literal Length' : (bindings) -> processCompareLength('literalLength',bindings)
      'Property Namespace' : (bindings) -> processCompare('Property Namespace','propertyNamespace','entities',bindings)
      'Property Type' : (bindings) -> processCompare('Property Type','propertyClass','entities',bindings)
      'Subject Namespace' : (bindings) -> processCompare('Subject Namespace','subjectNamespace','entities',bindings)
      'Subject Type' : (bindings) -> processCompare('Subject Type','class','entities',bindings)
      'Subject' : (bindings) -> processCompare('Subject','s','triples',bindings)
      'Object Namespace' : (bindings) -> processCompare('Object Namespace','objectNamespace','entities',bindings)
      'Object Type' : (bindings) -> processCompare('Object Type','objectClass','entities',bindings)
      'Object Datatype' : (bindings) -> processCompare('Object Datatype','datatype','entities',bindings)
      'Object Language' : (bindings) -> processCompare('Object Language','language','entities',bindings)
      'Object Resource' : (bindings) -> processCompare('Object Resource','o','triples',bindings)
      'Object Literal' : (bindings) -> processCompare('Object Literal','o','triples',bindings)
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
        $scope.compare.stats.triple.Property = obj
      }
    !function handleLength(stat,valueType2)
      if (!$scope.main.stats.general[stat]?.raw?) then return
      entities1 = []
      entities2 = []
      entities3 = []
      tentities = 0
      for binding in $scope.main.stats.general[stat].raw
        count = parseInt(binding.entities.value)
        tentities += count
        if (binding.length?)
          key = binding.length.value
        else
          key = binding.minLength.value + '-' + (binding.maxLength?.value ? '')
        if ($scope.compare.stats.general[stat]?)
          if($scope.compare.stats.general[stat][key])
            count2 = $scope.compare.stats.general[stat][key]
            if (count2<count) then key = '▲' + key
            else if (count2>count) then key = '▼' + key
          else
            key = '▲' + key
        if (binding.length?)
          v1 = v2 = 0
        else 
          v1 = parseInt(binding.minLength.value)
          v2 = if (binding.maxLength?) then parseInt(binding.maxLength.value) else 2000
        if (v2 - v1 < 9) then entities1.push([key, count])
        else if (v2 - v1 < 99) then entities2.push([key,count])
        else entities3.push([key,count])
      $scope.main.stats.general[stat].total=tentities
      infos = 0
      if (entities1.length!=0)
        infos++
        $scope.main.stats.general[stat].single = [ { "key" : valueType2 , values : entities1 } ]
      else 
        delete $scope.main.stats.general[stat].single
      if (entities2.length!=0)
        infos++
        $scope.main.stats.general[stat].double = [ { "key" : valueType2 , values : entities2 } ]
      else 
        delete $scope.main.stats.general[stat].double
      if (entities3.length!=0)
        infos++
        $scope.main.stats.general[stat].triple = [ { "key" : valueType2 , values : entities3 } ]
      else 
        delete $scope.main.stats.general[stat].triple
      $scope.main.stats.general[stat].count = infos
    !function handle(stat,keyType,valueType1, valueType2)
      if (!$scope.main.stats.triple[stat]?.raw?) then return
      entities = []
      tentities = 0
      for binding,i in $scope.main.stats.triple[stat].raw
        key = sparql.bindingToString(binding[keyType])
        if (key=='UNDEF') then continue
        if ($scope.limits.subject?.stat == stat && $scope.limits.subject?.value==key)
          $scope.limits.subject.index=i
        else if ($scope.limits.property?.stat == stat && $scope.limits.property?.value==key)
          $scope.limits.property.index=i
        else if ($scope.limits.object?.stat == stat && $scope.limits.object?.value==key)
          $scope.limits.object.index=i
        count = parseInt(binding[valueType1].value)
        tentities += count
        if ($scope.compare.stats.triple[stat]?)
          if($scope.compare.stats.triple[stat][key])
            count2 = $scope.compare.stats.triple[stat][key]
            if (count2<count) then key = '▲' + key
            else if (count2>count) then key = '▼' + key
          else
            key = '▲' + key
        entities.push([key, count])
      $scope.main.stats.triple[stat]['total']=tentities
      $scope.main.stats.triple[stat].graphData = [ { "key" : valueType2 , values : entities } ]
    updateData = {
      'IRI Length' : -> handleLength('IRI Length','IRIs')
      'Literal Length' : -> handleLength('Literal Length','Literals')
      'Property Namespace' : -> handle('Property Namespace','propertyNamespace','entities','Properties')
      'Property Type' : -> handle('Property Type','propertyClass','entities','Properties')
      'Subject Namespace' : -> handle('Subject Namespace','subjectNamespace','entities','Subjects')
      'Subject Type' : -> handle('Subject Type','class','entities','Subjects')
      'Subject' : -> handle('Subject','s','triples','Triples')
      'Object Namespace' : -> handle('Object Namespace','objectNamespace','entities','Objects')
      'Object Type' : -> handle('Object Type','objectClass','entities','Objects')
      'Object Datatype' : -> handle('Object Datatype','datatype','entities','Literals')
      'Object Language' : -> handle('Object Language','language','entities','Literals')
      'Object Resource' : -> handle('Object Resource','o','triples','Triples')
      'Object Literal' : -> handle('Object Literal','o','triples','Triples')
      'Property' : ->
        if (!$scope.main.stats.triple.Property?.raw?) then return
        distinctIRIReferenceSubjects = []
        distinctBlankNodeSubjects = []
        distinctIRIReferenceObjects = []
        distinctBlankNodeObjects = []
        distinctLiterals = []
        triples = []
        triples2 = []
        ttriples = 0
        for binding,i in $scope.main.stats.triple.Property.raw
          property = sparql.bindingToString(binding.p)
          if (binding.triples?)
            ttriples=ttriples + parseInt(binding.triples.value)
            nrtriples1 = parseInt(binding.triples.value)
            nrtriples2 = nrtriples1
          else
            nrtriples1 = 0
            nrtriples2 = 0
          if ($scope.compare.stats.triple.Property)
            if ($scope.compare.stats.triple.Property[property])
              count2 = $scope.compare.stats.triple.Property[property].triples
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
          if ($scope.limits.property?.stat == 'Property' && $scope.limits.property?.value==property)
            $scope.limits.property.index=i
          triples.push([property, -nrtriples1])
          triples2.push([property, nrtriples2])
          if (binding.distinctIRIReferenceObjects?) then distinctIRIReferenceObjects.push([property, parseInt(binding.distinctIRIReferenceObjects.value)])
          else distinctIRIReferenceObjects.push([property,0])
          if (binding.distinctBlankNodeObjects?) then distinctBlankNodeObjects.push([property, parseInt(binding.distinctBlankNodeObjects.value)])
          else distinctBlankNodeObjects.push([property,0])
          if (binding.distinctLiterals?) then distinctLiterals.push([property, parseInt(binding.distinctLiterals.value)])
          else distinctLiterals.push([property,0])
        $scope.main.stats.triple.Property.total = ttriples
        $scope.main.stats.triple.Property.graphData = [
          { "key" : "IRI Reference Objects", values : distinctIRIReferenceObjects }
          { "key" : "Literal Objects", values : distinctLiterals }
          { "key" : "Blank Node Objects", values : distinctBlankNodeObjects }
          { "key" : "Triples", values : triples2 }
          { "key" : "IRI Reference Subjects", values : distinctIRIReferenceSubjects }
          { "key" : "Blank Node Subjects", values : distinctBlankNodeSubjects }
          { "key" : "Triples", values : triples }
        ]
    }
    !function calculateGeneralStatistics(prefix,endpoint,graphIRI)
      for query in voidService.generalStats
        if cancelers[prefix+query]? then cancelers[prefix+query].resolve!
        cancelers[prefix+query] = $q.defer!
        $scope.queries++
        voidService.calculateStatistic(endpoint,graphIRI,query,null,{timeout: cancelers[prefix+query].promise}).success((data) ->
          $scope.queries--
          processGeneralStatistics(prefix,data)).error(handleError)
    !function processGeneralStatistics(section,data)
      for stat, value of data.results.bindings[0]
        if (stat!='sparqlEndpoint' && stat!='graphIRI')
          $scope[section].stats.general[stat]=parseInt(value.value)
        else
          $scope[section].stats.general[stat]=value.value
      if (section=='compare')
        if ($scope.compare.stats.general.distinctIRIReferences? && $scope.compare.stats.general.distinctBlankNodes? && $scope.compare.stats.general.distinctLiterals?)
          $scope.compare.stats.allRDFNodes = {
            'IRI References': $scope.compare.stats.general.distinctIRIReferences
            'Blank Nodes': $scope.compare.stats.general.distinctBlankNodes
            'Literals': $scope.compare.stats.general.distinctLiterals
          }
        if ($scope.compare.stats.general.distinctIRIReferenceSubjects? && $scope.compare.stats.general.distinctBlankNodeSubjects?)
          $scope.compare.stats.subjectRDFNodes = {
            'IRI References': $scope.compare.stats.general.distinctIRIReferenceSubjects
            'Blank Nodes':$scope.compare.stats.general.distinctBlankNodeSubjects
          }
        if ($scope.compare.stats.general.distinctIRIReferenceObjects? && $scope.compare.stats.general.distinctBlankNodeObjects? && $scope.compare.stats.general.distinctLiterals?)
          $scope.compare.stats.objectRDFNodes = {
            'IRI References': $scope.compare.stats.general.distinctIRIReferenceObjects
            'Blank Nodes':$scope.compare.stats.general.distinctBlankNodeObjects
            'Literals':$scope.compare.stats.general.distinctLiterals
          }
      else 
        if ($scope.main.stats.general.distinctIRIReferences? && $scope.main.stats.general.distinctBlankNodes? && $scope.main.stats.general.distinctLiterals?)
          $scope.main.stats.general.allRDFNodes = [['IRI References',$scope.main.stats.general.distinctIRIReferences],['Blank Nodes',$scope.main.stats.general.distinctBlankNodes],['Literals',$scope.main.stats.general.distinctLiterals]]
        if ($scope.main.stats.general.distinctIRIReferenceSubjects? && $scope.main.stats.general.distinctBlankNodeSubjects?)
          $scope.main.stats.general.subjectRDFNodes = [['IRI References',$scope.main.stats.general.distinctIRIReferenceSubjects],['Blank Nodes',$scope.main.stats.general.distinctBlankNodeSubjects]]
        if ($scope.main.stats.general.distinctIRIReferenceObjects? && $scope.main.stats.general.distinctBlankNodeObjects? && $scope.main.stats.general.distinctLiterals?)
          $scope.main.stats.general.objectRDFNodes = [['IRI References',$scope.main.stats.general.distinctIRIReferenceObjects],['Blank Nodes',$scope.main.stats.general.distinctBlankNodeObjects],['Literals',$scope.main.stats.general.distinctLiterals]]
    !function processStatistics(section,stat,data)
      if (section=='compare')
        processCompareData[stat](data.results.bindings)
      else
        statSection = if stat=='IRI Length' or stat=='Literal Length' then 'general' else 'triple'
        if !$scope.main.stats[statSection][stat] then $scope.main.stats[statSection][stat]={}
        $scope.main.stats[statSection][stat].raw=data.results.bindings
      updateData[stat]!
    function getLimits(fstat)
      limits = []
      if ($scope.limits.property? && $scope.limits.property.stat!=fstat) then limits.push($scope.limits.property)
      if ($scope.limits.subject? && $scope.limits.subject.stat!=fstat) then limits.push($scope.limits.subject)
      if ($scope.limits.object? && $scope.limits.object.stat!=fstat) then limits.push($scope.limits.object)
      if (limits.length>0) then limits else null
    !function fetchStatistics(section,fetchGeneralStatistics)
      if (!$scope[section].datasets) then return
      $scope.errors=[]
      if (section=='main' && $scope.main.datasetIRI)
        $scope.dataset_sparqlEndpoint = null
        $scope.dataset_graphIRI = null
        for binding in $scope.main.datasets
          if $scope.main.datasetIRI==binding.datasetIRI.value 
            $scope.dataset_sparqlEndpoint=binding.sparqlEndpoint?.value
            $scope.dataset_graphIRI=binding.graphIRI?.value
      if (fetchGeneralStatistics)
        $scope[section].stats.general = {}
        $scope[section].allRDFNodes = null
        $scope[section].subjectRDFNodes = null
        $scope[section].objectRDFNodes = null
        if ($scope[section].datasetIRI)
          if cancelers[section].General? then cancelers[section].General.resolve!
          cancelers[section].General = $q.defer!
          $scope.queries++
          voidService.getStatistic($scope[section].sparqlEndpoint,$scope[section].graphIRI,$scope[section].datasetIRI,'General',null,{timeout: cancelers[section].General.promise}).success((data) ->
            $scope.queries--
            if (data.results.bindings.length>0 || !$scope.dataset_sparqlEndpoint)
              processGeneralStatistics(section,data)
            else calculateGeneralStatistics(section,$scope.dataset_sparqlEndpoint,$scope.dataset_graphIRI)
          ).error(handleError)
        else calculateGeneralStatistics(section,$scope[section].sparqlEndpoint,$scope[section].graphIRI)
      if !$scope[section].stats.triple? then $scope[section].stats.triple = {}
      for stat of updateData when fetchGeneralStatistics || (stat!='IRI Length' && stat!='Literal Length') 
        if cancelers[section][stat]? then cancelers[section][stat].resolve!
        stattype = 
          if voidService.subjectStats[stat] then \subject
          else if voidService.propertyStats[stat] then \property
          else \object
        if !$scope.limits[stattype]? || !$scope[section].stats.triple[stat]? || !(voidService.banList[$scope.limits[stattype].stat] && stat in voidService.banList[$scope.limits[stattype].stat])
          cancelers[section][stat] = $q.defer!
          $scope.queries++
          limits = if stat!='IRI Length' && stat!='Literal Length' then getLimits(stat) else void
          let stat,limits
            if ($scope[section].datasetIRI)
              voidService.getStatistic($scope[section].sparqlEndpoint,$scope[section].graphIRI,$scope[section].datasetIRI,stat,limits,{timeout: cancelers[section][stat].promise}).success((data) ->
                $scope.queries--
                if (data.results.bindings.length>0 || !$scope.dataset_sparqlEndpoint)
                  processStatistics(section,stat,data)
                else
                  $scope.queries++
                  voidService.calculateStatistic($scope.dataset_sparqlEndpoint,$scope.dataset_graphIRI,stat,limits,{timeout: cancelers[section][stat].promise}).success((data) ->
                    $scope.queries--
                    processStatistics(section,stat,data)).error(handleError)
              ).error(handleError)
            else
              voidService.calculateStatistic($scope[section].sparqlEndpoint,$scope[section].graphIRI,stat,limits,{timeout: cancelers[section][stat].promise}).success((data) ->
                $scope.queries--
                processStatistics(section,stat,data)).error(handleError)
    watchLimit = (stat,limit,oldLimit) -->
      if (limit==oldLimit) then return
      if (limit == "")
        delete $scope.limits[stat]
        return
      if (!limit?)
        $location.search("#{stat}LimitStat", null)
        $location.search("#{stat}LimitValue", null)
      else
        $location.search("#{stat}LimitStat", limit.stat)
        $location.search("#{stat}LimitValue", limit.value)
      fetchStatistics('main',false)
      if ($scope.compare.datasetIRI!=$scope.main.datasetIRI || $scope.compare.sparqlEndpoint!=$scope.main.sparqlEndpoint || $scope.compare.graphIRI!=$scope.main.graphIRI)
        fetchStatistics('compare',false)
    $scope.$watch('limits.subject', watchLimit('subject'))
    $scope.$watch('limits.property', watchLimit('property'))
    $scope.$watch('limits.object', watchLimit('object'))
    !function checkLimit(stat)
      if $location.search!["#{stat}LimitStat"] and $location.search!["#{stat}LimitValue"]
        limitStat = $location.search!["#{stat}LimitStat"]
        limitValue = $location.search!["#{stat}LimitValue"]
        for limit in $scope.availableLimits[stat]
          if limitStat==limit.stat and limitValue==limit.value then $scope.limits[stat]=limit
      else delete $scope["#{stat}Limit"]
    $scope.$on('$locationChangeSuccess', ->
      $scope.main.sparqlEndpoint = $location.search!.sparqlEndpoint
      $scope.main.graphIRI = $location.search!.graphIRI
      $scope.main.datasetIRI = $location.search!.datasetIRI
      if $location.search!.compare_sparqlEndpoint? then $scope.compare.sparqlEndpoint = $location.search!.compare_sparqlEndpoint
      if $location.search!.compare_graphIRI? then $scope.compare.graphIRI = $location.search!.compare_graphIRI
      if $location.search!.compare_datasetIRI? then $scope.compare.datasetIRI = $location.search!.compare_datasetIRI
      checkLimit('subject')
      checkLimit('property')
      checkLimit('object')
    )
    # initialization
    $scope.main = {
      sparqlEndpoint : $stateParams.sparqlEndpoint
      datasetIRI : $stateParams.datasetIRI
      graphIRI : $stateParams.graphIRI
      stats: { general: {}, triple: {}}
    }
    $scope.compare = {
      sparqlEndpoint : $stateParams.compare_sparqlEndpoint
      datasetIRI : $stateParams.compare_datasetIRI
      graphIRI : $stateParams.compare_graphIRI      
      stats: { general: {}, triple: {}}
    }
    $scope.limits = {
      subject : if $stateParams.subjectLimitStat? and $stateParams.subjectLimitValue? then {stat:$stateParams.subjectLimitStat,value:$stateParams.subjectLimitValue} else void
      property : if $stateParams.propertyLimitStat? and $stateParams.propertyLimitValue? then {stat:$stateParams.propertyLimitStat,value:$stateParams.propertyLimitValue} else void
      object : if $stateParams.objectLimitStat? and $stateParams.objectLimitValue? then {stat:$stateParams.objectLimitStat,value:$stateParams.objectLimitValue} else void
    }
    $scope.fullView = true
    if (!$scope.compare.graphIRI) then $scope.compare.graphIRI = $scope.main.graphIRI
    if (!$scope.compare.datasetIRI) then $scope.compare.datasetIRI = $scope.main.datasetIRI
    if ($scope.main.sparqlEndpoint)
      if (!$scope.compare.sparqlEndpoint) then $scope.compare.sparqlEndpoint = $scope.main.sparqlEndpoint
      $scope.main.sparqlEndpointInput = $scope.main.sparqlEndpoint
      fetchGraphs('main')
    if ($scope.compare.sparqlEndpoint) 
      $scope.compare.sparqlEndpointInput = $scope.compare.sparqlEndpoint
      if ($scope.compare.sparqlEndpoint!=$scope.main.sparqlEndpoint)
        fetchGraphs('compare')
      else if ($scope.compare.graphIRI!=$scope.main.graphIRI)
        fetchDatasets('compare')
    if ($scope.main.datasetIRI) then updateLimits!
        # move to right location after initial load
    if ($location.hash!)
      unregister = $scope.$watch('queries', (queries) ->
        if (queries==0)
          $anchorScroll!
          unregister!
      )
      
  )


  	
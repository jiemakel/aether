'use strict'

angular.module('fi.seco.sparql',[])
  .factory('sparql', ($http,$q) ->
    service =
      query : (endpoint,query,params) ->
        if (query.length<=2048)
          $http(angular.extend({
            method: "GET",
            url : endpoint,
            params: { query:query },
            headers: { 'Accept' : 'application/sparql-results+json' }
          },params))
        else
          $http(angular.extend({
            method: "POST",
            url : endpoint,
            data: query,
            headers:
              'Content-Type': 'application/sparql-query'
              'Accept' : 'application/sparql-results+json'
          },params))
      update : (endpoint,query,params) ->
        $http(angular.extend({
          method: "POST"
          url: endpoint,
          headers: { 'Content-Type' : 'application/sparql-update' }
          data: query
        },params))
      bindingToString : (binding) ->
          if !binding? then "UNDEF"
          else
            value = binding.value.replace(/\\/g,'\\\\').replace(/\t/g,'\\t').replace(/\n/g,'\\n').replace(/\r/g,'\\r').replace(/[\b]/g,'\\b').replace(/\f/g,'\\f').replace(/\'/g,"\\'").replace(/\"/g,'\\"')
            if (binding.type == 'uri') then '<' + value + '>'
            else if (binding.type == 'bnode') then '_:' + value
            else
              if (binding.datatype?)
                switch binding.datatype
                  when 'http://www.w3.org/2001/XMLSchema#integer','http://www.w3.org/2001/XMLSchema#decimal','http://www.w3.org/2001/XMLSchema#double','http://www.w3.org/2001/XMLSchema#boolean' then value
                  when 'http://www.w3.org/2001/XMLSchema#string' then '"' + value + '"'
                  else '"' + value + '"^^<'+binding.datatype+'>'
              else if (binding['xml:lang']) then '"' + value + '"@' + binding['xml:lang']
              else '"' + value + '"'
  )
# Each of the public functions here creates a graph for a given ontology
# and using some metaprogramming, exposes itself to the interface as an
# option.  In a future, possibly better word, it might be worth looking into
# CSV for the Web (https://www.w3.org/TR/tabular-data-model) 
# for a better way of doing this, but we're not there yet. 
#
module GraphBuilder

  include RDF::Vocab
  DPLA = RDF::StrictVocabulary.new("http://dp.la/about/map/")
  EDM = RDF::StrictVocabulary.new("http://www.europeana.eu/schemas/edm/")
  RDAGR2 = RDF::StrictVocabulary.new("http://RDVocab.info/ElementsGr2/")

  # def cidoc(obj)
  #   uri = RDF::URI.new(url("/#{obj[:id]}"))
  #   graph = RDF::Graph.new
  # end

  def dcterms(obj)
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = RDF::Graph.new
    prop(graph, uri, RDF::type, DC.Agent)
  end

  def dpla(obj)
    edm(obj)
  end

  def edm(obj) 
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = RDF::Graph.new

    prop(graph, uri, SKOS.prefLabel, obj[:name])
    prop(graph, uri, SKOS.altLabel, obj[:alternateName])
    prop(graph, uri, SKOS.exactMatch, obj[:sameAs])

    prop(graph, uri, RDF::type, EDM.Agent)
    prop(graph, uri, EDM::begin, make_date(obj[:birthDate]))
    prop(graph, uri, EDM::end, make_date(obj[:deathDate]))
    prop(graph, uri, FOAF.name, obj[:name])  
    prop(graph, uri, FOAF.name, obj[:name])  
    # prop(graph, uri, OWL.sameAs, obj[:sameAs])

    if obj[:entityType] == "Person"
      prop(graph, uri, RDAGR2::dateOfBirth, make_date(obj[:birthDate]))
      prop(graph, uri, RDAGR2::dateOfDeath, make_date(obj[:deathDate]))
      prop(graph, uri, RDAGR2::placeOfBirth, obj[:birthPlace])
      prop(graph, uri, RDAGR2::placeOfDeath, obj[:deathPlace])
      prop(graph, uri, RDAGR2::gender, obj[:gender])
    elsif obj[:entityType] == "Organization"
      prop(graph, uri, RDAGR2::dateOfEstablishment, make_date(obj[:birthDate]))
      prop(graph, uri, RDAGR2::dateOfTermination, make_date(obj[:deathDate]))
    end
    graph
  end

  def schema(obj)
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = RDF::Graph.new

    prop(graph, uri, RDF::type, SCHEMA[obj[:entityType]])

    prop(graph, uri, SCHEMA.name, obj[:name])
    prop(graph, uri, SCHEMA.sameAs, obj[:sameAs])
    prop(graph, uri, SCHEMA.mainEntityOfPage, obj[:webpage])
    prop(graph, uri, SCHEMA.image, obj[:image])
    prop(graph, uri, SCHEMA.alternateName, obj[:alternateName])
    if obj[:entityType] == "Person"
      prop(graph, uri, SCHEMA.birthPlace, obj[:birthPlace])
      prop(graph, uri, SCHEMA.deathPlace, obj[:deathPlace])    
      prop(graph, uri, SCHEMA.birthDate, make_date(obj[:birthDate]))    
      prop(graph, uri, SCHEMA.deathDate, make_date(obj[:deathDate]))    
      prop(graph, uri, SCHEMA.familyName, obj[:familyName])    
      prop(graph, uri, SCHEMA.givenName, obj[:givenName]) 
      prop(graph, uri, SCHEMA.nationality, obj[:nationality])

      if obj[:gender]
        gender = obj[:gender].downcase == "male" ? SCHEMA.Male : obj[:gender].downcase == "female" ? SCHEMA.Female : obj[:gender]
        prop(graph, uri, SCHEMA.gender, gender)    
      end
      
    elsif obj[:entityType] == "Organization"
      prop(graph, uri, SCHEMA.dissolutionDate, make_date(obj[:deathDate]))    
      prop(graph, uri, SCHEMA.foundingLocation, obj[:birthPlace])
      prop(graph, uri, SCHEMA.foundingDate, make_date(obj[:birthDate]))    
    end
    graph
  end

  def rdfs(obj)
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = RDF::Graph.new
    prop(graph, uri, RDF::RDFS.label, obj[:name])
  end

  def skos(obj)
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = RDF::Graph.new
    prop(graph, uri, SKOS.prefLabel, obj[:name])
    prop(graph, uri, SKOS.altLabel, obj[:alternateName])
    prop(graph, uri, SKOS.exactMatch, obj[:sameAs])
    prop(graph, uri, SKOS.hiddenLabel, obj[:sortName])
  end

  def foaf(obj)
    uri = RDF::URI.new(url("/#{obj[:id]}"))
    graph = graph = RDF::Graph.new

    agentType = FOAF[obj[:entityType]] rescue FOAF.Agent
    prop(graph, uri, RDF::type, agentType)
    
    prop(graph, uri, FOAF.name, obj[:name])  
    prop(graph, uri, FOAF.homepage, obj[:webpage])
    prop(graph, uri, FOAF.page, obj[:relatedWebpage])
    prop(graph, uri, FOAF.depiction, obj[:image]) 
  
    if agentType == FOAF.Person
      prop(graph, uri, FOAF.gender, obj[:gender].downcase)
      prop(graph, uri, FOAF.birthday, make_date(obj[:birthDate])&.strftime("%m-%d"))
      prop(graph, uri, FOAF.familyName, obj[:familyName])
      prop(graph, uri, FOAF.lastName, obj[:familyName])
      prop(graph, uri, FOAF.givenName, obj[:givenName])
      prop(graph, uri, FOAF.firstName, obj[:givenName])  
    end

    graph
    #knows, made, based_near, depiction
  end

  private

  def make_date(val)
    Date.parse(val) rescue val
  end

  def prop(graph, uri, vocab, field)
    if field 
      if field.is_a? String
        field.split("|").each do |subfield|
          graph << [uri, vocab, subfield]
        end
      else
        graph << [uri, vocab, field]
      end
    end
    graph
  end
end
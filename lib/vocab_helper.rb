module VocabHelper

  ActiveSupport::Inflector.inflections(:en) do |inflect|
    inflect.irregular 'as', 'as'
  end

  def lod_links(path,vocab=nil)
    vocab_string = vocab ? "?vocabs=#{vocab}" : ""
    jsonld = "<a href=#{path.gsub("html","jsonld"+vocab_string)}>JSON-LD</a>"    
    rdf = "<a href=#{path.gsub("html","rdf"+vocab_string)}>RDF</a>"    
    ttl = "<a href=#{path.gsub("html","ttl"+vocab_string)}>Turtle</a>"    

    str = vocab ? "as #{vocab.upcase}:" : "View as Linked Data:"
    "#{str} (#{[jsonld,ttl,rdf].join(", ")})"
  end

  def display_terms(graph)
    seen_values = []
    seen_types = []
    pairs = {}
    graph.each_statement do |statement|
      pred = RDF::Vocabulary.find_term(statement.predicate)
      puts "pred: #{pred}"
      next unless pred.respond_to? :label
      val = if statement.object.literal?  
        statement.object.to_s 
      else
        term = RDF::Vocabulary.find_term(statement.object)
        prefix = term.vocab.__prefix__
        prefix = term.vocab.to_uri.to_s.split("//")[1]&.split("/")&.first if prefix == :strictvocabulary
        [prefix,term.label].compact.join(":")
      end
      pairs[pred.label] ||= []
      pairs[pred.label] << [val,pred.to_uri]
    end
    pairs.sort_by{|key,val| key}.collect do |key, val|
      val = val.reduce([]){|memo,obj| memo.push(obj) unless memo.collect{|m| m[0].downcase}.include?(obj[0].downcase); memo}
      list_item(key.titleize, val.collect{|a| a[0]}.uniq, is_link: val[0].first.start_with?("http"),  title_link: val.collect{|a| a[1].to_s}.uniq )
    end.join("\n")
  end

end
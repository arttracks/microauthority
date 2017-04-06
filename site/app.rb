# Ruby Standard Library
require "json"
require "yaml"
require "benchmark"

# Sinatra & Extensions
require 'sinatra/base'
require "sinatra/reloader" 
require "sinatra/json"
require "sinatra/content_for"
require "sinatra/link_header"

# Linked Data Libraries
require "linkeddata"

# Views and Templates
require "haml"
require "sass"
require 'active_support'
require "active_support/inflector"
require 'active_support/core_ext'

# Internal Libraries
require "./lib/metadata_helper.rb"
require "./lib/graph_builder.rb"
require "./lib/vocab_helper.rb"

# Character Encoding Libraries
require 'charlock_holmes'


class MicroAuthority < Sinatra::Base

  helpers Sinatra::LinkHeader
  helpers Sinatra::ContentFor
  helpers MetadataHelper
  helpers VocabHelper

  include GraphBuilder

  ## Load the CSV File into memory
  def self.load_csv
    obj = {}
    csv_opts =  {
              encoding: "UTF-8", 
              headers: true, 
              row_sep: :auto, 
              header_converters: :symbol, 
              converters: :all
            }
    time = Benchmark.realtime do

      id_present = true

      csvContent = File.read("./data/#{settings.config["csv_file_name"]}")
      detection = CharlockHolmes::EncodingDetector.detect(csvContent)
      utf8_encoded_content = CharlockHolmes::Converter.convert csvContent, detection[:encoding], 'UTF-8'

      CSV.parse(utf8_encoded_content,  csv_opts)
      .sort_by{|row| (row["sortName"] || row["name"])}
      .each_with_index do |row, i|
        row[:id] = (i+1) if row[:id].nil?
        row[:id] = row[:id].to_s.parameterize.underscore
        if obj[row[:id]]
          puts "\n\nERROR:\n\nTwo rows in data.csv both have the same id: '#{row[:id]}'.\nPlease fix this in your data.\nMicroAuthority will not run until you do this.\n\n"
          exit 1
        end
        row[:entityType] ||= "Person"
        value = row.to_h.delete_if { |k, v| v.nil? }
        key = value[:id]
        obj[key] = value
      end
    end
    puts "Loaded CSV in #{time.round(4)} seconds"
    obj
  end

  # Load a cache of the fields into memory to power the typeahead
  def self.load_typeahead
    lookup = {}
    time = Benchmark.realtime do
      settings.data.each do |key, entity|
        next unless entity[:name]
        words = entity[:name].downcase.split(" ")
        while words.count > 0 
          phrase = words.join(" ")
          lookup[phrase] ||= []
          lookup[phrase] << entity[:id].to_i
          words.shift
        end
      end
    end
    puts "Loaded typahead in #{time.round(4)} seconds"
    lookup
  end


  #  Development-Environment-specific configuration
  configure :development do
    register Sinatra::Reloader
    Dir.glob('./lib/**/*') { |file| also_reload file}
    set :show_exceptions, :after_handler
  end

  # Global configuration
  configure do 
    set :config,    YAML.load_file("./config/settings.yaml")
    set :context,   File.read("data/context.json")
    set :frame,     File.read("data/frame.json")
    set :data,      load_csv
    set :typeahead, load_typeahead
  end
 

             #-------------------------------------------------#
             #                  ROUTES BELOW                   #
             #-------------------------------------------------#


  before do
    @footer_text = settings.config["footer_text"]
    @header_text = settings.config["header_text"]
  end

  # Index Route
  #----------------------------------------------------------------------------
  get "/" do
    @total = settings.data.count
    @vocabs = GraphBuilder.public_instance_methods
    @config = settings.config
    haml :index
  end
  get "/index.html" do
    status, headers, body = call env.merge("PATH_INFO" => '/')
  end

  # CSS Route.  (here as a lazy way to use SASS as a preprocessor)
  #----------------------------------------------------------------------------
    get "/stylesheets/base.css" do
    sass :"sass/base"
  end

  # Robot Route (here for Sitemaps)
  #----------------------------------------------------------------------------
  get "/robots.txt" do
    "Sitemap: #{@config["domain"]}/sitemap.xml.gz"
  end

  # CSV Data Dump
  #----------------------------------------------------------------------------
    get "/dump.csv" do
    attachment
    File.read("./data/#{settings.config["csv_file_name"]}")
  end


  # the paginated list of possible routes, as both JSON and html
  #----------------------------------------------------------------------------
  get "/list.json", :provides => "json" do
    unless @everything_as_json
      obj = {}
      settings.data.each{|key, val| obj[key] = val[:name]}
      @everything_as_json = obj.to_json
    end
    content_type "application/json"
    @everything_as_json
  end

  get "/list.?:format?/?", :provides => "html" do
    per_page = 100
    @start = params.fetch("offset", 1).to_i
    @end = @start + per_page - 1
    @total = settings.data.count
    list=settings.data.values[(@start-1),per_page]
    @entries = list.collect{|a| {name: a[:name], url: url("/#{a[:id]}")}}
    haml :pagination
  end

  # the typeahead endpoint.  
  #----------------------------------------------------------------------------
  get "/typeahead" do
    halt  404 unless query = params[:q]
    results = settings.typeahead.find_all{|key,val| key.start_with?(query.downcase)}
    if results
      results = results.reduce([]){|memo,a| memo << a[1]}.flatten.uniq
      results = results.collect{|id| {value: lookup(id)[:name], id: id}}
    end
    json results || {}
  end


  get "/reconcile" do
    if params.include?("query")
      query = params["query"]
      unless query[0] == "{"
        query = "{\"query\":\"#{query}\"}"
      end
      begin 
        data = JSON.parse(query)
      rescue JSON::ParserError
        error 404, "invalid query: #{query}"
      end
     
      reconciled_data =  reconcile(data)
    elsif params.include?("queries")
      begin 
        data = JSON.parse(params["queries"])
      rescue JSON::ParserError
        error 404, "invalid query: #{params["queries"]}"
      end
      results = {}
      data.each do |key,val|
        results[key] = reconcile(val)
      end
      reconciled_data = results
    else
      reconciled_data = {
        name: "#{settings.config["institution_name"]} Agent Reconciliation Service",
        identifierSpace: settings.config["domain"],
        schemaSpace: "https://schema.org",
        defaultTypes: ["Person", "Organization"]
      }
    end
    if params["callback"]
      content_type "application/javascript"
      "#{params["callback"]}(#{reconciled_data.to_json});"
    else
      json reconciled_data
    end
  end


  # The JSON-LD Context
  #----------------------------------------------------------------------------
  get "/context" do
    cache_control :public
    etag Digest::SHA1.hexdigest(settings.context)

    if request.accept? "application/ld+json"
      content_type "application/ld+json"
    else
      content_type "application/json"
    end
    
    settings.context
  end

  # The JSON-LD Frame
  #----------------------------------------------------------------------------
  get "/frame" do
    cache_control :public
    etag Digest::SHA1.hexdigest(settings.frame)

    if request.accept? "application/ld+json"
      content_type "application/ld+json"
    else
      content_type "application/json"
    end
    
    settings.frame
  end


  # the HTML route for each entity
  #----------------------------------------------------------------------------
  get /^\/([\w]+)\.html$/ do
    id = params[:captures].first
    @entity = lookup(id)
    halt 404 unless @entity
    redirect(to(@entity[:"permalink"]), 301) if @entity[:"permalink"] && !params["force"]
    @graph = schema(@entity)
    haml :entity
  end

  # the RDF routes for each entity
  #----------------------------------------------------------------------------
  get "/:id.:extension" do
    return 404 if params[:id] == "favicon"
    vocabs = params[:vocabs].split(",").collect{|v| v.to_sym} if params[:vocabs]
    graph_as_type(params[:id],params[:extension].to_sym,vocabs)
  end

  # The entity with no extension (here to handle/allow content negotiation)
  #----------------------------------------------------------------------------
  get "/:id/?" do

    # Handle 301_redirect
    if data = lookup(params[:id])
      redirect(to(data[:"301_redirect"]), 301)  if data[:"301_redirect"] && !params["force"]
    else
      halt 404
    end

    id = params[:id]
    # Handle Content Negotiation
    if params[:format].nil?
      request.accept.each do |accept_obj|
        case accept_obj.to_s
        when "application/ld+json"
          redirect to("#{id}.jsonld"), 303
        when "application/json"
          redirect to("#{id}.json"), 303
        when "text/turtle"
          redirect to("#{id}.ttl"), 303
        when "application/rdf+xml"
          redirect to("#{id}.rdf"), 303
        end
      end

      # default to HTML
      querystring = params[:force] ? "?force=true" : ""
      redirect to("#{id}.html#{querystring}"), 303
    end
  end



  #-------------------------------------------------#
  #            INSTANCE METHODS BELOW               #
  #-------------------------------------------------#


  # Retrieve a record
  #----------------------------------------------------------------------------
   def lookup(id)
    id_num = id
    settings.data[id_num]
  end

  # Given an ID and an optional list of vocabularies, return a graph
  #----------------------------------------------------------------------------
  def get_graph(id,vocabs=nil)
    puts "ID: #{id}"

    # Whitelist
    vocabs ||= []
    possible_vocabs = GraphBuilder.public_instance_methods
    vocabs = (vocabs & possible_vocabs)

    # By default, include everything
    vocabs = possible_vocabs if vocabs.empty?

    # by default, always include RDF.label
    vocabs << :rdfs

    #instantiate the graph and the data 
    data = lookup(id)
    graph = RDF::Graph.new

    # Call all the vocabs and include them
    vocabs.each do |vocab|
      graph << self.send(vocab,data) 
    end

    graph
  end


  def reconcile(obj)
     # obj = {
     #  *  name:        data["query"],
     #  *  limit:       data["limit"],
     #  *  type:        data["type"],
     #    type_strict: data["type_strict"],
     #    properties:  data["properties"]
     #  }
    results = settings.typeahead.find_all do |key,val| 
      key.start_with?(obj["query"].downcase)
    end
    if results.empty?
      return {result: []}
    else
      results = results.reduce([]){|memo,a| memo << a[1]}.flatten.uniq
      results = results.collect do |id| 
        data = lookup(id)

        next if obj["type"] && ![obj["type"]].flatten.include?(data[:entityType]) 

        result = {
          id:    data[:permalink] || uri("/#{id}"),              # ... string, database ID ...
          name:  data[:name],                                    # ... string ...
          type:  [data[:entityType]],                            # ... array of strings ...
          score:  0,                                             # ... double ...
          match:  (obj["query"].downcase == data[:name].downcase)  # ... boolean, true if the service is quite confident about the match ...
        }
      end.compact

      limit = obj["limit"].nil? ? results.count : obj["limit"].to_i 
      return { result: results.first(limit) }
    end
  end

  # Given an id, a format, and an optional list of vocabs, return
  # set the content type and return the content (as a string).
  #----------------------------------------------------------------------------
  def graph_as_type(id, extension, vocabs=nil)
    
    graph = get_graph(id,vocabs)
    
    case extension
    when :html
      pass
    when :rdf
      content_type "application/rdf+xml"
      graph.dump(:rdfxml)  
    when :ttl
      content_type "text/turtle"
      graph.dump(:turtle)  
    when :json
      headers "Link" => "<#{uri("/context")}>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\""
      content_type "application/json"
      graph.dump(:jsonld)  
    when :jsonld
      content_type "application/ld+json"
      unframed_json = JSON::LD::API::fromRdf(graph)
      contextual_json = JSON::LD::API.compact(unframed_json, uri("/context"))
      JSON.pretty_generate contextual_json
    else
      halt 404, "Could not load #{extension} for #{id}."
    end
  end
end









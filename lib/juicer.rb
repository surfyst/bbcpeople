require 'cgi'

class Juicer
  include HTTParty
  #http_proxy 'www-cache.reith.bbc.co.uk', 80 if Rails.env.development?

  class << self

    # Takes a name and returns a person object for the person with that name
    def person_by_name(name)
      name = CGI::escape(name)

      response = get("http://triplestore.bbcnewslabs.co.uk/api/concepts?product=http://www.bbc.co.uk/ontologies/bbc/NewsWeb&uri=http://dbpedia.org/resource/#{name}")

      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      Person.new(name:        json_data['label'],
                 description: json_data['abstract'],
                 dbpedia_uri: json_data['uri'],
                 image_uri:   json_data['thumbnail'])
    end

    # Takes a name and returns an organisation object for the organisation with that name
    def organisation_by_name(name)
      name = CGI::escape(name)

      response = get(URI.encode("http://triplestore.bbcnewslabs.co.uk/api/concepts?product=http://www.bbc.co.uk/ontologies/bbc/NewsWeb&uri=http://dbpedia.org/resource/#{name}"))

      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      Organisation.new(name:        json_data['label'],
                       description: json_data['abstract'],
                       image_uri:   json_data['thumbnail'],
                       dbpedia_uri: json_data['uri'])
    end


    # Returns an array of news articles relating to an entity or an array of multiple entities
    def articles_related_to(entities)
      if(entities.is_a? Entity)
        articles = articles_for(entities)
      else
        articles = []
        entities.each do |entity|
          articles = articles | articles_for(entity) # set union to remove duplication
          articles.sort! { |x, y| x.published_at <=> y.published_at }.reverse!
        end
      end
      articles.uniq! { |article| article.headline } if articles.present?
      articles
    end

    def articles_for(entity)
      response = get(URI.encode("http://triplestore.bbcnewslabs.co.uk/api/concepts?product=http://www.bbc.co.uk/ontologies/bbc/NewsWeb&uri=#{entity.dbpedia_uri}"))

      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      return [] unless json_data['articles']

      json_data['articles'].map do |json|
        Article.new(
          cps_id:    json['cpsid'],
          headline:  json['title'],
          uri:       json['article'],
          published_at: json['published']
        )
      end
    end
 

    def people_related_to(entity)
      response = get(URI.encode("http://triplestore.bbcnewslabs.co.uk/api/concepts/co-occurrences?concept=#{entity.dbpedia_uri}&type=http://dbpedia.org/ontology/Person"))
      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      json_data['co-occurrences'].map do |json|

        if entity.name == json['label']
          nil
        else
          Person.new(
            name:              json['label'],
            cooccurence_count: json['occurrence'],
            dbpedia_uri:       json['thing'],
            image_uri:         json['img']
          )
        end
      end.compact
    end

    def organisations_related_to(entity)
      response = get(URI.encode("http://triplestore.bbcnewslabs.co.uk/api/concepts/co-occurrences?concept=#{entity.dbpedia_uri}&type=http://dbpedia.org/ontology/Organisation"))
      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      json_data['co-occurrences'].map do |json|
        Organisation.new(
          name:              json['label'],
          cooccurence_count: json['occurrence'],
          dbpedia_uri:       json['thing'],
          image_uri:         json['img']
        )
      end
    end

    def people_related_to_article(id)
      response = get(URI.encode("http://juicer.bbcnewslabs.co.uk/articles/#{id}.json"))

      return [] if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      json_data['article']['people'].map do |json|
        name = URI.escape(CGI.escape( json['uri'].split( '/' ).last ),'.')
        ::Juicer.person_by_name(name)
      end
    end

    def organisations_related_to_article(id)
      response = get(URI.encode("http://juicer.bbcnewslabs.co.uk/articles/#{id}.json"))
      return [] if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      json_data['article']['organisations'].map do |json|
        name = URI.escape(CGI.escape( json['uri'].split( '/' ).last ),'.')
        ::Juicer.organisation_by_name(name)
      end
    end

    def trending_people(after_date=nil)
      after_date = (Time.now - 1.day).strftime("%Y-%m-%d")
      response = get(URI.encode("http://triplestore.bbcnewslabs.co.uk/api/concepts/occurrences?type=http://dbpedia.org/ontology/Person&after=#{after_date}"))
      return nil if response.body.blank? || response.code != 200
      json_data = JSON.parse(response.body)

      json_data['occurrences'].map do |json|
        Person.new(
          name:              json['label'],
          cooccurence_count: json['occurrence'],
          dbpedia_uri:       json['thing'],
          image_uri:         json['img']
        )
      end
    end
  end
end

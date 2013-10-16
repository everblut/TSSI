#!/usr/bin/ruby

require 'twitter'
require 'mongo'


def init
  Twitter.configure do |config|
    config.consumer_key        = "f7cG75dRoMkty7bhyg1UyQ"
    config.consumer_secret     = "46JPSnfnHkLFykwisOUKPQPo7xLZ6vrDvwRkJfFTDo"
    config.oauth_token        = "146482713-rH5z8S5Yt7cTjLQalrjh5VzVbo18akh52KSrwdyf"
    config.oauth_token_secret = "PS2VJpGQLyjkvuQhKWgL73Rs9114vjVYwNcq2WP7QWk"
  end
end

def getCliente
  return Twitter
end

def readTweets(data,idioma,cantidad)
  cliente = getCliente()
  if cliente
    return cliente.search(data, :lang => idioma, :count => cantidad).results
  else
    puts "no tweets"
    return nil
  end
end

def saveTweets(tweets)
  collection =  Mongo::MongoClient.new.db("TSSI")["tweets"]
  if collection.count > 0
    lastId = collection.find.sort({"id" => -1}).limit(1).to_a[0]["id"]
  else
    lastId = 1
  end
  tweets.each do |tweet|
    next if !collection.find( { "text" => /tweet.full_text/ } ).to_a[0].nil?
    lastId = lastId+1
    data = { "id" => lastId, "user" => tweet.from_user, "text" => tweet.full_text, "date" => tweet.created_at, "flagged" => false  }
    collection.insert(data)
  end
  collection.db.close()  
end

def createSanityArray()
    arr = Array.new
    File.open('setwords.dat','r').each_line do |line|
    	arr << line.chomp
    end
    puts arr
    return arr
end

def eval
    collection = Mongo::MongoClient.new.db("TSSI")["tweetsFlagged"]
    words = createSanityArray()
    collection.find.to_a.each do |c|
      words.each do |w|
       if c["text"].match(Regexp.new(w,Regexp::IGNORECASE))
          c["flagged"] = true
	  puts "flagged #{w} en #{c["text"]}"
       	  collection.update( {"_id" => c["_id"]}, c)
       end	
      end
    end
end

def main
   if ARGV[0] == "eval"
      eval
      return
   end
   unless ARGV[0].nil?
        puts "Criterio de busqueda : #{ARGV[0]}"
    else
       return puts "Primer argumento, criterio de busqueda"
    end
    unless ARGV[1].nil? 
        puts "Cantidad de tweets : #{ARGV[1]}"
    else
	return puts "Necesitas una cantida de tweets como segundo parametro"
    end 
  init
  saveTweets(readTweets(ARGV[0],"es",ARGV[1].to_i))
end

main

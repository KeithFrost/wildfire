module Bttrack
    class Request 
    def initialize(params, config)
      @params = params
      @config = config
    end
    
    def info_hash
      @info_hash ||= InfoHash.new(@params, @config)
    end

    def peer
      @peer ||= Peer.new(@params, @config)
    end

    def compact?
      @params[:compact].to_i == 1 || @config[:compact]
    end

    def no_peer_id?
      @params[:no_peer_id].to_i != 1
    end

    def numwant
      n = @params[:numwant].nil? ? @config[:default_peers] : @params[:numwant].to_i
      n = (n == 0 || n > @config[:max_peers]) ? @config[:max_peers] : n
    end

    def downloaded
      @params[:downloaded].to_i
    end

    def uploaded
      @params[:uploaded].to_i
    end

    def left
      @params[:left].to_i
    end
    
    def event
      @params[:event].to_s
    end
  end
end

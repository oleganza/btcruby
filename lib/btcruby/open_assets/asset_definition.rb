# Implementation of OpenAssets Asset Definition Format
# https://github.com/OpenAssets/open-assets-protocol/blob/master/asset-definition-protocol.mediawiki
require 'json' # in Ruby 2 stdlib
module BTC
  class AssetDefinition
    
    DEFAULT_VERSION = "1.0".freeze
    
    attr_accessor :asset_ids
    attr_accessor :name_short
    attr_accessor :name
    attr_accessor :contract_url
    attr_accessor :issuer
    attr_accessor :description
    attr_accessor :description_mime
    attr_accessor :type
    attr_accessor :divisibility
    attr_accessor :link_to_website
    attr_accessor :icon_url
    attr_accessor :image_url
    attr_accessor :version

    def initialize(dictionary: nil,
                   json: nil,
                   asset_ids: [],
                   name: nil,
                   name_short: nil,
                   issuer: nil,
                   type: nil,
                   divisibility: 0)

      @json = json
      dictionary ||= (json ? JSON.parse(json) : nil)
      if dictionary
        @asset_ids = dictionary["asset_ids"].map{|aid| AssetID.parse(aid) }
      else
        @asset_ids = asset_ids
        @name = name
        @name_short = name_short
        @issuer = issuer
        @type = type
        @divisibility = divisibility
      end
      @version ||= DEFAULT_VERSION
      @asset_ids ||= []
      @divisibility ||= 0
    end

    def dictionary
      dict = {}
      dict["asset_ids"]  = self.asset_ids.map{|aid| aid.to_s}
      dict["name_short"] = self.name_short || ""
      dict["name"]       = self.name || ""
      dict["contract_url"] =       self.contract_url     if self.contract_url
      dict["issuer"] =             self.issuer           if self.issuer
      dict["description"] =        self.description      if self.description
      dict["description_mime"] =   self.description_mime if self.description_mime
      dict["type"] =               self.type             if self.type
      dict["divisibility"] =       self.divisibility     if self.divisibility
      dict["link_to_website"] =    self.link_to_website  if self.link_to_website
      dict["icon_url"] =           self.icon_url         if self.icon_url
      dict["image_url"] =          self.image_url        if self.image_url
      dict["version"] =            self.version          if self.version
      dict
    end

    def json
      @json ||= JSON.generate(dictionary)
    end
    
    def sha256
      BTC.to_hex(BTC.sha256(json))
    end
  end
end

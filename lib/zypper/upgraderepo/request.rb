require 'delegate'
require_relative 'traversable.rb'
require_relative 'requests/local.rb'
require_relative 'requests/http.rb'

module Zypper
  module Upgraderepo


    class Request

      def self.build(repo, timeout)
        @@registry ||= self.load_requests

        raise InvalidProtocol, repo unless @@registry.include? repo.protocol

        Object.const_get(@@registry[repo.protocol]).new(repo, timeout)
      end

      def self.protocols
        self.load_requests.keys
      end

      private

      def self.load_requests
        res = {}
        Requests.constants.each do |klass|
          Object.const_get("Zypper::Upgraderepo::Requests::#{klass}").register_protocol.each do |protocol|
            res[protocol] = "Zypper::Upgraderepo::Requests::#{klass}"
          end
        end

        res
      end

    end



  end
end

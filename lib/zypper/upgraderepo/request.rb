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

        Object.const_get(self.find_class(repo)).new(repo, timeout)
      end

      def self.protocols
        self.load_requests.keys
      end

      private

      def self.load_requests
        res = {}
        Requests.constants.each do |klass|
          obj = Object.const_get("Zypper::Upgraderepo::Requests::#{klass}")
          obj.register_protocol.each do |protocol|
            res[protocol] ||= {}
            res[protocol][obj.domain] = "Zypper::Upgraderepo::Requests::#{klass}"
          end
        end

        res
      end

      def self.find_class(repo)
        domain = URI(repo.url).hostname

        if @@registry[repo.protocol].has_key? domain
          return @@registry[repo.protocol][domain]
        else
          return @@registry[repo.protocol]['default']
        end
      end
    end

  end
end

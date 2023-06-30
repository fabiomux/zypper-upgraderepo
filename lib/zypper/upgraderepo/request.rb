# frozen_string_literal: true

require "delegate"
require_relative "traversable"
require_relative "requests/local"
require_relative "requests/http"

module Zypper
  module Upgraderepo
    #
    # Load the right class to handle the protool and
    # achieve the request..
    #
    class Request
      def self.build(repo, timeout)
        @@registry ||= load_requests

        raise InvalidProtocol, repo unless @@registry.include? repo.protocol

        Object.const_get(find_class(repo)).new(repo, timeout)
      end

      def self.protocols
        load_requests.keys
      end

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

        return @@registry[repo.protocol][domain] if @@registry[repo.protocol].key? domain

        @@registry[repo.protocol]["default"]
      end
    end
  end
end

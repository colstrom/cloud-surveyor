require 'aws-sdk'
require_relative 'config'

module CloudSurveyor
  class Queue
    def config
      @config ||= Config.new
    end

    def service
      @api ||= if config.endpoint
                 Aws::SQS::Client.new endpoint: config.endpoint
               else
                 Aws::SQS::Client.new
               end
    end
  end
end

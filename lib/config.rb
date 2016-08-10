require 'yaml'

module CloudSurveyor
  class Config
    def path
      @path ||= File.expand_path ENV.fetch('CONFIG_PATH') { './queues.yaml' }
    end

    def config
      @config ||= File.exist?(path) ? YAML.load_file(path) : {}
    end

    def endpoint
      @endpoint ||= config.dig('aws', 'sqs_endpoint')
    end

    def queues
      @queues ||= config.fetch('queues') { [] }.map(&:first)
    end

    def regions
      @regions ||= if ENV.key? 'REGIONS'
                     ENV.fetch('REGIONS').split($IFS)
                   else
                     config.fetch('regions') { [] }
                   end
    end
  end
end

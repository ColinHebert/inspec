# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'openssl'

module Fetchers
  class Local < Inspec.fetcher(1)
    name 'local'
    priority 0

    def self.resolve(target)
      local_path = if target.is_a?(String)
                     resolve_from_string(target)
                   elsif target.is_a?(Hash)
                     resolve_from_hash(target)
                   end

      new(local_path) if local_path
    end

    def self.resolve_from_hash(target)
      return unless target.key?(:path)

      local_path = target[:path]
      local_path = File.expand_path(local_path, target[:cwd]) if target.key?(:cwd)
      local_path
    end

    def self.resolve_from_string(target)
      # Support "urls" in the form of file://
      if target.start_with?('file://')
        target = target.gsub(%r{^file://}, '')
      else
        # support for windows paths
        target = target.tr('\\', '/')
      end

      target if File.exist?(target)
    end

    def initialize(target)
      @target = target
    end

    def fetch(_path)
      archive_path
    end

    def archive_path
      @target
    end

    def writable?
      File.directory?(@target)
    end

    def cache_key
      sha256.to_s
    end

    def sha256
      return nil if File.directory?(@target)
      @archive_shasum ||=
        OpenSSL::Digest::SHA256.digest(File.read(@target)).unpack('H*')[0]
    end

    def resolved_source
      h = { path: @target }
      h[:sha256] = sha256 if sha256
      h
    end
  end
end

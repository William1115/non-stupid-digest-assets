require "sprockets/manifest"
require "pathname"

module NonStupidDigestAssets
  mattr_accessor :whitelist
  @@whitelist = []

  class << self
    def assets(assets)
      return assets if whitelist.empty?
      whitelisted_assets(assets)
    end

    private

    def whitelisted_assets(assets)
      assets.select do |logical_path, digest_path|
        whitelist.any? do |item|
          item === logical_path
        end
      end
    end
  end

  module CompileWithNonDigest
    def compile *args
      paths = super
      NonStupidDigestAssets.assets(assets).each do |(logical_path, digest_path)|
        full_digest_path = File.join dir, digest_path
        full_digest_gz_path = "#{full_digest_path}.gz"
        full_non_digest_path = File.join dir, logical_path
        full_non_digest_gz_path = "#{full_non_digest_path}.gz"

        relative_digest_name = Pathname.new(full_digest_path).relative_path_from(Pathname.new(full_non_digest_path).dirname).to_s
        relative_digest_gz_name = Pathname.new(full_digest_gz_path).relative_path_from(Pathname.new(full_non_digest_gz_path).dirname).to_s

        if File.exists? full_digest_path
          logger.debug "Writing #{full_non_digest_path}"
          FileUtils.ln_s relative_digest_name, full_non_digest_path, :force => true
        else
          logger.debug "Could not find: #{full_digest_path}"
        end
        if File.exists? full_digest_gz_path
          logger.debug "Writing #{full_non_digest_gz_path}"
          FileUtils.ln_s relative_digest_gz_name, full_non_digest_gz_path, :force => true
        else
          logger.debug "Could not find: #{full_digest_gz_path}"
        end
      end
      paths
    end
  end
end

Sprockets::Manifest.send(:prepend, NonStupidDigestAssets::CompileWithNonDigest)

require 'base64'
require 'digest'
require 'openssl'
require 'fileutils'

module Jekyll
  PROTECTED_POSTS = []

  # Hook: Remove password-protected posts from Jekyll output
  Jekyll::Hooks.register :site, :post_read do |site|
    all_posts = site.posts.docs
    protected = all_posts.select { |p| p.data['password'] }

    # Save protected posts for plugin to process
    PROTECTED_POSTS.concat(protected)

    # Prevent Jekyll from rendering them
    site.posts.docs.delete_if { |p| protected.include?(p) }
  end

  class ProtectedPage < Page
    def aes256_encrypt(password, cleardata)
      raise ArgumentError, "Password required for encryption" if password.nil? || password.empty?

      digest = Digest::SHA256.new
      digest.update(password)
      key = digest.digest

      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv = cipher.random_iv

      encrypted = cipher.update(cleardata) + cipher.final
      encoded_msg = Base64.encode64(encrypted).gsub(/\n/, '')
      encoded_iv = Base64.encode64(iv).gsub(/\n/, '')

      hmac = Base64.encode64(OpenSSL::HMAC.digest('sha256', key, encoded_msg)).strip
      "#{encoded_iv}|#{hmac}|#{encoded_msg}"
    end

    def initialize(site, base, dir, to_protect)
      @site = site
      @base = base

      post_date = to_protect.data['date'] || to_protect.date
      slug = to_protect.basename_without_ext.sub(/^\d{4}-\d{2}-\d{2}-/, '')

      year  = post_date.strftime('%Y')
      month = post_date.strftime('%m')
      day   = post_date.strftime('%d')

      @dir = File.join(year, month, day)
      @name = "#{slug}.html"

      markdown_content = to_protect.content
      markdown_converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      html_content = markdown_converter.convert(markdown_content)

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'protected.html')

      # Expose front matter to layout
      to_protect.data.each do |key, value|
        self.data[key] = value
      end

      password = to_protect.data['password']
      if password
        # Only hash post content (not metadata) to avoid unnecessary cache invalidation
        content_digest = Digest::SHA1.new
        content_digest.update(to_protect.content)
        content_hash = content_digest.hexdigest

        protected_cache_path = File.join(Dir.pwd, '_protected-cache')
        page_cache_path = File.join(protected_cache_path, to_protect.basename_without_ext)
        hash_path = File.join(page_cache_path, 'hash')
        payload_path = File.join(page_cache_path, 'payload')

        regenerate = false

        if File.exist?(hash_path) && File.exist?(payload_path)
          cached_hash = File.read(hash_path).strip
          cached_payload = File.read(payload_path).strip

          if cached_hash == content_hash
            self.data['protected_content'] = cached_payload
          else
            regenerate = true
          end
        end

        FileUtils.mkdir_p(page_cache_path)

        if !File.exist?(hash_path) || regenerate
          File.write(hash_path, content_hash)
        end

        if !File.exist?(payload_path) || regenerate
          encrypted_content = self.aes256_encrypt(password, html_content)
          File.write(payload_path, encrypted_content)
          self.data['protected_content'] = encrypted_content
        end
      else
        self.data['protected_content'] = html_content
      end
    end
  end

  class ProtectedPageGenerator < Generator
    def generate(site)
      protected_pages_names = []

      PROTECTED_POSTS.each do |plain_page|
        protected_page = ProtectedPage.new(site, site.source, '', plain_page)
        site.pages << protected_page
        protected_pages_names << plain_page.basename_without_ext
      end

      # Clean up stale cache
      protected_cache_path = File.join(Dir.pwd, '_protected-cache')
      return unless Dir.exist?(protected_cache_path)

      Dir.foreach(protected_cache_path) do |cached_page|
        next if cached_page == '.' || cached_page == '..'
        unless protected_pages_names.include?(cached_page)
          FileUtils.rm_rf(File.join(protected_cache_path, cached_page))
        end
      end
    end
  end
end

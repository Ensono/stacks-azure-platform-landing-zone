RUBY_ENGINE == 'opal' ? (require 'generate-banner-image/extension') : (require_relative 'generate-banner-image/extension')

# Register the extension
Asciidoctor::Extensions.register do
  block BannerImageBlock
end

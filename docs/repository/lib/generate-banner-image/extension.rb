require 'rmagick'

include Asciidoctor

class BannerImageBlock < Asciidoctor::Extensions::BlockProcessor

  use_dsl

  named :banner_image
  # on_context :paragraph

  def process(parent, reader, attributes)

    # Set default values for attributes
    width = (attributes.fetch 'width', 300).to_i
    height = (attributes.fetch 'height', 45).to_i
    font_name = attributes.fetch 'font_name', 'Arial'
    font_size = (attributes.fetch 'font_size', 20).to_i
    bg_color = attributes.fetch 'bg_color', 'red'
    font_color = attributes.fetch 'font_color', 'white'
    font_weight = (attributes.fetch 'font_weight', 100).to_i
    text = attributes.fetch 'text', 'Banner Text'


    # Create the banner image
    img = Magick::Image.new(width, height) { |options| options.background_color = bg_color }
    gc = Magick::Draw.new
    gc.font = font_name
    gc.pointsize = font_size
    gc.fill = font_color
    gc.gravity = Magick::CenterGravity
    gc.font_weight = font_weight
    gc.annotate(img, 0, 0, 0, 0, text)


    # Convert the image to a base64-encoded data URI
    base64_data = img.to_blob { |i| i.format = 'PNG' }
    data_uri = "data:image/png;base64,#{Base64.strict_encode64(base64_data)}"


    # Create the image block
    image_block = Asciidoctor::Block.new(parent, :image, content_model: :empty, attributes: {
      'target' => data_uri,
      'alt' => text
    })

    image_block
  end

end

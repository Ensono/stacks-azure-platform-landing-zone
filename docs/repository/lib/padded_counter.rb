# frozen_string_literal: true

# Asciidoctor extension to provide a zero-padded, variable-width counter macro
# with a default of 3 digits, global (document attribute), and per-macro control.
#
# Usage in AsciiDoc:
#   paddedcounter:section[]             # yields 001, 002, etc. (default pad=3)
#   :paddedcounter-pad: 4
#   paddedcounter:section[]             # yields 0001, 0002, etc.
#   paddedcounter:section[pad=2]        # yields 01, 02, etc.

require 'asciidoctor'
require 'asciidoctor/extensions'

Asciidoctor::Extensions.register do
  inline_macro do
    named :paddedcounter

    process do |parent, target, attrs|
      doc = parent.document
      counter_name = "paddedcounter-#{target}"
      value = doc.counter(counter_name)

      # Priority: Macro attribute > Document attribute > Default (3)
      pad =
        if attrs['pad']
          attrs['pad'].to_i
        elsif doc.attr?('paddedcounter-pad')
          doc.attr('paddedcounter-pad').to_i
        else
          3
        end

      format_str = "%0#{pad}d"
      formatted = format_str % value
      (create_inline parent, :quoted, formatted).convert
    end
  end
end

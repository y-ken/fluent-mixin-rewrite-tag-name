module Fluent
  module Mixin
    module RewriteTagName
      include RecordFilterMixin
      attr_accessor :tag, :hostname_command

      DEFAULT_HOSTNAME_COMMAND = 'hostname'

      def configure(conf)
        super

        hostname_command = @hostname_command || DEFAULT_HOSTNAME_COMMAND
        hostname = `#{hostname_command}`.chomp
        @placeholder_expander = PlaceholderExpander.new
        @placeholder_expander.setHostname(hostname)
      end

      def filter_record(tag, time, record)
        super
        if @tag
          rewrite_tag!(tag)
        end
      end

      def rewrite_tag!(tag)
        @placeholder_expander.setTag(tag)
        emit_tag = @placeholder_expander.expand(@tag)
        tag.gsub!(tag, emit_tag)
      end

      class PlaceholderExpander
        # referenced https://github.com/fluent/fluent-plugin-rewrite-tag-filter, thanks!
        # referenced https://github.com/sonots/fluent-plugin-record-reformer, thanks!
        attr_reader :placeholders

        def initialize
          @placeholders = {}
        end

        def expand(str)
          str.gsub(/(\${[a-z_]+(\[-?[0-9]+\])?}|__[A-Z_]+(\[-?[0-9]+\])?__)/) {
            $log.warn "RewriteTagNameMixin: unknown placeholder `#{$1}` found" unless @placeholders.include?($1)
            @placeholders[$1]
          }
        end

        def setTag(value)
          setPlaceholder('tag', value)
          setTagParts(value)
        end

        def setHostname(value)
          setPlaceholder('hostname', value)
        end

        def setTagParts(tag)
          tag_parts = tag.split('.') 
          size = tag_parts.size
          tag_parts.each_with_index { |t, idx|
            setPlaceholder("tag_parts[#{idx}]", t)
            setPlaceholder("tag_parts[#{idx-size}]", t) # support tag_parts[-1]
          }
        end

        private
        def setPlaceholder(key, value)
          @placeholders.store("${#{key.downcase}}", value)
          @placeholders.store("__#{key.upcase}__", value)
        end
      end
    end
  end
end

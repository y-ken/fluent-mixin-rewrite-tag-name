module Fluent
  module Mixin
    module RewriteTagName
      include RecordFilterMixin
      attr_accessor :tag, :hostname_command
      attr_accessor :enable_placeholder_upcase, :enable_placeholder_hostname

      DEFAULT_HOSTNAME_COMMAND = 'hostname'

      def configure(conf)
        super

        @placeholder_expander = PlaceholderExpander.new

        if enable_upcase = conf['enable_placeholder_upcase']
          @enable_placeholder_upcase = enable_upcase
        end
        if @enable_placeholder_upcase
          @placeholder_expander.enable_placeholder_upcase
        end

        if enable_hostname = conf['enable_placeholder_hostname']
          @enable_placeholder_hostname = enable_hostname
        end
        if @enable_placeholder_hostname
          hostname_command = @hostname_command || DEFAULT_HOSTNAME_COMMAND
          hostname = `#{hostname_command}`.chomp
          @placeholder_expander.enable_placeholder_hostname
          @placeholder_expander.set_hostname(hostname)
        end
      end

      def filter_record(tag, time, record)
        super
        if @tag
          rewrite_tag!(tag)
        end
      end

      def rewrite_tag!(tag)

        @placeholder_expander.set_tag(tag)
        emit_tag = @placeholder_expander.expand(@tag)
        tag.gsub!(tag, emit_tag)
      end

      class PlaceholderExpander
        # referenced https://github.com/fluent/fluent-plugin-rewrite-tag-filter, thanks!
        # referenced https://github.com/sonots/fluent-plugin-record-reformer, thanks!
        attr_reader :placeholders

        def initialize
          @placeholders = {}
          @enable_options = {
            :hostname => false,
            :upcase => false,
          }
        end

        def expand(str)
          str.gsub(/(\${[a-z_]+(\[-?[0-9]+\])?}|__[A-Z_]+(\[-?[0-9]+\])?__)/) {
            $log.warn "RewriteTagNameMixin: unknown placeholder `#{$1}` found" unless @placeholders.include?($1)
            @placeholders[$1]
          }
        end

        def enable_placeholder_hostname
          @enable_options[:hostname] = true
        end

        def enable_placeholder_upcase
          @enable_options[:upcase] = true
        end

        def set_tag(value)
          set_placeholder('tag', value)
          set_tag_parts(value)
        end

        def set_hostname(value)
          set_placeholder('hostname', value)
        end

        def set_tag_parts(tag)
          tag_parts = tag.split('.') 
          size = tag_parts.size
          tag_parts.each_with_index { |t, idx|
            set_placeholder("tag_parts[#{idx}]", t)
            set_placeholder("tag_parts[#{idx-size}]", t) # support tag_parts[-1]
          }
        end

        private
        def set_placeholder(key, value)
          @placeholders.store("${#{key.downcase}}", value)
          @placeholders.store("__#{key.upcase}__", value) if @enable_options[:upcase]
        end
      end
    end
  end
end

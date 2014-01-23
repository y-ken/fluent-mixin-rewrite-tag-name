module Fluent
  module Mixin
    module RewriteTagName
      include RecordFilterMixin
      attr_accessor :tag, :hostname_command
      attr_accessor :enable_placeholder_upcase

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

        hostname_command = @hostname_command || DEFAULT_HOSTNAME_COMMAND
        hostname = `#{hostname_command}`.chomp
        @placeholder_expander.set_hostname(hostname)
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
        tag.sub!(tag, emit_tag)
      end

      class PlaceholderExpander
        # referenced https://github.com/fluent/fluent-plugin-rewrite-tag-filter, thanks!
        # referenced https://github.com/sonots/fluent-plugin-record-reformer, thanks!
        # referenced https://github.com/tagomoris/fluent-plugin-forest, thanks!
        attr_reader :placeholders

        def initialize
          @tag = ''
          @placeholders = {}
          @enable_options = {
            :upcase => false,
          }
        end

        def expand(str)
          str = str.gsub(/(\${(tag|hostname)}|__(TAG|HOSTNAME)__)/) do |name|
            $log.warn "RewriteTagNameMixin: unknown placeholder `#{name}` found" unless @placeholders.include?(name)
            @placeholders[name]
          end
          str = str.gsub(/__TAG_PARTS\[-?[0-9]+(?:\.\.\.?-?[0-9]+)?\]__|\$\{tag_parts\[-?[0-9]+(?:\.\.\.?-?[0-9]+)?\]\}/) do |tag_parts_offset|
            expand_tag_parts(tag_parts_offset)
          end
        end

        def expand_tag_parts(tag_parts_offset)
          begin
            position = /\[(?<first>-?[0-9]+)(?<range_part>(?<range_type>\.\.\.?)(?<last>-?[0-9]+))?\]/.match(tag_parts_offset)
            raise "failed to parse offset even though matching tag_parts" unless position
            tag_parts = @tag.split('.')
            if position[:range_part]
              extract_tag_part_range(tag_parts, position)
            else
              extract_tag_part_index(tag_parts, position)
            end
          rescue StandardError => e
            $log.warn "RewriteTagNameMixin: failed to expand tag_parts. :message=>#{e.message} tag:#{@tag} placeholder:#{tag_parts_matched}"
            nil
          end
        end

        def extract_tag_part_index(tag_parts, position)
          index = position[:first].to_i
          raise "missing placeholder." unless tag_parts[index]
          tag_parts[index]
        end

        def extract_tag_part_range(tag_parts, position)
          exclude_end = (position[:range_type] == '...')
          range = Range.new(position[:first].to_i, position[:last].to_i, exclude_end)
          raise "missing placeholder." unless tag_parts[range]
          tag_parts[range].join('.')
        end

        def enable_placeholder_upcase
          @enable_options[:upcase] = true
        end

        def set_tag(value)
          @tag = value
          set_placeholder('tag', value)
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

module Fluent
  module Mixin
    module RewriteTagName
      include RecordFilterMixin
      attr_accessor :tag

      def filter_record(tag, time, record)
        super
        if @tag
          rewrite_tag!(tag)
        end
      end

      def rewrite_tag!(tag)
        placeholder = {
          '${tag}' => tag,
          '__TAG__' => tag
        }
        emit_tag = @tag.gsub(/(\${[a-z_]+(\[[0-9]+\])?}|__[A-Z_]+__)/) do
          $log.warn "RewriteTagNameMixin: unknown placeholder found. :placeholder=>#{$1} :tag=>#{tag} :rewritetag=>#{rewritetag}" unless placeholder.include?($1)
          placeholder[$1]
        end
        tag.gsub!(tag, emit_tag)
      end
    end
  end
end

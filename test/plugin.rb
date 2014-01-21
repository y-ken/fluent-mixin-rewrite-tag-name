class Fluent::RewriteTagNameMixinOutput < Fluent::Output
  Fluent::Plugin.register_output('rewrite_tag_name_mixin', self)

  config_param :tag, :string, :default => nil
  config_param :hostname_command, :string, :default => 'hostname'

  include Fluent::HandleTagNameMixin
  include Fluent::Mixin::RewriteTagName
  config_set_default :enable_placeholder_upcase, false
  config_set_default :enable_placeholder_hostname, true

  def configure(conf)
    super

    if ( !@tag && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix )
      raise Fluent::ConfigError, "RewriteTagNameMixin: missing remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
    end
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      emit_tag = tag.dup
      filter_record(emit_tag, time, record)
      Fluent::Engine.emit(emit_tag, time, record)
    end
    chain.next
  end
end

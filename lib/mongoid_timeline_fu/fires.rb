module MongoidTimelineFu
  module Fires
    def fires(event_type, opts)
      raise ArgumentError, "Argument :on is mandatory" unless opts.has_key?(:on)
    
      # Array provided, set multiple callbacks
      if opts[:on].kind_of?(Array)
        opts[:on].each { |on| fires(event_type, opts.merge({:on => on})) }
        return
      end
    
      opts[:subject] = :self unless opts.has_key?(:subject)
      
      on = opts.delete(:on)
      _if = opts.delete(:if)
    
      type = opts.delete(:type) || "TimelineEvent"

      method_name = :"fire_#{event_type}_after_#{on}"
      define_method(method_name) do
        create_options = opts.keys.inject({}) do |memo, sym|
          if opts[sym]
            if opts[sym].respond_to?(:call)
              memo[sym] = opts[sym].call(self)
            elsif opts[sym] == :self
              memo[sym] = self
            else
              memo[sym] = send(opts[sym])
            end
          end
          memo
        end
        create_options[:event_type] = event_type.to_s
    
        type.constantize.create!(create_options)
      end
    
      send(:"after_#{on}", method_name, :if => _if)
    end
     
    def fires_manually(event_type, opts)
      opts[:subject] = :self unless opts.has_key?(:subject)
      type = opts.delete(:type) || "TimelineEvent"

      method_name = :"fire_#{event_type}"
      define_method(method_name) do |params|
        create_options = opts.keys.inject({}) do |memo, sym|
          if opts[sym]
            if self.respond_to?(opts[sym])
              memo[sym] = send(opts[sym])
            elsif opts[sym] == :self
              memo[sym] = self
            else
              memo[sym] = params[opts[sym]]
            end
          end
          memo
        end
        create_options[:event_type] = event_type.to_s

        type.constantize.create!(create_options)
      end
    end
  end
end


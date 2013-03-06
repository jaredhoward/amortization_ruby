class Class

  def extended_attr_accessor(*args)
    original_args = args.dup
    options = args.last.is_a?(Hash) ? args.pop : {}

    args.each do |attribute|
      self.class_eval("def #{attribute};@#{attribute};end")
    end

    self.extended_attr_writer(original_args)
  end

  def extended_attr_writer(*args)
    args.flatten!
    options = args.last.is_a?(Hash) ? args.pop : {}

    args.each do |attribute|
      @extended_attributes = {} unless @extended_attributes
      @extended_attributes[attribute.to_sym] = options

      self.class_eval <<-EOC
        def #{attribute}=(value)
          ext = self.class.instance_variable_get(:@extended_attributes)[:#{attribute}]

          unless value.nil?
            if ext[:kind_of]
              kinds = *ext[:kind_of]
              raise ArgumentError, "\#\{self.class.to_s\}##{attribute}= \#\{value.inspect\} is not the correct data type" unless kinds.map{|k| value.kind_of?(k) }.include?(true)
            end
            if ext[:validate]
              if ext[:validate].instance_of?(Proc)
                raise ArgumentError, "\#\{self.class.to_s\}##{attribute}= \#\{value.inspect\} is not valid" unless ext[:validate].call(value)
              end
            end
          end

          [ext[:reset]].flatten.each {|reset| instance_variable_set(:"@\#\{reset\}", nil) } if ext[:reset]

          @#{attribute} = value
        end
      EOC
    end
  end

end

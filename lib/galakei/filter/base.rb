module Galakei
  module Filter
    class Base
      attr_accessor :controller

      def self.condition?(controller)
        @instance ||= self.new
        @instance.controller = controller
        @instance.condition?
      end

      def self.filter(controller, &block)
        @instance ||= self.new
        @instance.controller = controller
        @instance.filter(&block)
      end

      def method_missing(m, *args)
        if controller.respond_to?(m)
          controller.send(m, *args)
        else
          super
        end
      end
    end
  end
end

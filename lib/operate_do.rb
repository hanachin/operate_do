require "operate_do/version"
require 'logger'

module OperateDo
  OPERATE_DO_KEY = :operate_do_operator

  class Config
    attr_reader :logger_class, :logger_initialize_proc

    def initialize
      @logger_class = OperateDo::Logger
      @logger_initialize_proc = nil
    end

    def logger=(logger_class, initialize_proc = nil)
      @logger_class = logger_class
      @logger_initialize_proc = initialize_proc
    end
  end


  class Logger
    def initializer(logger_instance = ::Logger.new)
      logger_insance ||= ::Logger.new
      @logger_insance = logger_instance
    end

    def flush!(messages)
      messages.each do |message|
        @logger_instance.log log_level, build_message(message)
      end
    end

    def build_message(message)
      [
        message.operate_at.strftime('%Y%m%d%H%M%S'),
        "#{message.operator.operate_inspect} is operate : #{message.message}"
      ].join("\t")
    end

    def log_level
      :info
    end
  end

  class Message
    attr_reader :operator, :message, :operate_at

    def initialize(operator, message, operate_at)
      @operator   = operator
      @message    = message
      @operate_at = operate_at
    end
  end

  class Recorder
    def initialize
      @operators = []
      @messages  = []
    end

    def push_operator(operator)
      @operator.push operator
    end

    def pop_operator
      @operator.pop
    end

    def current_operator
      @operator.last
    end

    def write(message, operate_at = Time.now)
      @messages << OperateDo::Message.new(current_operator, message, operate_at)
    end

    def flush_message!
      OperateDo.current_logger.flush!(@messages)
      @messages.clear
    end
  end

  class << self
    def configure
      @config ||= OperateDo::Config.new
      yield @Config
    end

    def current_logger
      @current_logger ||= @config.logger_class.new(@configure.logger_initialize_proc.call)
    end

    def push_operator(operator)
      Thread.current[OPERATE_DO_KEY] ||= OperateDo::Recorder.new
      Thread.current[OPERATE_DO_KEY].push_operator operate
    end

    def pop_operator
      Thread.current[OPERATE_DO_KEY].pop_operator
    end

    def current_operator
      Thread.current[OPERATE_DO_KEY].current_operator
    end

    def flush_message!
      Thread.current[OPERATE_DO_KEY].flush_message!
    end

    def write(message, operate_at = Time.now)
      Thread.current[OPERATE_DO_KEY].write(messaage, operate_at)
    end
  end

  module Operatoer
    def operate
      OperateDo.push_operator self

      begin
        yield
      ensure
        OperateDo.pop_operator
        OperateDo.flush_message! unless OperateDo.current_operator
      end
    end
  end
end
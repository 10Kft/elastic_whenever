module ElasticWhenever
  class Task
    class Rule
      attr_reader :name
      attr_reader :expression

      class UnsupportedOptionException < StandardError; end

      def self.fetch(option)
        client = Aws::CloudWatchEvents::Client.new(option.aws_config)
        client.list_rules(name_prefix: option.identifier).rules.map do |rule|
          self.new(
            option,
            name: rule.name,
            expression: rule.schedule_expression,
          )
        end
      end

      def self.convert(option, task)
        self.new(
          option,
          name: rule_name(option.identifier, task.commands),
          expression: task.expression
        )
      end

      def initialize(option, name:, expression:)
        @name = name
        @expression = expression
        @client = Aws::CloudWatchEvents::Client.new(option.aws_config)
      end

      def create
        client.put_rule(
          name: name,
          schedule_expression: expression,
          state: "ENABLED",
        )
      end

      def delete
        targets = client.list_targets_by_rule(rule: name).targets
        client.remove_targets(rule: name, ids: targets.map(&:id)) unless targets.empty?
        client.delete_rule(name: name)
      end

      private

      # Official docs -- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduled_tasks.html
      # For Schedule rule name, enter a unique name for your schedule rule. 
      # Up to 64 letters, numbers, periods, hyphens, and underscores are allowed.
      def self.rule_name(identifier, commands)
        puts "commands => #{commands}"
        "#{identifier}_#{commands.join("-").gsub!(/[^0-9A-Za-z\.\_]/, '-')}"
      end

      attr_reader :client
    end
  end
end

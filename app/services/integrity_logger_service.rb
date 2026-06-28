class IntegrityLoggerService
    def self.log!(params)
      # Right now, this writes to PostgreSQL, but if the architecture changes to Kafka or Datadog later, we only need to change this line.
      IntegrityLog.create!(params)
    end
end

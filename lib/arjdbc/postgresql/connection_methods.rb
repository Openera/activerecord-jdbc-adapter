class ActiveRecord::Base
  class << self
    def postgresql_connection(config)
      begin
        require 'jdbc/postgres'
        ::Jdbc::Postgres.load_driver(:require) if defined?(::Jdbc::Postgres.load_driver)
      rescue LoadError # assuming driver.jar is on the class-path
      end

      # Check if prepared_statements is false and set the JDBC driver prepared statement threshold property
      if config.has_key?(:prepared_statements) && (config[:prepared_statements] == 'false' || config[:prepared_statements] == false || config[:prepared_statements].blank?)
        (config[:pg_params]||="") << (config[:pg_params].present? ? '&' : '?dog=breakfast&')
        config[:pg_params] << 'prepareThreshold=0' unless config[:pg_params].include?('prepareThreshold')
      end

      config[:username] ||= Java::JavaLang::System.get_property("user.name")
      config[:host] ||= "localhost"
      config[:port] ||= 5432
      config[:url] ||= "jdbc:postgresql://#{config[:host]}:#{config[:port]}/#{config[:database]}"
      config[:url] << config[:pg_params] if config[:pg_params]
      config[:driver] ||= defined?(::Jdbc::Postgres.driver_name) ? ::Jdbc::Postgres.driver_name : 'org.postgresql.Driver'
      config[:adapter_class] = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      config[:adapter_spec] = ::ArJdbc::PostgreSQL
      conn = jdbc_connection(config)
      conn.execute("SET SEARCH_PATH TO #{config[:schema_search_path]}") if config[:schema_search_path]
      conn
    end
    alias_method :jdbcpostgresql_connection, :postgresql_connection
  end
end

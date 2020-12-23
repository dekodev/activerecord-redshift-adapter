require "spec_helper"

describe ActiveRecord::Base do
  let(:connection) { ActiveRecord::Base.redshift_connection(TEST_CONNECTION_HASH) }

  describe '.redshift_connection' do
    it "opens a connection" do
      expect(connection).to be_active
    end
  end

  describe 'set UTC timezone for datetime' do
    class TimezoneTest < ActiveRecord::Base
      default_timezone = :jst
      establish_connection(TEST_CONNECTION_HASH.merge('adapter' => 'redshift', 'read_timezone' => 'UTC'))
    end

    before do
      connection.query <<-SQL
        CREATE TABLE public.timezone_tests ( "id" INTEGER NULL, "created_at" TIMESTAMP NULL );
        INSERT INTO public.timezone_tests VALUES (1, '2013-07-01 12:00:00');
      SQL
    end

    after do
      connection.query <<-SQL
        DROP TABLE public.timezone_tests;
      SQL
    end

    it 'returns timestamp as UTC' do
      data = TimezoneTest.all.first
      expect(data.created_at.zone).to eq 'UTC'
      expect(data.created_at).to eq Time.parse '2013-07-01 12:00:00 UTC'
    end
  end
end

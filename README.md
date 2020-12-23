# activerecord-redshift-adapter

adapter for aws redshift for rails 3

Ripped from rails 3 postgresql.

## example database.yml
```yml
common: &common
  adapter: postgresql
  username: postgres
  encoding: SQL_ASCII
  template: template0
  pool: 5
  timeout: 5000

redshiftdb: &redshiftdb
  adapter: redshift
  host: clustername.something.us-east-1.redshift.amazonaws.com
  database: databasename
  port: 5439
  username: username
  password: password

redshift_development:
  <<: *common
  <<: *redshiftdb
  database: databasename
```

## options
```html
<table>
  <tr>
    <th>option</th>
    <th>description</th>
  </tr>
  <tr>
    <th>schema_search_path</th>
    <td>set schema_search_path. use default value if not given.</td>
  </tr>
  <tr>
    <th>read_timezone</th>
    <td>force timezone for datetime when select values. ActiveRecord default timezone will set if not given.</td>
  </tr>
</table>
```

## Have you considered using Partitioned gem?  It works with redshift!

https://github.com/fiksu/partitioned

## TableManager

Helpful code to clone redshift tables

```sql
create table foos
(
  id int not null primary key distkey,
   name varchar(255) unique sortkey
);
```

```ruby
class Foo < ActiveRecord::Base
end

require 'activerecord_redshift_adapter'

table_manager = ActiverecordRedshift::TableManager.new(Foo.connection, :exemplar_table_name => Foo.table_name)
table_manager.duplicate_table
```

yields:

```sql
  select oid from pg_namespace where nspname = 'public' limit 1;

  select oid,reldiststyle from pg_class where relnamespace = 2200 and relname = 'foos' limit 1;

  select contype,conkey from pg_constraint where connamespace = 2200 and conrelid = 212591;

  select attname,attnum from pg_attribute where attrelid = 212591 and attnum in (2,1);

  show search_path;

  set search_path = 'public';

  select * from pg_table_def where tablename = 'foos' and schemaname = 'public';

  create temporary table temporary_events_25343
  (
   id integer not null distkey,
   name character varying(255),
   primary key (id),
   unique (name)
  ) sortkey (name);

  set search_path = '$user','public';
```

/*
    Onix CMDB - Copyright (c) 2018-2019 by www.gatblau.org

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software distributed under
    the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

    Contributors to this project, hereby assign copyright in this code to the project,
    to be licensed under the same terms as the rest of the code.
*/
DO
$$
BEGIN

/*
  find_items: find items that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_items(
    tag_param text[], -- zero (null) or more tags
    attribute_param hstore, -- zero (null) or more key->regex pair attributes
    status_param smallint, -- zero (null) or one status
    item_type_key_param character varying, -- zero (null) or one item type
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
    max_items integer default 20 -- the maximum number of items to return
  )
  RETURNS TABLE(
    id bigint,
    key character varying,
    name character varying,
    description text,
    status smallint,
    item_type_key character varying,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  item_type_id_value smallint;

BEGIN
  RETURN QUERY SELECT
    i.id,
    i.key,
    i.name,
    i.description,
    i.status,
    it.key as item_type_key,
    i.meta,
    i.tag,
    i.attribute,
    i.version,
    i.created,
    i.updated,
    i.changed_by
  FROM item i
  INNER JOIN item_type it
    ON i.item_type_id = it.id
  WHERE
  -- by item type
      (it.key = item_type_key_param OR item_type_key_param IS NULL)
  -- by status
  AND (i.status = status_param OR status_param IS NULL)
  -- by tags
  AND (i.tag @> tag_param OR tag_param IS NULL)
  -- by attributes (hstore)
  AND (i.attribute @> attribute_param OR attribute_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= i.created AND date_created_to_param > i.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > i.created) OR
      (date_created_from_param <= i.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= i.updated AND date_updated_to_param > i.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > i.updated) OR
      (date_updated_from_param <= i.updated AND date_updated_to_param IS NULL))
  LIMIT max_items;
END
$BODY$;

ALTER FUNCTION find_items(
    text[],
    hstore,
    smallint,
    character varying,
    timestamp(6) with time zone, -- created from
    timestamp(6) with time zone, -- created to
    timestamp(6) with time zone, -- updated from
    timestamp(6) with time zone, -- updated to
    integer -- max_items
  )
  OWNER TO onix;

/*
  find_links: find links that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_links(
  start_item_key_param character varying, -- zero (null) or one start item
  end_item_key_param character varying, -- zero (null) or one end item
  tag_param text[], -- zero (null) or more tags
  attribute_param hstore, -- zero (null) or more key->regex pair attributes
  link_type_key_param character varying, -- zero (null) or one link type
  date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
  date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
  date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_updated_to_param timestamp(6) with time zone -- none (null) or updated to date
)
RETURNS TABLE(
    id bigint,
    key character varying,
    link_type_key character varying,
    start_item_key character varying,
    end_item_key character varying,
    description text,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created TIMESTAMP(6) WITH TIME ZONE,
    updated timestamp(6) WITH TIME ZONE,
    changed_by CHARACTER VARYING
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  link_type_id_value smallint;

BEGIN
  RETURN QUERY SELECT
    l.id,
    l.key,
    lt.key as link_type_key,
    start_item.key AS start_item_key,
    end_item.key AS end_item_key,
    l.description,
    l.meta,
    l.tag,
    l.attribute,
    l.version,
    l.created,
    l.updated,
    l.changed_by
  FROM link l
    INNER JOIN item start_item
      ON l.start_item_id = start_item.id
    INNER JOIN item end_item
      ON l.end_item_id = end_item.id
    INNER JOIN link_type lt
      ON l.link_type_id = lt.id
  WHERE
   -- by link type
   (lt.key = link_type_key_param OR link_type_key_param IS NULL)
   -- by start item
   AND (start_item.key = start_item_key_param OR start_item_key_param IS NULL)
   -- by end item
   AND (end_item.key = end_item_key_param OR end_item_key_param IS NULL)
   -- by tags
   AND (l.tag @> tag_param OR tag_param IS NULL)
   -- by attributes (hstore)
   AND (l.attribute @> attribute_param OR attribute_param IS NULL)
   -- by created date range
   AND ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
        (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
        (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
        (date_created_from_param <= l.created AND date_created_to_param IS NULL))
   -- by updated date range
   AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
        (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
        (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
        (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_links(
  character varying,
  character varying,
  text[],
  hstore,
  character varying,
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone -- updated to
)
OWNER TO onix;

/*
  find_item_types: find item types that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_item_types(
    attr_valid_param hstore, -- zero (null) or more key->regex pair attributes
    system_param boolean, -- (null) for any or true / false
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone -- none (null) or updated to date
  )
  RETURNS TABLE(
    id integer,
    key character varying,
    name character varying,
    description text,
    attr_valid hstore,
    system boolean,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     i.id,
     i.key,
     i.name,
     i.description,
     i.attr_valid,
     i.system,
     i.version,
     i.created,
     i.updated,
     i.changed_by
  FROM item_type i
  WHERE
  -- by system flag
     (i.system = system_param OR system_param IS NULL)
  -- by attributes (hstore)
  AND (i.attr_valid @> attr_valid_param OR attr_valid_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= i.created AND date_created_to_param > i.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > i.created) OR
      (date_created_from_param <= i.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= i.updated AND date_updated_to_param > i.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > i.updated) OR
      (date_updated_from_param <= i.updated AND date_updated_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_item_types(
  hstore,
  boolean,
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone -- updated to
)
OWNER TO onix;

/*
  find_link_types: find link types that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_link_types(
    attr_valid_param hstore, -- zero (null) or more key->regex pair attributes
    system_param boolean, -- (null) for any or true / false
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone -- none (null) or updated to date
  )
  RETURNS TABLE(
    id integer,
    key character varying,
    name character varying,
    description text,
    attr_valid hstore,
    system boolean,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     l.id,
     l.key,
     l.name,
     l.description,
     l.attr_valid,
     l.system,
     l.version,
     l.created,
     l.updated,
     l.changed_by
  FROM link_type l
  WHERE
  -- by system flag
      (l.system = system_param OR system_param IS NULL)
  -- by attributes (hstore)
  AND (l.attr_valid @> attr_valid_param OR attr_valid_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
      (date_created_from_param <= l.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
      (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_link_types(
  hstore,
  boolean,
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone -- updated to
)
OWNER TO onix;

/*
  find_items_change: find change records for items that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_items_change(
  item_key_param character varying,
  date_changed_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_changed_to_param timestamp(6) with time zone -- none (null) or updated to date
)
RETURNS TABLE(
    operation char,
    changed_date timestamp(6) with time zone,
    id bigint,
    key character varying,
    name character varying,
    description text,
    status smallint,
    item_type_id integer,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
    i.operation,
    i.changed_date,
    i.id,
    i.key,
    i.name,
    i.description,
    i.status,
    i.item_type_id,
    i.meta,
    i.tag,
    i.attribute,
    i.version,
    i.created,
    i.updated,
    i.changed_by
  FROM item_change i
  WHERE i.key = item_key_param
  -- by change date range
  AND ((date_changed_from_param <= i.changed_date AND date_changed_to_param > i.changed_date) OR
      (date_changed_from_param IS NULL AND date_changed_to_param IS NULL) OR
      (date_changed_from_param IS NULL AND date_changed_to_param > i.changed_date) OR
      (date_changed_from_param <= i.changed_date AND date_changed_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_items_change(
  character varying, -- item natural key
  timestamp(6) with time zone, -- change date from
  timestamp(6) with time zone -- change date to
)
OWNER TO onix;

/*
  find_links_change: find change records for links that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_links_change(
    link_key_param character varying,
    date_changed_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_changed_to_param timestamp(6) with time zone -- none (null) or updated to date
  )
  RETURNS TABLE(
    operation char,
    changed_date timestamp(6) with time zone,
    id bigint,
    key character varying,
    description text,
    link_type_key character varying,
    start_item_key character varying,
    end_item_key character varying,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     l.operation,
     l.changed_date,
     l.id,
     l.key,
     l.description,
     lt.key as link_type_key,
     start_item.key AS start_item_key,
     end_item.key AS end_item_key,
     l.meta,
     l.tag,
     l.attribute,
     l.version,
     l.created,
     l.updated,
     l.changed_by
  FROM link_change l
    INNER JOIN item start_item
      ON l.start_item_id = start_item.id
    INNER JOIN item end_item
      ON l.end_item_id = end_item.id
    INNER JOIN link_type lt
      ON l.link_type_id = lt.id
  WHERE l.key = link_key_param
  -- by changed_date range
  AND ((date_changed_from_param <= l.changed_date AND date_changed_to_param > l.changed_date) OR
      (date_changed_from_param IS NULL AND date_changed_to_param IS NULL) OR
      (date_changed_from_param IS NULL AND date_changed_to_param > l.changed_date) OR
      (date_changed_from_param <= l.changed_date AND date_changed_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_links_change(
  character varying, -- item natural key
  timestamp(6) with time zone, -- change date from
  timestamp(6) with time zone -- change date to
)
OWNER TO onix;

/*
  get_links_from_item_count: find the number of links of a particular type that are associated with an start item.
     Can use the link attributes to filter the result.
 */
CREATE OR REPLACE FUNCTION get_links_from_item_count(
    item_key_param character varying, -- item natural key
    attribute_param hstore -- filter for links
  )
  RETURNS INTEGER
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  link_count integer;
BEGIN
  RETURN (
    SELECT COUNT(*) INTO link_count
    FROM link l
    INNER JOIN item i
       ON l.start_item_id = i.id
    WHERE i.key = item_key_param
    -- by attributes (hstore)
    AND (l.attribute @> attribute_param OR attribute_param IS NULL)
  );
END
$BODY$;

ALTER FUNCTION get_links_from_item_count(
  character varying, -- item natural key
  hstore -- filter for links
)
OWNER TO onix;

/*
  get_links_to_item_count: find the number of links of a particular type that are associated with an end item.
     Can use the link attributes to filter the result.
 */
CREATE OR REPLACE FUNCTION get_links_to_item_count(
    item_key_param character varying, -- item natural key
    attribute_param hstore -- filter for links
  )
  RETURNS INTEGER
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  link_count integer;
BEGIN
  RETURN (
    SELECT COUNT(*) INTO link_count
    FROM link l
      INNER JOIN item i
        ON l.end_item_id = i.id
    WHERE i.key = item_key_param
    -- by attributes (hstore)
    AND (l.attribute @> attribute_param OR attribute_param IS NULL)
  );
END
$BODY$;

ALTER FUNCTION get_links_to_item_count(
  character varying, -- item natural key
  hstore -- filter for links
)
OWNER TO onix;

/*
  find_link_rules: find link rules that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION find_link_rules(
  link_type_key_param character varying, -- none (null) or link type key
  start_item_type_key_param character varying, -- none (null) or start item type key
  end_item_type_key_param character varying, -- none (null) or end item type key
  system_param boolean, -- (null) for any or true / false
  date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
  date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
  date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_updated_to_param timestamp(6) with time zone -- none (null) or updated to date
)
RETURNS TABLE(
  id bigint,
  key character varying,
  name character varying,
  description text,
  link_type_key character varying,
  start_item_type_key character varying,
  end_item_type_key character varying,
  system boolean,
  version bigint,
  created timestamp(6) with time zone,
  updated timestamp(6) with time zone,
  changed_by character varying
)
LANGUAGE 'plpgsql'
COST 100
STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
      l.id,
      l.key,
      l.name,
      l.description,
      link_type.key as link_type_key,
      start_item_type.key as start_item_type_key,
      end_item_type.key as end_item_type_key,
      l.system,
      l.version,
      l.created,
      l.updated,
      l.changed_by
  FROM link_rule l
    INNER JOIN link_type link_type
      ON link_type.id = l.link_type_id
    INNER JOIN item_type start_item_type
      ON start_item_type.id = l.start_item_type_id
    INNER JOIN item_type end_item_type
      ON end_item_type.id = l.end_item_type_id
  WHERE
  -- by system flag
  (l.system = system_param OR system_param IS NULL)
  -- by link type
  AND (link_type.key = link_type_key_param OR link_type_key_param IS NULL)
  -- by start item_type key
  AND (start_item_type.key = start_item_type_key_param OR start_item_type_key_param IS NULL)
  -- by end item_type key
  AND (end_item_type.key = end_item_type_key_param OR end_item_type_key_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
      (date_created_from_param <= l.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
      (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION find_link_rules(
  character varying, -- link_type key
  character varying, -- start item_type key
  character varying, -- end item_type key
  boolean, -- system
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone -- updated to
)
OWNER TO onix;

/*
  find_child_items: returns a list of child items which are linked to the specified item.
 */
CREATE OR REPLACE FUNCTION find_child_items(
  parent_item_key_param character varying,
  link_type_key_param character varying
)
RETURNS TABLE(
  id bigint, -- id
  key character varying, -- key
  name character varying, -- name
  description text, -- description
  meta jsonb, -- meta
  tag text[], -- tag
  attribute hstore, -- attribute
  status smallint, -- status
  item_type_id integer,
  item_type_key character varying,
  version bigint,
  created timestamp(6) with time zone,
  updated timestamp(6) with time zone,
  changed_by character varying
)
LANGUAGE 'plpgsql'
COST 100
STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     i.id,
     i.key,
     i.name,
     i.description,
     i.meta,
     i.tag,
     i.attribute,
     i.status,
     i.item_type_id,
     it.key AS item_type_key,
     i.version,
     i.created,
     i.updated,
     i.changed_by
  FROM item i
  INNER JOIN link l
    ON i.id = l.end_item_id
  INNER JOIN item_type it
    ON it.id = i.item_type_id
  INNER JOIN item i2
    ON i2.id = l.start_item_id
  INNER JOIN link_type lt
    ON lt.id = l.link_type_id
  WHERE i2.key = parent_item_key_param
  AND (lt.key = link_type_key_param OR link_type_key_param IS NULL)
  ORDER BY it.key DESC;
END
$BODY$;

ALTER FUNCTION find_child_items(character varying, character varying) OWNER TO onix;

END
$$;
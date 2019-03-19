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
    ---------------------------------------------------------------------------
    -- ITEM TYPE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='item_type')
    THEN
        CREATE SEQUENCE item_type_id_seq
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            CACHE 1;

        ALTER SEQUENCE item_type_id_seq
            OWNER TO onix;

        CREATE TABLE item_type
        (
          id          INTEGER                NOT NULL DEFAULT nextval('item_type_id_seq'::regclass),
          key         CHARACTER VARYING(100) NOT NULL COLLATE pg_catalog."default",
          name        CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description TEXT COLLATE pg_catalog."default",
          attr_valid  HSTORE,
          filter      jsonb,
          meta_schema jsonb,
          version     bigint                 NOT NULL DEFAULT 1,
          created     timestamp(6) with time zone     DEFAULT CURRENT_TIMESTAMP(6),
          updated     timestamp(6) with time zone,
          changed_by  CHARACTER VARYING(50)  NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT item_type_id_pk PRIMARY KEY (id),
          CONSTRAINT item_type_key_uc UNIQUE (key),
          CONSTRAINT item_type_name_uc UNIQUE (name)
        )
        WITH (
            OIDS = FALSE
        )
        TABLESPACE pg_default;

        ALTER TABLE item_type
            OWNER to onix;

    END IF;

    ---------------------------------------------------------------------------
    -- ITEM_TYPE CHANGE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='item_type_change')
    THEN
        CREATE TABLE item_type_change
        (
          operation   CHAR(1)               NOT NULL,
          changed     TIMESTAMP             NOT NULL,
          id          INTEGER,
          key         CHARACTER VARYING(100) COLLATE pg_catalog."default",
          name        CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description TEXT COLLATE pg_catalog."default",
          attr_valid  HSTORE,
          filter      jsonb,
          meta_schema jsonb,
          version     bigint,
          created     timestamp(6) with time zone,
          updated     timestamp(6) with time zone,
          changed_by  CHARACTER VARYING(50) NOT NULL COLLATE pg_catalog."default"
        );

        ALTER TABLE item_type_change
            OWNER to onix;

        CREATE OR REPLACE FUNCTION change_item_type() RETURNS TRIGGER AS $item_type_change$
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                INSERT INTO item_type_change SELECT 'D', now(), OLD.*;
                RETURN OLD;
            ELSIF (TG_OP = 'UPDATE') THEN
                INSERT INTO item_type_change SELECT 'U', now(), NEW.*;
                RETURN NEW;
            ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO item_type_change SELECT 'I', now(), NEW.*;
                RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
        END;
        $item_type_change$ LANGUAGE plpgsql;

        CREATE TRIGGER item_type_change
            AFTER INSERT OR UPDATE OR DELETE ON item_type
            FOR EACH ROW EXECUTE PROCEDURE change_item_type();

    END IF;

    ---------------------------------------------------------------------------
    -- ITEM
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='item')
    THEN
        CREATE SEQUENCE item_id_seq
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            CACHE 1;

        ALTER SEQUENCE item_id_seq
            OWNER TO onix;

        CREATE TABLE item
        (
          id           bigint                                              NOT NULL DEFAULT nextval('item_id_seq'::regclass),
          key          character varying(100) COLLATE pg_catalog."default" NOT NULL,
          name         character varying(200) COLLATE pg_catalog."default",
          description  text COLLATE pg_catalog."default",
          meta         jsonb,
          tag          text[] COLLATE pg_catalog."default",
          attribute    hstore,
          status       smallint                                                     DEFAULT 0,
          item_type_id integer,
          version      bigint                                              NOT NULL DEFAULT 1,
          created      timestamp(6) with time zone                                  DEFAULT CURRENT_TIMESTAMP(6),
          updated      timestamp(6) with time zone,
          changed_by   CHARACTER VARYING(100)                              NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT item_id_pk PRIMARY KEY (id),
          CONSTRAINT item_key_uc UNIQUE (key),
          CONSTRAINT item_item_type_id_fk FOREIGN KEY (item_type_id)
            REFERENCES item_type (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
        )
        WITH (
            OIDS = FALSE
        )
        TABLESPACE pg_default;

        ALTER TABLE item
            OWNER to onix;

        CREATE UNIQUE INDEX item_id_uix
            ON item
            (id)
            TABLESPACE pg_default;

        CREATE INDEX item_tag_ix
            ON item USING gin
            (tag COLLATE pg_catalog."default")
            TABLESPACE pg_default;

        CREATE INDEX item_attribute_ix
            ON item USING gin
            (attribute)
            TABLESPACE pg_default;

        CREATE INDEX fki_item_item_type_id_fk
            ON item USING btree (item_type_id)
            TABLESPACE pg_default;
	  END IF;

    ---------------------------------------------------------------------------
    -- ITEM CHANGE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='item_change')
    THEN
        CREATE TABLE item_change
        (
          operation    CHAR(1)                     NOT NULL,
          changed      timestamp(6) with time zone NOT NULL,
          id           bigint,
          key          CHARACTER VARYING(100) COLLATE pg_catalog."default",
          name         CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description  text COLLATE pg_catalog."default",
          meta         jsonb,
          tag          text[] COLLATE pg_catalog."default",
          attribute    hstore,
          status       SMALLINT,
          item_type_id INTEGER,
          version      bigint,
          created      timestamp(6) with time zone,
          updated      timestamp(6) with time zone,
          changed_by   CHARACTER VARYING(100)      NOT NULL COLLATE pg_catalog."default"
        );

        ALTER TABLE item_change
            OWNER to onix;

        CREATE OR REPLACE FUNCTION change_item() RETURNS TRIGGER AS $item_change$
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                INSERT INTO item_change SELECT 'D', now(), OLD.*;
                RETURN OLD;
            ELSIF (TG_OP = 'UPDATE') THEN
                INSERT INTO item_change SELECT 'U', now(), NEW.*;
                RETURN NEW;
            ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO item_change SELECT 'I', now(), NEW.*;
                RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
        END;
        $item_change$ LANGUAGE plpgsql;

        CREATE TRIGGER item_change
            AFTER INSERT OR UPDATE OR DELETE ON item
            FOR EACH ROW EXECUTE PROCEDURE change_item();

    END IF;

    ---------------------------------------------------------------------------
    -- LINK TYPE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link_type')
    THEN
        CREATE SEQUENCE link_type_id_seq
        INCREMENT 1
        START 1
        MINVALUE 1
        MAXVALUE 9223372036854775807
        CACHE 1;

        ALTER SEQUENCE link_type_id_seq
        OWNER TO onix;

        CREATE TABLE link_type
        (
          id          INTEGER                NOT NULL DEFAULT nextval('link_type_id_seq'::regclass),
          key         CHARACTER VARYING(100) NOT NULL COLLATE pg_catalog."default",
          name        CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description TEXT COLLATE pg_catalog."default",
          attr_valid  HSTORE,
          meta_schema jsonb,
          version     bigint                 NOT NULL DEFAULT 1,
          created     timestamp(6) with time zone     DEFAULT CURRENT_TIMESTAMP(6),
          updated     timestamp(6) with time zone,
          changed_by  CHARACTER VARYING(50)  NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT link_type_id_pk PRIMARY KEY (id),
          CONSTRAINT link_type_key_uc UNIQUE (key),
          CONSTRAINT link_type_name_uc UNIQUE (name)
        )
        WITH (OIDS = FALSE) TABLESPACE pg_default;

        ALTER TABLE link_type OWNER to onix;

    END IF;

    ---------------------------------------------------------------------------
    -- LINK_TYPE CHANGE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link_type_change')
    THEN
        CREATE TABLE link_type_change
        (
          operation   CHAR(1)               NOT NULL,
          changed     TIMESTAMP             NOT NULL,
          id          INTEGER,
          key         CHARACTER VARYING(100) COLLATE pg_catalog."default",
          name        CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description TEXT COLLATE pg_catalog."default",
          attr_valid  HSTORE,
          meta_schema jsonb,
          version     bigint,
          created     timestamp(6) with time zone,
          updated     timestamp(6) with time zone,
          changed_by  CHARACTER VARYING(50) NOT NULL COLLATE pg_catalog."default"
        );

        ALTER TABLE link_type_change
            OWNER to onix;

        CREATE OR REPLACE FUNCTION change_link_type() RETURNS TRIGGER AS $link_type_change$
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                INSERT INTO link_type_change SELECT 'D', now(), OLD.*;
                RETURN OLD;
            ELSIF (TG_OP = 'UPDATE') THEN
                INSERT INTO link_type_change SELECT 'U', now(), NEW.*;
                RETURN NEW;
            ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO link_type_change SELECT 'I', now(), NEW.*;
                RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
        END;
        $link_type_change$ LANGUAGE plpgsql;

        CREATE TRIGGER link_type_change
            AFTER INSERT OR UPDATE OR DELETE ON link_type
            FOR EACH ROW EXECUTE PROCEDURE change_link_type();

    END IF;

    ---------------------------------------------------------------------------
    -- LINK
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link')
	  THEN
        CREATE SEQUENCE link_id_seq
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            CACHE 1;

        ALTER SEQUENCE link_id_seq
            OWNER TO onix;

        CREATE TABLE link
        (
          id            bigint                                              NOT NULL DEFAULT nextval('link_id_seq'::regclass),
          key           CHARACTER VARYING(200) COLLATE pg_catalog."default" NOT NULL,
          link_type_id  integer,
          start_item_id bigint                                              NOT NULL,
          end_item_id   bigint                                              NOT NULL,
          description   text COLLATE pg_catalog."default",
          meta          jsonb,
          tag           text[] COLLATE pg_catalog."default",
          attribute     hstore,
          version       bigint                                              NOT NULL DEFAULT 1,
          created       TIMESTAMP(6) WITH TIME ZONE                                  DEFAULT CURRENT_TIMESTAMP(6),
          updated       timestamp(6) WITH TIME ZONE,
          changed_by    CHARACTER VARYING(100)                              NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT link_id_pk PRIMARY KEY (id),
          CONSTRAINT link_key_uc UNIQUE (key),
          CONSTRAINT link_link_type_id_fk FOREIGN KEY (link_type_id)
            REFERENCES link_type (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
          CONSTRAINT link_end_item_id_fk FOREIGN KEY (end_item_id)
            REFERENCES item (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
          CONSTRAINT link_start_item_id_fk FOREIGN KEY (start_item_id)
            REFERENCES item (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
        )
        WITH (
            OIDS = FALSE
        )
        TABLESPACE pg_default;

        ALTER TABLE link
            OWNER to onix;

        CREATE INDEX fki_link_link_type_id_fk
            ON link USING btree (link_type_id)
            TABLESPACE pg_default;

        CREATE INDEX fki_link_start_item_id_fk
            ON link USING btree
            (start_item_id)
            TABLESPACE pg_default;

        CREATE INDEX fki_link_end_item_id_fk
            ON link USING btree
            (end_item_id)
            TABLESPACE pg_default;

        CREATE INDEX link_tag_ix
        ON link USING gin
        (tag COLLATE pg_catalog."default")
        TABLESPACE pg_default;

        CREATE INDEX link_attribute_ix
        ON link USING gin
        (attribute)
        TABLESPACE pg_default;

    END IF;

    ---------------------------------------------------------------------------
    -- LINK CHANGE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link_change')
    THEN
        CREATE TABLE link_change
        (
          operation     CHAR(1)                     NOT NULL,
          changed       timestamp(6) with time zone NOT NULL,
          id            bigint,
          key           CHARACTER VARYING(200) COLLATE pg_catalog."default",
          link_type_id  integer,
          start_item_id bigint,
          end_item_id   bigint,
          description   text COLLATE pg_catalog."default",
          meta          jsonb,
          tag           text[] COLLATE pg_catalog."default",
          attribute     hstore,
          version       bigint,
          created       TIMESTAMP(6) with time zone,
          updated       TIMESTAMP(6) with time zone,
          changed_by    CHARACTER VARYING(100)      NOT NULL COLLATE pg_catalog."default"
        );

        ALTER TABLE link_change
            OWNER to onix;

        CREATE OR REPLACE FUNCTION change_link() RETURNS TRIGGER AS $link_change$
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                INSERT INTO link_change SELECT 'D', now(), OLD.*;
                RETURN OLD;
            ELSIF (TG_OP = 'UPDATE') THEN
                INSERT INTO link_change SELECT 'U', now(), NEW.*;
                RETURN NEW;
            ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO link_change SELECT 'I', now(), NEW.*;
                RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
        END;
        $link_change$ LANGUAGE plpgsql;

        CREATE TRIGGER link_change
            AFTER INSERT OR UPDATE OR DELETE ON link
            FOR EACH ROW EXECUTE PROCEDURE change_link();

    END IF;

    ---------------------------------------------------------------------------
    -- LINK_RULE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link_rule')
    THEN
        CREATE SEQUENCE link_rule_id_seq
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            CACHE 1;

        ALTER SEQUENCE link_rule_id_seq
            OWNER TO onix;

        CREATE TABLE link_rule
        (
          id                 bigint                                              NOT NULL DEFAULT nextval('link_rule_id_seq'::regclass),
          key                character varying(300) COLLATE pg_catalog."default" NOT NULL,
          name               character varying(200) COLLATE pg_catalog."default",
          description        text COLLATE pg_catalog."default",
          link_type_id       integer                                             NOT NULL,
          start_item_type_id integer                                             NOT NULL,
          end_item_type_id   integer                                             NOT NULL,
          version            bigint                                              NOT NULL DEFAULT 1,
          created            timestamp(6) with time zone                                  DEFAULT CURRENT_TIMESTAMP(6),
          updated            timestamp(6) with time zone,
          changed_by         CHARACTER VARYING(100)                              NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT link_rule_id_pk PRIMARY KEY (id),
          CONSTRAINT link_rule_key_uc UNIQUE (key),
          CONSTRAINT link_rule_start_item_type_id_fk FOREIGN KEY (start_item_type_id)
            REFERENCES item_type (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
          CONSTRAINT link_rule_end_item_type_id_fk FOREIGN KEY (end_item_type_id)
            REFERENCES item_type (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
          CONSTRAINT link_rule_link_type_id_fk FOREIGN KEY (link_type_id)
            REFERENCES link_type (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
        )
        WITH (OIDS = FALSE)
        TABLESPACE pg_default;

        ALTER TABLE link_rule
            OWNER to onix;

        CREATE UNIQUE INDEX link_rule_id_uix
            ON link_rule
            (id)
            TABLESPACE pg_default;

        CREATE INDEX fki_link_rule_link_type_id_fk
            ON link_rule USING btree (link_type_id)
            TABLESPACE pg_default;

        CREATE INDEX fki_link_rule_start_item_type_id_fk
            ON link_rule USING btree (start_item_type_id)
            TABLESPACE pg_default;

        CREATE INDEX fki_link_rule_end_item_type_id_fk
            ON link_rule USING btree (end_item_type_id)
            TABLESPACE pg_default;

    END IF;

    ---------------------------------------------------------------------------
    -- LINK_RULE CHANGE
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='link_rule_change')
    THEN
        CREATE TABLE link_rule_change
        (
          operation          CHAR(1),
          changed            timestamp(6) with time zone,
          id                 bigint,
          key                character varying(300),
          name               character varying(200),
          description        text,
          link_type_id       integer,
          start_item_type_id integer,
          end_item_type_id   integer,
          version            bigint,
          created            timestamp(6) with time zone,
          updated            timestamp(6) with time zone,
          changed_by         CHARACTER VARYING(100)
        );

        ALTER TABLE link_rule_change
            OWNER to onix;

        CREATE OR REPLACE FUNCTION change_link_rule() RETURNS TRIGGER AS $link_rule_change$
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                INSERT INTO link_rule_change SELECT 'D', now(), OLD.*;
                RETURN OLD;
            ELSIF (TG_OP = 'UPDATE') THEN
                INSERT INTO link_rule_change SELECT 'U', now(), NEW.*;
                RETURN NEW;
            ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO link_rule_change SELECT 'I', now(), NEW.*;
                RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
        END;
        $link_rule_change$
        LANGUAGE plpgsql;

        CREATE TRIGGER link_rule_change
            AFTER INSERT OR UPDATE OR DELETE ON link_rule
            FOR EACH ROW EXECUTE PROCEDURE change_link_rule();

    END IF;

    ---------------------------------------------------------------------------
    -- TAG
    ---------------------------------------------------------------------------
    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='tag')
    THEN
        CREATE SEQUENCE tag_id_seq
        INCREMENT 1
        START 1
        MINVALUE 1
        MAXVALUE 9223372036854775807
        CACHE 1;

        ALTER SEQUENCE tag_id_seq
            OWNER TO onix;

        CREATE TABLE tag
        (
          id            INTEGER                NOT NULL DEFAULT nextval('tag_id_seq'::regclass),
          label         CHARACTER VARYING(50)  NOT NULL COLLATE pg_catalog."default",
          root_item_key CHARACTER VARYING(100) NOT NULL COLLATE pg_catalog."default",
          name          CHARACTER VARYING(200) COLLATE pg_catalog."default",
          description   TEXT COLLATE pg_catalog."default",
          item_data     HSTORE,
          link_data     HSTORE,
          version       BIGINT,
          created       timestamp(6) with time zone     DEFAULT CURRENT_TIMESTAMP(6),
          updated       timestamp(6) with time zone,
          changed_by    CHARACTER VARYING(50)  NOT NULL COLLATE pg_catalog."default",
          CONSTRAINT tag_id_pk PRIMARY KEY (id),
          CONSTRAINT label_root_item_key_uc UNIQUE (label, root_item_key),
          CONSTRAINT root_item_key_item_data_link_data_uc UNIQUE (root_item_key, item_data, link_data),
          CONSTRAINT tag_root_item_key_fk FOREIGN KEY (root_item_key)
            REFERENCES item (key) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
        )
        WITH (
            OIDS = FALSE
        )
        TABLESPACE pg_default;

        ALTER TABLE tag
            OWNER to onix;

        CREATE INDEX fki_tag_root_item_key_fk
            ON tag USING btree (root_item_key)
            TABLESPACE pg_default;
    END IF;

  ---------------------------------------------------------------------------
  -- TAG CHANGE
  ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname='tag_change')
  THEN
    CREATE TABLE tag_change
    (
      operation     CHAR(1),
      changed       timestamp(6) with time zone,
      id            INTEGER,
      label         CHARACTER VARYING(50),
      root_item_key CHARACTER VARYING(100),
      name          CHARACTER VARYING(200),
      description   TEXT,
      item_data     HSTORE,
      link_data     HSTORE,
      version       BIGINT,
      created       timestamp(6) with time zone,
      updated       timestamp(6) with time zone,
      changed_by    CHARACTER VARYING(50)
    );

    ALTER TABLE tag_change
      OWNER to onix;

    CREATE OR REPLACE FUNCTION change_tag() RETURNS TRIGGER AS $tag_change$
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        INSERT INTO tag_change SELECT 'D', now(), OLD.*;
        RETURN OLD;
      ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO tag_change SELECT 'U', now(), NEW.*;
        RETURN NEW;
      ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO tag_change SELECT 'I', now(), NEW.*;
        RETURN NEW;
      END IF;
      RETURN NULL; -- result is ignored since this is an AFTER trigger
      END;
    $tag_change$
    LANGUAGE plpgsql;

    CREATE TRIGGER tag_change
      AFTER INSERT OR UPDATE OR DELETE ON tag
      FOR EACH ROW EXECUTE PROCEDURE change_tag();

END IF;

END;
$$

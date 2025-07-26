-- config_model.monitoring_policies definition

-- Drop table

-- DROP TABLE config_model.monitoring_policies;

CREATE TABLE config_model.monitoring_policies (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" text NOT NULL,
	max_retries int4 DEFAULT 1 NOT NULL,
	backoff int4 NOT NULL,
	create_user varchar(50) DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp NULL,
	CONSTRAINT newtable_pk PRIMARY KEY (id)
);
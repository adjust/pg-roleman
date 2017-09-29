EXTENSION = roleman
DATA = extension/*

ifeq ($(PG_CONFIG),)
PG_CONFIG = pg_config
endif
REGRESS = definitions upgrade
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

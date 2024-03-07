##############################PgSQL template################################
FROM postgres:latest
############################################################################

#############################install packages###############################
# RUN apt update                          \
#         && apt -y install               \
#                 postgresql-postgis      \
#                 postgresql-pgrouting    \
#         && rm -rf /var/lib/apt/lists/*
############################################################################

##############################set up locales################################
RUN sed -i '/# C.UTF-8 UTF-8/c C.UTF-8 UTF-8' /etc/locale.gen
RUN sed -i '/# en_US.UTF-8 UTF-8/c en_US.UTF-8 UTF-8' /etc/locale.gen
RUN sed -i '/# ru_RU.CP1251 CP1251/c ru_RU.CP1251 CP1251' /etc/locale.gen
RUN sed -i '/# ru_RU.UTF-8 UTF-8/c ru_RU.UTF-8 UTF-8' /etc/locale.gen
RUN locale-gen
############################################################################

###############################PgSQL config#################################
#Extend postgresql config
#RUN echo \
#'\n\
#example \n\
#' > /etc/postgresql/postgresql.conf
# select * FROM pg_extension; \n\
############################################################################

##########################Install PgSQL extensions##########################
# RUN echo \
# '\
# #!/bin/sh \n\
# \n\
# # You could probably do this fancier and have an array of extensions \n\
# # to create, but this is mostly an illustration of what can be done \n\
# \n\
# psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<EOF \n\
# create extension pg_trgm; \n\
# create extension pg_stat_statements; \n\
# create extension postgis; \n\
# select * FROM pg_extension; \n\
# EOF' > /docker-entrypoint-initdb.d/load-extensions.sh
############################################################################
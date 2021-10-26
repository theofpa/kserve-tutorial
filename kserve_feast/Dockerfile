FROM tedhtchang/feast-feature-server:latest

COPY feature_store.yaml /mnt/feature_store.yaml

WORKDIR /mnt

RUN feast init
#RUN feast alpha enable python_feature_server
RUN feast apply
RUN feast materialize-incremental $(date +%Y-%m-%d)

EXPOSE 6566
ENTRYPOINT ["feast"]
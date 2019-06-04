FROM ashumehra/websphere-liberty:openj9-jre

RUN rm -rf /opt/ibm/wlp/usr/servers/defaultServer/server.xml
ADD server.xml /opt/ibm/wlp/usr/servers/defaultServer/server.xml

RUN installUtility install --acceptLicense defaultServer \
    && rm -rf /opt/ibm/wlp/usr/servers/defaultServer/workarea

ADD ./build/libs/*.war /opt/ibm/wlp/usr/servers/defaultServer/apps

EXPOSE 8080

ENV MONGO_HOST=acmeair-db
ENV MONGO_DBNAME=acmeair

CMD ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]

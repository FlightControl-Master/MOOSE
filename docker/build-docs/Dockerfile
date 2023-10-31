FROM nickblah/lua:5.1.5-luarocks-ubuntu

RUN apt-get -qq update
RUN apt-get -qq install tree
RUN apt-get -qq install build-essential
RUN apt-get -qq install git
RUN luarocks install markdown 0.32-2
RUN luarocks install penlight 1.11.0-1
RUN luarocks install metalua-compiler 0.7.3-1
RUN luarocks install metalua-parser 0.7.3-2
RUN luarocks install checks
COPY start.sh /start.sh
RUN chmod +x /start.sh

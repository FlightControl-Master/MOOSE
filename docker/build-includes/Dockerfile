FROM nickblah/lua:5.3-luarocks-ubuntu

RUN apt-get -qq update
RUN apt-get -qq install tree
RUN apt-get -qq install build-essential
RUN apt-get -qq install git
RUN luarocks install luasrcdiet
RUN luarocks install luacheck
COPY start.sh /start.sh
RUN chmod +x /start.sh

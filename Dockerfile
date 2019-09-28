FROM arm32v7/python:2.7-stretch
EXPOSE 5000
LABEL maintainer "gaetancollaud@gmail.com"

ENV CURA_VERSION=15.04.6
ARG tag=master

WORKDIR /opt/octoprint

# In case of alpine
#RUN apk update && apk upgrade \
#    && apk add --no-cache bash git openssh gcc\
#		&& pip install virtualenv \
#		&& rm -rf /var/cache/apk/*

#install ffmpeg
RUN cd /tmp \
  && wget -O ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-armhf-static.tar.xz \
	&& mkdir -p /opt/ffmpeg \
	&& tar xvf ffmpeg.tar.xz -C /opt/ffmpeg --strip-components=1 \
  && rm -Rf /tmp/*

#install Cura
RUN cd /tmp \
  && wget https://github.com/Ultimaker/CuraEngine/archive/${CURA_VERSION}.tar.gz \
  && tar -zxf ${CURA_VERSION}.tar.gz \
	&& cd CuraEngine-${CURA_VERSION} \
	&& mkdir build \
	&& make \
	&& mv -f ./build /opt/cura/ \
  && rm -Rf /tmp/*

#Create an octoprint user
RUN useradd -ms /bin/bash octoprint && adduser octoprint dialout
RUN chown octoprint:octoprint /opt/octoprint

#To support GPIO
RUN pip install --upgrade RPi.GPIO

#To control GPIO with octoprint user in docker container
RUN apt-get update && apt-get install -y sudo
RUN echo "octoprint ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010_octoprint-nopasswd
RUN chmod 0440 /etc/sudoers.d/010_octoprint-nopasswd

# Not worked even octoprint user is added to gpio group
#RUN groupadd gpio
#RUN usermod -a -G gpio octoprint
#RUN grep gpio /etc/group
#RUN chown root.gpio /dev/gpiomem
#RUN chmod g+rw /dev/gpiomem

USER octoprint
#This fixes issues with the volume command setting wrong permissions
RUN mkdir /home/octoprint/.octoprint

#Install Octoprint
RUN git clone --branch $tag https://github.com/foosel/OctoPrint.git /opt/octoprint \
  && virtualenv venv \
	&& ./venv/bin/python setup.py install

VOLUME /home/octoprint/.octoprint

CMD ["/opt/octoprint/venv/bin/octoprint", "serve"]

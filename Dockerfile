FROM jinaai/jina

RUN apt-get update && apt-get install -y jq curl git

RUN pip install docker

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
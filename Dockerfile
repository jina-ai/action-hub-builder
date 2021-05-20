FROM jinaai/jina:1.2.3

RUN apt-get update && apt-get install -y jq curl

RUN pip install docker

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

FROM jinaai/jina:latest

RUN apt-get update && apt-get install -y jq curl

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
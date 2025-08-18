FROM glitchtip/glitchtip:v5.1.0

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
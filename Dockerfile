FROM glitchtip/glitchtip:6.2.6

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

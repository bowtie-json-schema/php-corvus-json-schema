# The extension's builds, as released (src-php in Corvus.JsonSchema). Its version is this tag, which Dependabot keeps
# up to date.
FROM ghcr.io/corvus-dotnet/corvus-json-schema-php:0.1.4 AS corvus

FROM php:8.5-cli-alpine
WORKDIR /usr/src/harness
# The build of the extension for this PHP: its minor version, thread safety, architecture and musl. It is the archive
# PIE would install.
RUN --mount=type=bind,from=corvus,source=/corvus-json-schema,target=/tmp/corvus \
    apk add --no-cache --virtual .fetch unzip \
 && name="php_corvus_json_schema-*_php$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')-$(uname -m | sed 's/aarch64/arm64/')-linux-musl$(php -r 'echo PHP_ZTS ? "-zts" : "";').zip" \
 && set -- /tmp/corvus/$name \
 && [ "$#" -eq 1 ] && [ -f "$1" ] \
 && unzip -q "$1" -d /tmp/extension \
 && cp /tmp/extension/corvus_json_schema.so "$(php-config --extension-dir)/" \
 && docker-php-ext-enable corvus_json_schema \
 && rm -rf /tmp/extension \
 && apk del .fetch \
 && php -r 'exit(extension_loaded("corvus_json_schema") ? 0 : 1);'
COPY bowtie_corvus_json_schema.php .
# No memory limit: some cases build large values.
CMD ["php", "-d", "memory_limit=-1", "bowtie_corvus_json_schema.php"]

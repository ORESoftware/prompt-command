ARG base
FROM $base

COPY . .

ENTRYPOINT ["node","test.js"]
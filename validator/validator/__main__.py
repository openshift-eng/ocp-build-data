import sys

from . import format, schema


def main():
    file = sys.argv[1]

    (parsed, err) = format.validate(open(file).read())
    if err:
        print('{} is not a valid YAML.'.format(file), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)

    (_, err) = schema.validate(parsed)
    if err:
        print('{} schema is invalid.'.format(file), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)


if __name__ == '__main__':
    main()

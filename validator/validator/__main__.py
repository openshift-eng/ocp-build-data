from __future__ import print_function
import sys

from . import format, distgit_repo
from .schema import image_schema


def main():
    filename = sys.argv[1]

    (parsed, err) = format.validate(open(filename).read())
    if err:
        print('{} is not a valid YAML.'.format(filename), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)

    (_, err) = image_schema.validate(parsed)
    if err:
        print('{} schema is invalid.'.format(filename), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)

    (repo_url, err) = distgit_repo.validate(filename, parsed)
    if err:
        print('{} is not reacheable.'.format(repo_url), file=sys.stderr)
        print('Returned error: {}.'.format(err, file=sys.stderr))
        exit(1)


if __name__ == '__main__':
    main()

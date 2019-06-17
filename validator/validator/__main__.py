from __future__ import print_function
import sys

from . import format, schema, distgit_repo


def main():
    filename = sys.argv[1]

    (parsed, err) = format.validate(open(filename).read())
    if err:
        print('{} is not a valid YAML.'.format(filename), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)

    (kind, err) = schema.validate(filename, parsed)
    if err:
        print('{} schema mismatch: {}'.format(kind, filename), file=sys.stderr)
        print('Returned error: {}.'.format(err), file=sys.stderr)
        exit(1)

    (repo_url, err) = distgit_repo.validate(filename, parsed, kind)
    if err:
        print('{} is not reacheable.'.format(repo_url), file=sys.stderr)
        print('Returned error: {}.'.format(err, file=sys.stderr))
        exit(1)


if __name__ == '__main__':
    main()

import requests


def validate(filename, data, kind):
    endpoint = _get_cgit_endpoint()
    namespace = _get_namespace(data, kind)
    repo = _get_repo_name(filename)

    url = '{}/{}/{}'.format(endpoint, namespace, repo)

    try:
        response = requests.head(url)
        err = _map_status_code_to_err(response.status_code)
    except requests.exceptions.ConnectionError:
        err = ('This tool must run from a network '
               'with access to {}'.format(_get_cgit_endpoint()))

    return (url, err)


def _get_cgit_endpoint():
    # @TODO: fetch value from group.yml
    return 'http://pkgs.devel.redhat.com/cgit'


def _get_namespace(data, kind):
    # @TODO: check correct logic on doozer
    if 'distgit' in data and 'namespace' in data['distgit']:
        return data['distgit']['namespace']
    return 'containers' if kind == 'image' else 'rpms'


def _get_repo_name(filename):
    # @TODO: check correct logic on doozer
    return (filename
            .split('/')[-1]
            .replace('.yml', '')
            .replace('.apb', '')
            .replace('.container', ''))


def _map_status_code_to_err(status_code):
    if status_code == 200:
        return None

    if status_code == 404:
        return '\n'.join([
            'Corresponding DistGit repo was not found.',
            ('If you didn\'t request a DistGit repo yet, please do so: '
             'https://mojo.redhat.com/docs/DOC-1168290'),
            ('But if you already obtained one, make sure its name matches '
             'the YAML filename')])

    return status_code

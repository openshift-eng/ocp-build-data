from schema import Schema, Optional, Use, And, Or, SchemaError

valid_arches = ['x86_64']
valid_modification_commands = [
    'update-console-sources',
]


def github_repo_exists(repo):
    # @TODO
    return True


image_schema = Schema({
    Optional('arches'): valid_arches,
    Optional('base_only'): True,
    Optional('config'): 'wip',
    Optional('container_yaml'): {
        'go': {
            'modules': [{
                'module': And(str, len),
                Optional('path'): str,
            }],
        },
    },
    Optional('content'): {
        'source': {
            Optional('alias'): 'ose',
            Optional('dockerfile'): And(str, len),
            Optional('git'): {
                'branch': {
                    Optional('fallback'): And(str, len),
                    'target': And(str, len),
                },
                'url': And(Use(str), github_repo_exists),
            },
            Optional('modifications'): [{
                'action': And(str, len),
                Optional('command'): [Or(*valid_modification_commands)],
                Optional('match'): And(str, len),
                Optional('replacement'): And(str, len),
            }],
            Optional('path'): str,
        },
    },
    Optional('dependents'): [And(str, len)],
    Optional('distgit'): {
        Or('namespace', 'component'): And(str, len),
    },
    Optional('enabled_repos'): [And(str, len)],
    'from': {
        Optional('builder'): [{Or('stream', 'image', 'member'): Use(str)}],
        Optional('image'): And(str, len),
        Optional('stream'): And(str, len),
        Optional('member'): And(str, len),
    },
    Optional('labels'): {
        Optional('License'): And(str, len),
        Optional('io.k8s.description'): And(str, len),
        Optional('io.k8s.display-name'): And(str, len),
        Optional('io.openshift.tags'): And(str, len),
        Optional('vendor'): And(str, len),
    },
    Optional('mode'): And(str, len),
    'name': And(str, len),
    Optional('odcs'): {
        'packages': {
            'exclude': [And(str, len)],
            'mode': 'auto',
        },
    },
    Optional('no_oit_comments'): bool,
    Optional('owners'): [And(str, len)],
    Optional('push'): {
        'repos': [And(str, len)],
    },
    Optional('required'): bool,
    Optional('update-csv'): {
        'manifests-dir': And(str, len),
        'registry': And(str, len),
    },
    Optional('wait_for'): And(str, len),
})


def validate(data):
    try:
        return (image_schema.validate(data), None)
    except SchemaError as err:
        return (None, '{}'.format(err))

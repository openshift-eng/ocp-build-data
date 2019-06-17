from schema import Schema, Optional, Use, And, Or, Regex, SchemaError

valid_arches = [
    'x86_64',
]
valid_modification_actions = [
    'command',
    'replace',
]
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
            'modules': [
                {
                    'module': And(str, len),
                    Optional('path'): str,
                },
            ],
        },
    },
    Optional('content'): {
        'source': {
            Optional('alias'): And(str, len),
            Optional('dockerfile'): And(str, len),
            Optional('git'): {
                'branch': {
                    Optional('fallback'): And(str, len),
                    'target': And(str, len),
                },
                'url': And(Use(str), github_repo_exists),
            },
            Optional('modifications'): [{
                'action': Or(*valid_modification_actions),
                Optional('command'): [
                    Or(*valid_modification_commands),
                ],
                Optional('match'): And(str, len),
                Optional('replacement'): And(str, len),
            }],
            Optional('path'): str,
        },
    },
    Optional('dependents'): [
        And(str, len)
    ],
    Optional('distgit'): {
        Optional('namespace'): Or('rpms', 'apbs', 'containers'),
        Optional('component'): And(str, len),
        Optional('branch'): And(str, len),
    },
    Optional('enabled_repos'): [
        And(str, len),
    ],
    'from': {
        Optional('builder'): [
            {
                Optional('stream'): Or(Regex(r'^golang'),
                                       Regex(r'^ruby'),
                                       'rhel'),
                Optional('member'): And(str, len),
                Optional('image'): And(str, len),
            },
        ],
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
            'exclude': [
                And(str, len),
            ],
            'mode': 'auto',
        },
    },
    Optional('no_oit_comments'): bool,
    Optional('owners'): [
        And(str, len),
    ],
    Optional('push'): {
        'repos': [
            And(str, len),
        ],
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
        image_schema.validate(data)
    except SchemaError as err:
        return '{}'.format(err)

import yaml


def validate(contents):
    try:
        return (yaml.safe_load(contents), None)
    except Exception as err:
        return (None, '{}'.format(err.problem))

from . import image_schema, rpm_schema


def validate(filename, data):
    if '/images/' in filename:
        return ('Image', image_schema.validate(data))

    if '/rpms/' in filename:
        return ('RPM', rpm_schema.validate(data))

    err = '\n'.join([
        'Could not determine a schema',
        'Supported schemas: image, rpm',
        'Make sure the file is placed in either dir "images" or "rpms"'])
    return ('???', err)

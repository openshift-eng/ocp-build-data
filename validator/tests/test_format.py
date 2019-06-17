import unittest

from validator import format


class TestFormat(unittest.TestCase):

    def test_invalid_yaml(self):
        yaml = """
        key: value
        - item#1
        - item#2
        """

        expected = (None, 'expected <block end>, but found \'-\'')
        actual = format.validate(yaml)

        self.assertEqual(expected, actual)

    def test_valid_yaml(self):
        yaml = """
        key: &my_list
          - 1
          - 2
          - '3'
        obj:
          lst: *my_list
        """

        expected = ({'key': [1, 2, '3'], 'obj': {'lst': [1, 2, '3']}}, None)
        actual = format.validate(yaml)

        self.assertEqual(expected, actual)

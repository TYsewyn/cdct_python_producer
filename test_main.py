from unittest import TestCase
from main import hello_world


class Test(TestCase):
    def test_hello_world(self):
        self.assertEqual(hello_world(), 'Hello, World!', 'wrong response')

import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch

import azure.functions as func


APP_PATH = Path(__file__).resolve().parents[1] / "src" / "function_app.py"
spec = importlib.util.spec_from_file_location("flex_function_app", APP_PATH)
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


class FunctionAppTests(unittest.TestCase):
    def test_hello_and_function_key_responses(self):
        request = func.HttpRequest(method="GET", url="http://localhost/api/hello", params={"name": "Ada"}, body=b"")
        self.assertEqual(app.hello_world_http(request).get_body(), b"Hello, Ada!")
        self.assertEqual(app.hello_world_http_with_function_key(request).get_body(), b"Hello, Ada!")

    @patch.dict(os.environ, {"STORAGE_ACCOUNT_BLOB_ENDPOINT": "https://example.blob.core.windows.net/", "STORAGE_CONTAINER_NAME": "deploymentpackage"})
    @patch.object(app, "ManagedIdentityCredential")
    @patch.object(app, "BlobServiceClient")
    def test_storage_reads_container_properties(self, client_class, credential_class):
        request = func.HttpRequest(method="GET", url="http://localhost/api/storage-check", body=b"")
        response = app.storage_check(request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.get_body()), {"status": "ok", "container": "deploymentpackage"})
        client_class.assert_called_once_with(
            account_url="https://example.blob.core.windows.net/", credential=credential_class.return_value
        )
        client_class.return_value.get_container_client.assert_called_once_with("deploymentpackage")
        client_class.return_value.get_container_client.return_value.get_container_properties.assert_called_once_with()

    @patch.dict(os.environ, {"STORAGE_ACCOUNT_BLOB_ENDPOINT": "https://example.blob.core.windows.net/", "STORAGE_CONTAINER_NAME": "deploymentpackage"})
    @patch.object(app, "ManagedIdentityCredential")
    @patch.object(app, "BlobServiceClient")
    def test_storage_failure_does_not_expose_details(self, client_class, _credential_class):
        client_class.return_value.get_container_client.return_value.get_container_properties.side_effect = RuntimeError("secret")
        request = func.HttpRequest(method="GET", url="http://localhost/api/storage-check", body=b"")
        with self.assertLogs(level="ERROR"):
            response = app.storage_check(request)
        self.assertEqual(response.status_code, 503)
        self.assertNotIn(b"secret", response.get_body())

    def test_timer_marker(self):
        with self.assertLogs(level="INFO") as messages:
            app.hello_world_timer(MagicMock(past_due=False))
        self.assertIn("flex-timer-check: completed", messages.output[0])


if __name__ == "__main__":
    unittest.main()

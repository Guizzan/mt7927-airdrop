"""Nautilus: "Send with AirDrop" for selected files (opens airdrop-app)."""

import subprocess

from gi.repository import GObject, Nautilus


class AirDropMenu(GObject.GObject, Nautilus.MenuProvider):
    def _send(self, _item, files):
        paths = [f.get_location().get_path() for f in files]
        subprocess.Popen(["airdrop-app", *[p for p in paths if p]],
                         start_new_session=True)

    def get_file_items(self, files):
        files = [f for f in files if f.get_uri_scheme() == "file" and not f.is_directory()]
        if not files:
            return []
        item = Nautilus.MenuItem(name="AirDropMenu::Send", label="Send with AirDrop",
                                 icon="send-to-symbolic")
        item.connect("activate", self._send, files)
        return [item]

    def get_background_items(self, _folder):
        return []

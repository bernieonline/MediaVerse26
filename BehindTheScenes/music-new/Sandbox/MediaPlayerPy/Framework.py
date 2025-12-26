import sys
import os
import logging
import json

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

import PySide6
from PySide6.QtWidgets import QApplication, QMessageBox
from PySide6.QtCore import QCoreApplication, QUrl, QLibraryInfo
from PySide6.QtQml import QQmlApplicationEngine
from project_paths import paths
from XML_Details import GetXMLDetails
from dbMySql.db_utils import getLibraryList
from xml_controller import XmlController
from FileSystem import FileSystem
from Settings_Manager import SettingsManager
# NEW: use your v2 manifest wrapper
from Manifest_v2_wrapper import ManifestUpdater_v2 as ManifestUpdater
from NotificationManager import notifier
import threading

# NEW: server-side cache builder v2
from cacheBuilderOnServer_v2 import CacheBuilder_v2



def main():
    try:
        # ------------------------------------------------------------
        # Logging
        # ------------------------------------------------------------
        log_file = paths["log"]
        logging.basicConfig(
            filename=log_file,
            level=logging.DEBUG,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )

        # mysql connection
        myLibrary = getLibraryList()

        # ------------------------------------------------------------
        # Settings + filesystem
        # ------------------------------------------------------------
        config_path = paths["config"]
        fileSystem = FileSystem()
        settings_manager = SettingsManager(config_path, fileSystem)

        # Convert the Path object to a string QML can understand
        font_url = "file:///" + str(paths["fonts"].as_posix())

        # Load settings immediately
        settings_manager.load_settings()

        # ------------------------------------------------------------
        # Manifest updater (v2 wrapper)
        # ------------------------------------------------------------
        manifest_updater = ManifestUpdater()

        # ------------------------------------------------------------
        # Qt setup
        # ------------------------------------------------------------
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
        app = QApplication(sys.argv)

        # ------------------------------------------------------------
        # QML engine setup
        # ------------------------------------------------------------
        QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))
        os.add_dll_directory(str(Path(sys.modules["PySide6"].__file__).parent))

        with open(paths["menu"], encoding="utf-8") as f:
            menu_data = json.load(f)

        engine = QQmlApplicationEngine()
        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))
        engine.rootContext().setContextProperty("imagesPath", Path(paths["assets"]).as_uri())
        engine.rootContext().setContextProperty("centralMenuData", menu_data)
        engine.rootContext().setContextProperty("SettingsManager", settings_manager)
        engine.rootContext().setContextProperty("fileSystemManager", fileSystem)
        engine.rootContext().setContextProperty("fontPathFA", font_url)
        engine.rootContext().setContextProperty("notificationManager", notifier)

        # ------------------------------------------------------------
        # XML + filesystem controllers
        # ------------------------------------------------------------
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        if myLibrary and "path" in myLibrary[0]:
            root_path = myLibrary[0]["path"]
            fileSystem.update_folders(root_path)

        ctx = engine.rootContext()

        # Expose manifest updater to QML
        ctx.setContextProperty("manifestUpdater", manifest_updater)
        ctx.setContextProperty("fileSystemManager", fileSystem)
        ctx.setContextProperty("xmlController", xml_controller)
        ctx.setContextProperty("xmlDetails", xml_provider)
        ctx.setContextProperty("myLibraryModel", myLibrary)

        # Cache paths (for client-side thumbnails/display)
        ctx.setContextProperty("thumbsPath", paths["thumbs"].as_uri())
        ctx.setContextProperty("displayPath", paths["display"].as_uri())

        # ------------------------------------------------------------
        # Load QML
        # ------------------------------------------------------------
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            return -1

        # ------------------------------------------------------------
        # Helper: server cache info path (v2)
        # ------------------------------------------------------------
        server_cache_info_path = Path(r"W:\MediaVerse\cache\cache_info.json")
        server_cache_root_v2 = paths["server_cache_root_v2"]

        # ------------------------------------------------------------
        # Helper: decide whether cache rebuild is needed
        # ------------------------------------------------------------
        
        '''
        def is_cache_up_to_date(manifest: dict) -> bool:
            """
            Compare manifest['generated'] with cache_info['manifest_generated'].
            Return True if they match (no rebuild needed).
            """
            try:
                if not server_cache_info_path.exists():
                    print("[CacheInfo] cache_info.json not found -> rebuild required")
                    return False

                with open(server_cache_info_path, "r", encoding="utf-8") as f:
                    cache_info = json.load(f)

                manifest_generated = manifest.get("generated")
                cached_generated = cache_info.get("manifest_generated")

                print(f"[CacheInfo] manifest_generated = {manifest_generated}")
                print(f"[CacheInfo] cached_generated   = {cached_generated}")

                return bool(manifest_generated and manifest_generated == cached_generated)

            except Exception as e:
                print(f"[CacheInfo] Failed to read/compare cache_info.json: {e}")
                # On error, be safe and rebuild
                return False
        '''
        # ------------------------------------------------------------
        # Helper: update cache_info.json after successful rebuild
        # ------------------------------------------------------------
        '''
        def update_cache_info(manifest: dict):
            """
            Store manifest['generated'] into cache_info.json so we can
            skip future rebuilds until the manifest changes again.
            """
            try:
                manifest_generated = manifest.get("generated")
                if not manifest_generated:
                    print("[CacheInfo] Manifest missing 'generated' field; not updating cache_info.json")
                    return

                cache_info = {
                    "manifest_generated": manifest_generated,
                    "items": len(manifest.get("items", []))
                }

                server_cache_info_path.parent.mkdir(parents=True, exist_ok=True)
                with open(server_cache_info_path, "w", encoding="utf-8") as f:
                    json.dump(cache_info, f, indent=2)

                print(f"[CacheInfo] Updated cache_info.json with manifest_generated={manifest_generated}")

            except Exception as e:
                print(f"[CacheInfo] Failed to update cache_info.json: {e}")
        '''
        # ------------------------------------------------------------
        # Helper: run server cache builder in background
        # ------------------------------------------------------------
        def run_server_cache_builder(manifest: dict):
            """
            Run CacheBuilder_v2 on the server using the given manifest.
            This runs in a worker thread to avoid blocking the UI.
            """
            try:
                print("Framework,py")
                print("[CacheBuilder_v2] Initializing server cache builder...")
                builder = CacheBuilder_v2(manifest, server_cache_root_v2)

                # Optional: simple console logging for progress
                builder.cacheStarted.connect(
                    lambda: print("[CacheBuilder_v2] Cache build started")
                )
                #builder.cacheProgress.connect(
                    #lambda done, total: print(f"[CacheBuilder_v2] Progress: {done}/{total}")   
                #)
                builder.cacheProgress.connect(
                    lambda done, total: None
                )
                builder.cacheFinished.connect(
                    lambda: print("[CacheBuilder_v2] Cache build finished")
                )

                builder.run()

                # After a successful run, record the manifest timestamp
                #update_cache_info(manifest)

            except Exception as e:
                print(f"[CacheBuilder_v2] ERROR during cache build: {e}")
                logging.exception("CacheBuilder_v2 encountered an error.")

        # ------------------------------------------------------------
        # Slot: called when manifest is loaded (after update)
        # this should do nothing - actions affecting the cache and decisions about 
        # rebuilding are handled in sync engine check 0, check A Check B, Check C
        # ------------------------------------------------------------
        def on_manifest_loaded(manifest: dict):
            """
            Called whenever ManifestUpdater_v2 has built + loaded the manifest.
            We decide here whether to rebuild the server cache.
            """
            print("[Framework] manifestLoaded received in Framework.")
            print(f"[Framework] content_changed = {manifest.get('content_changed')}")
            print(f"[Framework] manifest keys = {list(manifest.keys())}")
            print(f"[Framework] manifest source = {manifest.get('_source')}")


            #print("[Framework] manifestLoaded received in Framework.")
            # Decide if cache is up to date
            #if is_cache_up_to_date(manifest):
            #    print("[Framework] Server cache is up to date. No rebuild required.")
            #    return

            print("[Framework] Server cache is OUT of date. Launching CacheBuilder_v2 in background...")
            if manifest.get("content_changed") is True:
                print("[Framework] Library content changed — launching CacheBuilder_v2 in background...")
                threading.Thread(
                    target=run_server_cache_builder,
                    args=(manifest,),
                    daemon=True
                ).start()
                return

            print("[Framework] No content_changed flag found — defaulting to rebuild.")


            # Run cache builder in a background thread
            #this runs the above  method
            threading.Thread(
                target=run_server_cache_builder,
                args=(manifest,),
                daemon=True
            ).start()


        # Connect manifestLoaded signal to our handler signal sent from wrapper when
        #manifest is done

        
        manifest_updater.manifestLoaded.connect(on_manifest_loaded)

    

        print("✅ Framework-1.qml loaded successfully.")

        # ------------------------------------------------------------
        # Database library list
        # ------------------------------------------------------------
        if not myLibrary:
            error_message = "Server not running or no libraries found."
            notifier.post_notification("Database Connection Failed!", True)
            logging.error(error_message)
            return -1
        else:
            notifier.post_notification("Database Connected: MediaVerse is Online", False)

        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1


if __name__ == "__main__":
    sys.exit(main())
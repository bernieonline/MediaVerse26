from PySide6.QtCore import QUrl

print(QUrl.fromLocalFile(
    r"\\freenas\Collection\1960s 70s 80s\A Hard Days Night (1964).jpg"
).toString())

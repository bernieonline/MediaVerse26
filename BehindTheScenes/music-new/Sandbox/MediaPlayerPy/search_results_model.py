from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex

class SearchResultsModel(QAbstractListModel):
    TITLE_ROLE = Qt.UserRole + 1
    PATH_ROLE = Qt.UserRole + 2

    def __init__(self):
        super().__init__()
        self._items = []

    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    def data(self, index, role):
        if not index.isValid():
            return None
        item = self._items[index.row()]
        if role == self.TITLE_ROLE:
            return item["title"]
        if role == self.PATH_ROLE:
            return item["filePath"]
        return None

    def roleNames(self):
        return {
            self.TITLE_ROLE: b"title",
            self.PATH_ROLE: b"filePath"
        }

    def clear(self):
        self.beginResetModel()
        self._items = []
        self.endResetModel()

    def append(self, item):
        self.beginInsertRows(QModelIndex(), len(self._items), len(self._items))
        self._items.append(item)
        self.endInsertRows()
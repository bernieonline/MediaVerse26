BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "errorLog" (
	"filename"	TEXT,
	"errorLog"	TEXT,
	"checksum"	TEXT,
	"timestamp"	DATETIME,
	"manual_check"	TEXT,
	"file_size"	INTEGER,
	"meta_data"	TEXT,
	"imdbID"	TEXT,
	"recno"	INTEGER,
	"Approved"	TEXT,
	PRIMARY KEY("recno" AUTOINCREMENT)
);
CREATE VIEW " SummaryView" AS select filename from CollectionDetails;
CREATE VIEW CollectionDeatils AS select MovieLibraryLarge.Drive||MovieLibraryLarge.Path||MovieLibraryLarge.FileName||MovieLibraryLarge.FileType as fullPath, Collection.Type
from MovieLibraryLarge
inner join Collection on MovieLibraryLarge.FileName = Collection.Title;
COMMIT;

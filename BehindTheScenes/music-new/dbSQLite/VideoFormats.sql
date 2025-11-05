BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "VideoFormats" (
	"Name"	TEXT,
	"Type"	TEXT NOT NULL,
	"Container Format"	TEXT,
	"Video coding Format"	TEXT,
	"Audio Coding Format"	TEXT,
	"Notes"	TEXT,
	"ID"	INTEGER,
	PRIMARY KEY("ID" AUTOINCREMENT)
);
CREATE VIEW " SummaryView" AS select filename from CollectionDetails;
CREATE VIEW CollectionDeatils AS select MovieLibraryLarge.Drive||MovieLibraryLarge.Path||MovieLibraryLarge.FileName||MovieLibraryLarge.FileType as fullPath, Collection.Type
from MovieLibraryLarge
inner join Collection on MovieLibraryLarge.FileName = Collection.Title;
COMMIT;

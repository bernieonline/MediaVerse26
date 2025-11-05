BEGIN TRANSACTION;
CREATE VIEW " SummaryView" AS select filename from CollectionDetails;
CREATE VIEW CollectionDeatils AS select MovieLibraryLarge.Drive||MovieLibraryLarge.Path||MovieLibraryLarge.FileName||MovieLibraryLarge.FileType as fullPath, Collection.Type
from MovieLibraryLarge
inner join Collection on MovieLibraryLarge.FileName = Collection.Title;
COMMIT;

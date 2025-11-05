import SQLiteFunction


# this class will populate the MovieIndex database table which will later be sorted to group
# together similarly named files
# so that I can see how many copies/versions of a file that I have and where they are
class MyMovies:
    def __init__(self, drive_letter, file_path, file_name, file_extension, file_size, date_created,
                 date_modified):
        self.drive_letter = drive_letter
        #   print(self.drive_letter)
        self.file_path = file_path
        #   print(self.file_path)
        self.file_name = file_name
        #   print(self.file_name)
        self.file_extension = file_extension
        #   print(self.file_extension)
        self.file_size = file_size
        #   print(self.file_size)
        self.date_created = date_created
        #   print(self.date_created)
        self.date_modified = date_modified
        #   print(self.date_modified)
        # self.tablename = tablename

    # this method is used to insert a redord into the database
    def insert_to_large_library(self, tableName):
        #   print(" now in inswer record method")
        # get a connection to the database
        self.tableName = tableName
        conn = SQLiteFunction.create_connection\
            (r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")

        cur = conn.cursor()

        # we set up a parametrised query by creating a list of variables to be passed into the query
        # its the easiest way to construct the query

        record = [self.drive_letter, self.file_path, self.file_name, self.file_extension,
                  self.file_size, self.date_created, self.date_modified ]

        # the variables above are inserted into the query statement where the ? placeholders are situated
        sql = "insert into [" + self.tableName + "] (Drive, Path, FileName, FileType, FileSize, DateCreated," \
              " DateModified) values (?,?,?,?,?,?,?)"
        # print(sql)
        cur.execute((sql), record)
        conn.commit()
        conn.close()
        # print(cur.lastrowid)

        return cur.lastrowid


class errorLibrary:
    def __init__(self):
        '''
        this class maintains a list of ffmpeg error codes that we want to remove from the final output
        ready to store in the database
        :return:
        '''

        # add strings to be stripped and listed to the list below
        string1 = 'non-existing PPS 0 referenced'
        string2 = '     Last message repeated 1 times'+"//n"     # this was a pain to filter out, spaces caused problem
        string3 = 'decode_slice_header error'
        string4 = 'no frame!'

        # List of error codes that can be filtered out as they are unimportant
        self.errorList = [string1, string2, string3, string4]

        # add chars to be removed to the list below for filtering process
        self.characters_to_remove = "[],"

        # output of list of stripped items
        self.finalList = []
        self.createFinalList()

    # this method returns the list of error codes
    def createFinalList(self):
        return self.errorList

    # removes [] and white space from before and  after a string
    def stripThis(self, message):
        original_string = message
        new_string = original_string
        for character in self.characters_to_remove:
            new_string = new_string.replace(character, "")

        return new_string

    # looks for the first instance of ']' and removes everything from the ] bracket plus a space
    def truncString(self, message):
        count = 0
        for x in message:
            if x == ']':
                break
            count = count + 1
        trunc = message[count+1:]         # to mop up the space after the bracket

        # returns the truncated piece of error text
        return trunc




import errorLibrary

test = errorLibrary.errorLibrary()

myList = test.createFinalList()
print("list of modded strings is :", myList)
messageA = '[h264 @ 00000219297e4080] non-existing PPS 0 referenced'
print("original message is :",messageA)
messageB = test.stripThis(messageA)
print("new message is :",messageB)

print("next step====== created input line =============")
readLine = '[h264 @ 00000219297e4080] decode_slice_header error'

readLineStripped = test.stripThis(readLine)
print("next step====== stripped input line =============")
if readLineStripped in myList:
    print("Its in the list:")
else:
    print("Its Missing")



# in filtering module

'''
import errorLibrary
Library = errorLibrary.errorLibrary()
myList = Library.createFinalList()
#read a line
messageA = readALine
messageB = Library.stripThis(messageA)
#strip it
#is it in list
if messageB in myList:
    None
else:
    write messageB to new file
# if yes do nothing
#if not write to new file
'''






'''
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[h264 @ 00000219297e4080] non-existing PPS 0 referenced
    Last message repeated 1 times
[h264 @ 00000219297e4080] decode_slice_header error
[h264 @ 00000219297e4080] no frame!
[ac3 @ 000002192adfd040] incomplete frame

'''
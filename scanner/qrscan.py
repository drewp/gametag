"""
get python 2.6.6 (for zbar compatibility)
get zbar-0.10
get zbar for python
get numpy-1.7.1
get opencv-2.4.0


python-requests

a qr that says 'station=/some/uri' shall change our this-station file
to contain /some/uri

"""
import subprocess, time
import zbar
from cv2 import cv
from requests.api import post

def playSound(wavPath):
    # see blockstack for a real sound player that can go bg
    subprocess.check_output(['/usr/bin/aplay', '-q', wavPath])
    
display = True

if display:
    win = cv.NamedWindow('qr')

print "capturing"
capture = cv.CaptureFromCAM(0)

width, height = cv.GetSize(cv.QueryFrame(capture))

scanner = zbar.ImageScanner()
scanner.parse_config('enable')

gray = cv.CreateMat(480, 640, cv.CV_8UC1)

playSound('request-station.wav')

lastSeen = {} # data : time
noRepeatSecs = 10 # ignore repeated scans spaced less than this

station = None

while True:
    img = cv.QueryFrame(capture)
    cv.CvtColor(img, gray, cv.CV_RGB2GRAY)

    if display:
        cv.ShowImage('qr', gray)
        cv.WaitKey(1)

    zbar_img = zbar.Image(width, height, 'Y800', gray.tostring())
    scanner.scan(zbar_img)

    now = time.time()
    
    for symbol in zbar_img:
        if lastSeen.get(symbol.data, 0) < now - noRepeatSecs:
            if station is None:
                station = symbol.data
                playSound('station-received.wav')
            else:
                playSound('scanned-person.wav')
                print "found", symbol.data, symbol.location
                post("https://gametag.bigast.com/scan", verify=False, timeout=2,
                     data={'station': station, 'user': symbol.data})
        lastSeen[symbol.data] = now


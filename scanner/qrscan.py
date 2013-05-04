"""
get python 2.6.6 (for zbar compatibility)
get zbar-0.10
get zbar for python
get numpy-1.7.1
get opencv-2.4.0


python-requests

a qr that says 'station=/some/uri' should change the station we're
sending to /some/uri

"""
import time
import zbar
from cv2 import cv
from requests.api import post
from pyglet import media, app

display = True

if display:
    win = cv.NamedWindow('qr')

sounds = {}
for f in ["station-received.wav", 'request-station.wav', 'scanned-person.wav']:
    sounds[f] = media.load(f)

print "capturing"
capture = cv.CaptureFromCAM(0)

width, height = cv.GetSize(cv.QueryFrame(capture))

scanner = zbar.ImageScanner()
scanner.parse_config('enable')

gray = cv.CreateMat(480, 640, cv.CV_8UC1)

sounds['request-station.wav'].play()

lastSeen = {} # data : time
noRepeatSecs = 10 # ignore repeated scans spaced less than this

station = None

class ScannerLoop(app.EventLoop):
    def idle(self):
        img = self.getZbarCameraImage()
        scanner.scan(img)
        self.handleMatches(img)
        return 0

    def getZbarCameraImage(self):
        img = cv.QueryFrame(capture)
        cv.CvtColor(img, gray, cv.CV_RGB2GRAY)

        if display:
            cv.ShowImage('qr', gray)
            cv.WaitKey(1)

        return zbar.Image(width, height, 'Y800', gray.tostring())
        
    def handleMatches(self, img):
        global station
        now = time.time()

        for symbol in img:
            if lastSeen.get(symbol.data, 0) < now - noRepeatSecs:
                if station is None:
                    station = symbol.data
                    sounds['station-received.wav'].play()
                else:
                    sounds['scanned-person.wav'].play()
                    print "found", symbol.data, symbol.location
                    post("https://gametag.bigast.com/scan", verify=False,
                         timeout=2,
                         data={'station': station, 'user': symbol.data})
            lastSeen[symbol.data] = now

ScannerLoop().run()


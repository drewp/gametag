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

class Scanner(object):
    def __init__(self, cvCameraNumber=0, display=True):

        self.display = display

        if self.display:
            self.win = cv.NamedWindow('qr')

        print "capturing video"
        self.capture = cv.CaptureFromCAM(cvCameraNumber)

        self.width, self.height = cv.GetSize(cv.QueryFrame(self.capture))

        self.scanner = zbar.ImageScanner()
        self.scanner.parse_config('enable')

        self.gray = cv.CreateMat(480, 640, cv.CV_8UC1)

    def getZbarCameraImage(self):
        img = cv.QueryFrame(self.capture)
        cv.CvtColor(img, self.gray, cv.CV_RGB2GRAY)

        if self.display:
            cv.ShowImage('qr', self.gray)
            cv.WaitKey(1)

        zimg = zbar.Image(self.width, self.height, 'Y800', self.gray.tostring())
        self.scanner.scan(zimg)
        return zimg

class Sounds(object):
    def play(self, name):
        media.load(name, streaming=False).play()
        
scanner = Scanner()
sounds = Sounds()
                
lastSeen = {} # data : time
noRepeatSecs = 10 # ignore repeated scans spaced less than this

station = None

class ScannerLoop(app.EventLoop):
    def __init__(self):
        app.EventLoop.__init__(self)
        sounds.play('request-station.wav')
        
    def idle(self):
        app.EventLoop.idle(self)
        img = scanner.getZbarCameraImage()
        self.handleMatches(img)
        return 0.05
        
    def handleMatches(self, img):
        global station
        now = time.time()

        for symbol in img:
            if lastSeen.get(symbol.data, 0) < now - noRepeatSecs:
                if station is None:
                    station = symbol.data
                    print "station is now", station
                    sounds.play('station-received.wav')
                else:
                    sounds.play('scanned-person.wav')
                    print "found", symbol.data, symbol.location
                    post("https://gametag.bigast.com/scan", verify=False,
                         timeout=2,
                         data={'station': station, 'user': symbol.data})
            lastSeen[symbol.data] = now

ScannerLoop().run()


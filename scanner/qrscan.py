"""

"""
import time, argparse
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
    def __init__(self):
        self.player = media.Player()
    def play(self, name):
        self.player.pause()
        prev = self.player.source
        self.player.queue(media.load(name, streaming=False))
        if prev:
            self.player.next()
        self.player.play()
                
class ScannerLoop(app.EventLoop):
    def __init__(self, args, sounds, scanner):
        app.EventLoop.__init__(self)
        sounds.play('request-station.wav')
        self.args, self.sounds, self.scanner = args, sounds, scanner
        self.station = None # our station uri (configured with a QR code)
        self.lastSeen = {} # data : time
        
    def idle(self):
        app.EventLoop.idle(self)
        img = self.scanner.getZbarCameraImage()
        self.handleMatches(img)
        return 0.05
        
    def handleMatches(self, img):
        now = time.time()

        for symbol in img:
            if not symbol.data.strip():
                # sometimes we get stray scans when there's no real QR code around
                continue
            if self.lastSeen.get(symbol.data, 0) < now - self.args.norepeat:
                if self.station is None:
                    self.station = symbol.data
                    print "station is now", self.station
                    self.sounds.play('station-received.wav')
                else:
                    # todo: a qr that says 'station=/some/uri' should
                    # change the station we're sending to /some/uri

                    self.sounds.play('chirp2.wav')
                    print "found", symbol.data, symbol.location
                    print post(self.args.post,
                         timeout=2,
                         data={'game': self.station, 'qr': symbol.data})
            else:
                print "still see", symbol.data, now
            self.lastSeen[symbol.data] = now

def main():
    parser = argparse.ArgumentParser(
        description='watch webcam for QR codes; send them as HTTP POST requests')
    parser.add_argument('--display',
                        action='store_true',
                        help='show incoming video in a window')
    parser.add_argument('--post',
                        default="https://gametag.bigast.com/scans",
                        metavar="url",
                        help="url we post to")
    parser.add_argument('--cam', default=0, type=int, metavar='num',
                        help='CV number for camera to read from')
    parser.add_argument('--norepeat', default=10, type=int, metavar='secs',
                        help='ignore repeated scans spaced closer than this')

    args = parser.parse_args()

    scanner = Scanner(display=args.display, cvCameraNumber=args.cam)
    sounds = Sounds()

    ScannerLoop(args, sounds, scanner).run()
main()

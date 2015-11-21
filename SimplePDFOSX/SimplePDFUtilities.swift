//
//  SimplePDFUtilities.swift
//
//  Created by Muhammad Ishaq on 22/03/2015
//

import Foundation
import ImageIO
import Cocoa

extension CIImage {
        func flippedImage(horizontal: Bool = false) -> CIImage? {
                
                var result : CIImage?
                
                if let transform = CIFilter(name:"CIAffineTransform") {
                        transform.setValue(self, forKey:"inputImage")
                        
                        let affineTransform = NSAffineTransform();
                        let xy : (CGFloat, CGFloat) = horizontal ? (-1,1) : (1,-1)
                        affineTransform.scaleXBy(xy.0, yBy:xy.1)
                        transform.setValue(affineTransform, forKey:"inputTransform")
                        
                        result = transform.valueForKey("outputImage") as? CIImage
                }
                return result
                
        }
        
        func drawInCGContext(context: CGContextRef!, destRect: CGRect!) {
                let ci = CIContext(CGContext: context, options: nil)
                ci.drawImage(self
                        , inRect: destRect
                        , fromRect: self.extent)
                
        }
        
        class func fromNSImage(i: NSImage?) -> CIImage? {
                guard let img = i else {return nil}
                // convert NSImage to bitmap
                if let tiffData = img.TIFFRepresentation {
                        if let bitmap = NSBitmapImageRep.init(data: tiffData) {
                                return CIImage(bitmapImageRep: bitmap)
                        }
                }
                return nil
        }
}

class SimplePDFUtilities {
    class func getApplicationVersion() -> String {
        var dictionary: Dictionary<NSObject, AnyObject>!
        if (NSBundle.mainBundle().localizedInfoDictionary != nil) {
            dictionary = NSBundle.mainBundle().localizedInfoDictionary! as Dictionary
        }
        else {
            dictionary = NSBundle.mainBundle().infoDictionary!
        }
        let build = dictionary["CFBundleVersion"] as! NSString
        let shortVersionString = dictionary["CFBundleShortVersionString"] as! NSString
        
        return "(\(shortVersionString) Build: \(build))"
    }
    
    class func getApplicationName() -> String {
        var dictionary: Dictionary<NSObject, AnyObject>!
        if (NSBundle.mainBundle().localizedInfoDictionary != nil) {
            dictionary = NSBundle.mainBundle().localizedInfoDictionary! as Dictionary
        }
        else {
            dictionary = NSBundle.mainBundle().infoDictionary!
        }
        let name = dictionary["CFBundleName"] as! NSString
        
        return name as String
    }
    
    class func pathForTmpFile(fileName: String) -> NSURL {
        let tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        let pathURL = tmpDirURL.URLByAppendingPathComponent(fileName)
        return pathURL
    }
    
    class func renameFilePathToPreventNameCollissions(url: NSURL) -> String {
        let fileManager = NSFileManager()
        
        // append a postfix if file name is already taken
        var postfix = 0
        var newPath = url.path!
        while(fileManager.fileExistsAtPath(newPath)) {
            postfix++
            
            let pathExtension = url.pathExtension
            newPath = url.URLByDeletingPathExtension!.path!
            newPath = newPath.stringByAppendingString(" \(postfix)")
            var newPathURL = NSURL(fileURLWithPath: newPath)
            newPathURL = newPathURL.URLByAppendingPathExtension(pathExtension!)
            newPath = newPathURL.path!
        }
        
        return newPath
    }
    
    class func getImageProperties(imagePath: String) -> Dictionary<NSObject, AnyObject>? {
        let imageURL = NSURL(fileURLWithPath: imagePath)
        let imageSourceRef = CGImageSourceCreateWithURL(imageURL, nil)
        let props = CGImageSourceCopyPropertiesAtIndex(imageSourceRef!, 0, nil) as Dictionary?
        return props
    }
    
    class func getNumericListAlphabeticTitleFromInteger(value: Int) -> String {
        let base:Int = 26
        let unicodeLetterA :UnicodeScalar = "\u{0061}" // a
        var mutableValue = value
        var result = ""
        repeat {
            let remainder = mutableValue % base
            mutableValue = mutableValue - remainder
            mutableValue = mutableValue / base
            let unicodeChar = UnicodeScalar(remainder + Int(unicodeLetterA.value))
            result = String(unicodeChar) + result
        
        } while mutableValue > 0
        
        return result
    }
    
    class func generateThumbnail(imageURL: NSURL, size: CGSize, callback: (thumbnail: NSImage, fromURL: NSURL, size: CGSize) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if let imageSource = CGImageSourceCreateWithURL(imageURL, nil) {
                let options = [
                    kCGImageSourceThumbnailMaxPixelSize as String: max(size.width, size.height),
                    kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true
                ]
                
                let scaledImage = NSImage(CGImage: CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)!, size: size)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(thumbnail: scaledImage, fromURL: imageURL, size: size)
                })
            }
        })
    }
}


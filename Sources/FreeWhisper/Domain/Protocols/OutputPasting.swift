import Foundation

protocol OutputPasting: AnyObject {
    func paste(text: String)
    func copyToClipboard(text: String)
}

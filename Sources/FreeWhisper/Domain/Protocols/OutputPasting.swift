import Foundation

protocol OutputPasting: AnyObject {
    func saveFrontmostApp()
    func paste(text: String)
    func copyToClipboard(text: String)
}

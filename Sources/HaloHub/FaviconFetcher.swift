import AppKit
import CryptoKit
import Foundation

actor FaviconFetcher {
    static let shared = FaviconFetcher()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        session = URLSession(configuration: configuration)
    }

    func cachedIcon(for pageURL: URL) async -> URL? {
        guard let host = pageURL.host else { return nil }
        let destinationURL = iconCacheURL(for: host)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }

        let candidates = await faviconCandidates(for: pageURL)
        for candidate in candidates {
            guard let image = await downloadImage(from: candidate),
                  let pngData = image.pngData else {
                continue
            }

            do {
                try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try pngData.write(to: destinationURL, options: .atomic)
                return destinationURL
            } catch {
                NSLog("PopDeck failed to cache favicon for \(host): \(error)")
                return nil
            }
        }

        return nil
    }

    private func faviconCandidates(for pageURL: URL) async -> [URL] {
        var candidates: [URL] = []

        if let htmlIconURL = await htmlIconURL(for: pageURL) {
            candidates.append(htmlIconURL)
        }

        if let origin = originURL(for: pageURL) {
            candidates.append(origin.appendingPathComponent("apple-touch-icon.png"))
            candidates.append(origin.appendingPathComponent("favicon.png"))
            candidates.append(origin.appendingPathComponent("favicon.ico"))
        }

        var seen = Set<String>()
        return candidates.filter { url in
            guard !seen.contains(url.absoluteString) else { return false }
            seen.insert(url.absoluteString)
            return true
        }
    }

    private func htmlIconURL(for pageURL: URL) async -> URL? {
        guard let (data, response) = try? await session.data(from: pageURL),
              let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode),
              let html = String(data: data.prefix(200_000), encoding: .utf8) ?? String(data: data.prefix(200_000), encoding: .isoLatin1) else {
            return nil
        }

        let patterns = [
            #"<link[^>]+rel=["'][^"']*(?:apple-touch-icon|shortcut icon|icon)[^"']*["'][^>]+href=["']([^"']+)["']"#,
            #"<link[^>]+href=["']([^"']+)["'][^>]+rel=["'][^"']*(?:apple-touch-icon|shortcut icon|icon)[^"']*["']"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            guard let match = regex.firstMatch(in: html, options: [], range: range),
                  let hrefRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let href = String(html[hrefRange])
            if let url = URL(string: href, relativeTo: pageURL)?.absoluteURL {
                return url
            }
        }

        return nil
    }

    private func downloadImage(from url: URL) async -> NSImage? {
        guard let (data, response) = try? await session.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode),
              let image = NSImage(data: data),
              image.isValid else {
            return nil
        }
        return image
    }

    private func originURL(for url: URL) -> URL? {
        guard let scheme = url.scheme, let host = url.host else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = url.port
        return components.url
    }

    private func iconCacheURL(for host: String) -> URL {
        let digest = SHA256.hash(data: Data(host.lowercased().utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined() + ".png"
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return baseURL
            .appendingPathComponent("PopDeck", isDirectory: true)
            .appendingPathComponent("Favicons", isDirectory: true)
            .appendingPathComponent(filename)
    }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}

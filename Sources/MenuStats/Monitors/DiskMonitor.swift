import Foundation

actor DiskMonitor {
    private let rootPath = "/"

    func getMetrics() -> DiskMetrics {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: rootPath)

            guard let totalSize = attributes[.systemSize] as? UInt64,
                  let freeSize = attributes[.systemFreeSize] as? UInt64 else {
                return DiskMetrics.empty
            }

            let usedSize = totalSize - freeSize

            return DiskMetrics(
                usedBytes: usedSize,
                totalBytes: totalSize,
                freeBytes: freeSize
            )
        } catch {
            return DiskMetrics.empty
        }
    }
}

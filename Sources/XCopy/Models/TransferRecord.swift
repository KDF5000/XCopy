import Foundation

struct TransferRecord: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case success
        case failed
    }

    var id: UUID
    var date: Date
    var hostName: String
    var fileName: String
    var remotePath: String
    var status: Status
    var message: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        hostName: String,
        fileName: String,
        remotePath: String,
        status: Status,
        message: String
    ) {
        self.id = id
        self.date = date
        self.hostName = hostName
        self.fileName = fileName
        self.remotePath = remotePath
        self.status = status
        self.message = message
    }
}

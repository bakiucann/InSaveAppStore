// CollectionModel.swift

import Foundation

struct VideoCollectionModel {
    var id: UUID
    var name: String
    var coverURL: String
    var videos: [VideoCollectionModel]
}

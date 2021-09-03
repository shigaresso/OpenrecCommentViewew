import Foundation

// 取得するコメントの JSON の構造体
struct CommentID: Codable, Identifiable {
    var id = UUID()
    let comment: Comment
}


struct Comment: Codable {
    let data: Data
}


struct Data: Codable {
    let user_name: String
    let message: String
}

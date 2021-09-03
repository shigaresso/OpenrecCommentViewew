import SwiftUI

class ConnectStream: ObservableObject {
    @Published var streamURL = ""
    @Published var commentIDs = [CommentID]()
    private var commentCount = 0

    
    func connectOpenrec() {
        // ユーザーIDを取得しAPIURLを作成
        let userID = fetchString(streamURL, "],\"channel\":{\"id\":\"", "\"")
        let apiURL = "https://public.openrec.tv/external/api/v5/movies?channel_ids=\(userID)&sort=onair_status&is_upload=false"
        
        // APIURLからムービーIDのURLを作成
        let movieID = fetchString(apiURL, "movie_id\":", ",")
        let webSocketURL = "wss://chat.openrec.tv/socket.io/?movieId=\(movieID)&EIO=3&transport=websocket"
        
        // WebSocketサーバーへの接続の準備
        let url = URL(string: webSocketURL)!
        let urlSession = URLSession(configuration: .default)
        let webSocketTask = urlSession.webSocketTask(with: url)
        
        webSocketTask.resume()
        receiveMessage(webSocketTask)
        // 接続が途切れないようにする
        sendPing(webSocketTask)
    }
    
    func fetchString(_ url: String, _ Idlandmark: String, _ separator: Substring.Element) -> String {
        let targetURL = URL(string: url)!
        
        let sourceHTML = try! String(contentsOf: targetURL, encoding: String.Encoding.utf8)
        
        let inFrontOfID = sourceHTML.range(of: Idlandmark)
        
        let fromID = sourceHTML[inFrontOfID!.upperBound...]
        let ID = fromID.split(separator: separator)
        
        return String(ID[0])
    }
    
    
    func receiveMessage(_ webSocketTask: URLSessionWebSocketTask) {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                print("メッセージの受信に失敗しました: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self.fetchOnlyComment(text)
                case .data(let data):
                    print("メッセージを受信しました: \(data)")
                default:
                    print("デフォルトです")
                }
                self.receiveMessage(webSocketTask)
            }
        }
    }
    
    // pingの内容はChromeのデべロッパーツールのNetworkのWS内のMessageから調べる
    func sendPing(_ webSocketTask: URLSessionWebSocketTask) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string("2")) { error in
            if let error = error {
                print(error)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            self.sendPing(webSocketTask)
        }
    }
    
    func fetchOnlyComment(_ text: String) {
        if text.contains("42[\"message\",\"{\\\"type\\\":0,") {
            // receiveMessage() で取得した文字列が定数になるので一旦変数に入れて置換出来るようにする
            var textComment = text
            textComment = textComment.replacingOccurrences(of: "42[\"message\",\"", with: "").replacingOccurrences(of: "\"]", with: "").replacingOccurrences(of: "\\\"", with: "\"")
            // ここで text を構造体に渡す
            convertStructure(textComment)
        }
    }
    
    func convertStructure(_ textComment: String) {
        do {
            let jsonData = textComment.data(using: .utf8)!
            // Comment 構造体の作成
            let comment = try JSONDecoder().decode(Comment.self, from: jsonData)
            // 作成した Comment 構造体を CommentID 構造体に代入
            // これは SwiftUI で View に用いる時に ID で識別する必要があるのだが、受け取る JSON には ID がない為、こちらで追加する必要があるから
            let commentID = CommentID(comment: comment)
            
            // UI に関係があるものはメインスレッドで変更が必要なためこのブロックで囲んでいる
            DispatchQueue.main.async {
                self.commentIDs.append(commentID)
                
                // デバッグでコメントが取れているかの確認用
                print(self.commentIDs[self.commentCount].comment.data.message)
                self.commentCount += 1
            }
            
        } catch {
            print("構造体化に失敗")
        }
    }
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var connectStream: ConnectStream = ConnectStream()
    // 自動スクロールを停止させるために使う
    @State private var isScroll = true
    
    var body: some View {
        VStack {
            
            HStack {
                TextField("Please, stream URL here", text: $connectStream.streamURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.border(Color.blue, width: 1.5)
                
                Button(action: {
                    connectStream.connectOpenrec()
                }) {
                    Text("接続")
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }

            
            ScrollView {
                ScrollViewReader { scorllViewProxy in
                    LazyVStack {
                        ForEach(connectStream.commentIDs) { structure in
                            Text(structure.comment.data.message)
                        }
                        .onChange(of: connectStream.commentIDs.count) { _ in
                            if isScroll {
                                // 今表示されている最後の構造体に飛ぶ
                                scorllViewProxy.scrollTo(connectStream.commentIDs.last!.id)
                            }
                        }
                    }
                }
            }

            
            Toggle(isOn: $isScroll) {
                if isScroll {
                    Text("オートスクロール機能オン中")
                } else {
                    Text("オートスクロール機能オフ中")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone{
            IphoneView()
        }else{
            IpadView()
        }
    }
}

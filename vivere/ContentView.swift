import SwiftUI

struct ContentView: View {
    @State private var mpc = MPCManager()
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            IphoneView(mpc: mpc)
        } else {
            IpadView(mpc: mpc)
        }
    }
}

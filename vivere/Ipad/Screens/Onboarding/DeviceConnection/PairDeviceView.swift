////
////  PairDeviceView.swift
////  vivere
////
////  Created by Reinhart on 09/11/25.
////
//
//import SwiftUI
//import MultipeerConnectivity
//
//struct PairDeviceView: View {
//    @Binding var isNextPressed: Bool
//    @Binding var isPaired: Bool
////    @Environment(MPCManager.self) private var mpc
//    
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.4)
//                .ignoresSafeArea(.all)
//                .onTapGesture {_ in
//                    isNextPressed = false
//                }
//            VStack(spacing: 30) {
//                VStack(spacing: 16) {
//                    Text("Hubungkan Perangkat Anda")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .foregroundColor(.black)
//                    
//                    Text("Tekan tombol \"hubungkan\" di bawah lalu dekatkan iPad dengan iPhone, perangkat akan otomatis terhubung satu sama lain.")
//                        .font(.body)
//                        .foregroundColor(.black)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(nil)
//                }
//                
//                if mpc.discoveredPeers.isEmpty {
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 267)
//                        .cornerRadius(8)
//                } else {
//                    List {
//                        ForEach(mpc.discoveredPeers, id:\.self) { peer in
//                            HStack {
//                                Text(peer.displayName)
//                                Spacer()
//                                if mpc.connectedPeers.contains(peer) {
//                                    Text("Terhubung")
//                                        .font(.caption)
//                                        .foregroundStyle(Color.green)
//                                } else if mpc.invitingPeer == peer {
//                                    HStack(spacing: 8) {
//                                        ProgressView()
//                                            .progressViewStyle(.circular)
//                                        Text("Mengundang…")
//                                            .font(.caption)
//                                            .foregroundStyle(.gray)
//                                    }
//                                } else {
//                                    Button("Hubungkan") {
//                                        mpc.connect(to: peer)
//                                    }
//                                    .buttonStyle(.bordered)
//                                }
//                                
//                            }
//                        }
//                    }
//                    .frame(maxWidth: 572)
//                }
//                
////                Button("Lanjutkan") {
////                    isPaired = true
////                }
////                .font(Font.title2)
////                .fontWeight(.semibold)
////                .cornerRadius(10)
////                .buttonStyle(.borderedProminent)
//            }
//            .padding(40)
//            .background(
//                RoundedRectangle(cornerRadius: 24)
//                    .fill(Color.white)
//                    .shadow(radius: 16)
//            )
//            .frame(maxWidth: 572, maxHeight: 478)
//        }
//    }
//}
//
//#Preview {
//    @Previewable @State var isNextPressed: Bool = false
//    @Previewable @State var isPaired: Bool = false
//    PairDeviceView(isNextPressed: $isNextPressed, isPaired: $isPaired)
//}

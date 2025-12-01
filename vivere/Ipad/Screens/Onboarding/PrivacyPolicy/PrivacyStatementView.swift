//
//  PrivacyStatement.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import SwiftUI

struct PrivacyStatementView: View {
   @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {_ in
                    isPresented = false
                }
            
            HStack {
                VStack(alignment: .leading) {
                    Spacer()
                    Image("buttonLeft")
                        .padding()
                }
                .padding()
                
                VStack {
                    Text("Baca ini dulu ya")
                        .font(Font.largeTitle.bold())
                    
                    Line()
                        .stroke(style: .init(dash: [20]))
                        .frame(height: 1)
                    
                    ScrollView {
                        Text("Kebijakan Privasi")
                            .font(Font.title2.bold())
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(privacyStatement)
                            .font(Font.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 20)
                }
                .padding()
                .padding(.vertical, 30)
                
                VStack(alignment: .trailing) {
                    Button("\(Image(systemName: "xmark"))"){
                        isPresented = false
                    }
                    .foregroundColor(Color.black)
                    .font(Font.title)
                    .padding()
                    Spacer()
                    Image("buttonRight")
                        .padding()
                }
                .padding()
            }
            .frame(maxWidth: 1000, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.accent)
            )
        }
    }
    
    private var privacyStatement: String {
        """
        Terima kasih telah menggunakan Vivere!

        Kami akan mengumpulkan, menyimpan, dan menggunakan data pribadi dan biografi yang sangat sensitif. Kami hanya mengumpulkan data yang diperlukan berdasarkan legalitas, legitimasi, dan kebutuhan untuk fungsionalitas produk kami. Jika Anda tidak memberikan persetujuan atas penggunaan data yang relevan ini, Anda tidak dapat menikmati layanan kami, atau tidak dapat mencapai hasil yang dimaksudkan dari layanan ini.

        Persetujuan ini meliputi tiga poin utama:

        1. Penggunaan Data Sensitif dan Privasi
        Kami akan mengumpulkan dan menyimpan informasi riwayat hidup dan pribadi untuk menyesuaikan sesi terapi kenangan. Data ini dienkripsi, dirahasiakan, dan tidak akan dijual atau dibagikan untuk pelatihan model AI eksternal atau tujuan pemasaran.

        2. Sifat Konten AI dan Akurasi
        Aplikasi ini menggunakan Kecerdasan Buatan (AI) untuk menghasilkan petunjuk percakapan yang dirancang untuk membangkitkan ingatan. Hasilnya tidak selalu akurat secara faktual atau historis. Konten harus digunakan hanya sebagai alat bantu percakapan, bukan sebagai catatan faktual yang terverifikasi.

        3. Otonomi dan Keselamatan ODD
        Sebagai Pengasuh/Wali, Anda menyatakan memiliki wewenang hukum untuk menyetujui penggunaan aplikasi ini bagi ODD. Anda juga berkomitmen untuk selalu mengamati reaksi ODD dan menggunakan hak untuk "Akhiri Sesi" segera jika ODD menunjukkan tanda-tanda ketidaknyamanan atau kesusahan.
        """
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    PrivacyStatementView(isPresented: $isPresented)
}

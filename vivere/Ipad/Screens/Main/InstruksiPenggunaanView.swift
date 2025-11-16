//
//  InstruksiPenggunaanView.swift
//  vivere
//
//  Created on 11/14/25.
//

import SwiftUI

struct InstruksiPenggunaanView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(edges: .all)

            VStack(spacing: 40) {
                // Header
                HStack {
                    CustomIpadButton(color: .vivereSecondary) {
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Kembali")
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .frame(height: 70)
                    }

                    Spacer()

                    Text("Instruksi Penggunaan")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible spacer to balance the layout
                    CustomIpadButton(color: .vivereSecondary) {
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Kembali")
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .frame(height: 70)
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 40)
                .padding(.top, 48)

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        InstructionSection(
                            title: "Memulai Permainan",
                            icon: "play.circle.fill",
                            steps: [
                                "Pilih salah satu permainan yang tersedia: Cocokkan Gambar atau Puzzle",
                                "Ikuti instruksi yang muncul di layar",
                                "Nikmati waktu bermain bersama eyang"
                            ]
                        )

                        InstructionSection(
                            title: "Kelola Foto",
                            icon: "photo.on.rectangle",
                            steps: [
                                "Tekan menu ellipsis (⋯) di pojok kanan atas",
                                "Pilih \"Kelola Foto\"",
                                "Tambahkan, ubah, atau hapus foto beserta ceritanya"
                            ]
                        )

                        InstructionSection(
                            title: "Koneksi iPhone",
                            icon: "iphone",
                            steps: [
                                "Tekan menu ellipsis (⋯) di pojok kanan atas",
                                "Pilih \"Koneksi iPhone\"",
                                "Pastikan iPhone dan iPad berada dalam jarak dekat",
                                "Tekan \"Mulai Pencarian\" dan pilih perangkat iPhone Anda"
                            ]
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct InstructionSection: View {
    let title: String
    let icon: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.accent)

                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.accent)
                            .frame(width: 30, alignment: .trailing)

                        Text(step)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 48)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        InstruksiPenggunaanView()
    }
}


//
//  CustomIpadButton.swift
//  vivere
//
//  Created by Reinhart on 08/11/25.
//

import SwiftUI

struct CustomIpadButtonAsView: View {
    let label:LocalizedStringKey
    var icon:Image? = nil
    let color:Color
    let style:CustomIpadButtonStyle
    
    var body: some View {
        Text(label)
            .font(style == .large ? .largeTitle : .title)
            .fontWeight(.semibold)
            .foregroundColor(Color(.black))
            .frame(minWidth:minWidth, minHeight: minHeight)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(minWidth:minWidth, minHeight: minHeight)
                        .foregroundColor(color)
                        .cornerRadius(20)
                        .shadow(color: color.tint(0.2), radius: 0, x: 3, y:3)
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [15]))
                        .padding(10)
                        .foregroundStyle(color == .deny || color == .darkBlue ? .white : .black)
                }
            )
        //                .padding()
        //                .cornerRadius(20)
    }
    
    private var minWidth: CGFloat {
        switch style {
        case .icon:
            return 150
        case .small:
            return 300
        case .large:
            return 320
        }
    }
    
    private var minHeight: CGFloat {
        switch style {
        case .icon:
            return 80
        case .small:
            return 80
        case .large:
            return 100
        }
    }
}

#Preview {
    CustomIpadButton(label: "label", icon: Image(systemName: "plus"), color:.accent, style: .large) {
        print("clicked")
    }
}

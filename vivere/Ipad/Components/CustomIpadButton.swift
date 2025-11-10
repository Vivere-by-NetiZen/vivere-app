//
//  CustomIpadButton.swift
//  vivere
//
//  Created by Reinhart on 08/11/25.
//

import SwiftUI

enum CustomIpadButtonStyle {
    case icon
    case small
    case large
}

struct CustomIpadButton: View {
    let label:String
    var icon:Image? = nil
    let color:Color
    let style:CustomIpadButtonStyle
    let action:() -> Void
    
    var body: some View {
        Button(action: action) {
            finalLabelText
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
        .buttonStyle(.plain)
    }
    
    private var finalLabelText: Text {
        switch style {
        case .icon:
            if let icon = icon {
                return Text("\(icon) \(label)")
            } else {
                return Text(label)
            }
        default:
            return Text(label)
        }
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

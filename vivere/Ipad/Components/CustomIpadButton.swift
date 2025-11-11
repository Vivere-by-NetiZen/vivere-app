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

struct CustomIpadButton<Label: View>: View {
    let color: Color
    let action: () -> Void
    let label: Label

    // Backward compatible initializer for string-based API
    init(
        label: String,
        icon: Image? = nil,
        color: Color,
        style: CustomIpadButtonStyle,
        action: @escaping () -> Void
    ) where Label == AnyView {
        self.color = color
        self.action = action

        let finalLabelText: Text = {
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
        }()

        self.label = AnyView(
            finalLabelText
                .font(style == .large ? .largeTitle : .title)
                .fontWeight(.semibold)
                .foregroundColor(Color(.black))
                .frame(minWidth: Self.minWidth(for: style), minHeight: Self.minHeight(for: style))
        )
    }

    // New flexible initializer with @ViewBuilder
    init(
        color: Color,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.color = color
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(color)
                            .shadow(color: color.tint(0.2), radius: 0, x: 3, y: 3)
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [15]))
                            .padding(10)
                            .foregroundStyle(color == .deny || color == .darkBlue ? .white : .black)
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private static func minWidth(for style: CustomIpadButtonStyle) -> CGFloat {
        switch style {
        case .icon:
            return 150
        case .small:
            return 300
        case .large:
            return 320
        }
    }

    private static func minHeight(for style: CustomIpadButtonStyle) -> CGFloat {
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

#Preview("Customizable") {
    CustomIpadButtonPreview()
}

private struct CustomIpadButtonPreview: View {
    @State private var label: String = "Label"
    @State private var selectedStyle: CustomIpadButtonStyle = .large
    @State private var selectedColorName: String = "accent"
    @State private var useIcon: Bool = true
    @State private var selectedSystemIcon: String = "plus"

    private let availableStyles: [CustomIpadButtonStyle] = [.icon, .small, .large]
    private let styleNames: [CustomIpadButtonStyle: String] = [.icon: "Icon", .small: "Small", .large: "Large"]

    // Map of color display name -> actual Color used by the component
    private let colorOptions: [(name: String, color: Color)] = [
        ("accent", .accent),
        ("blue", .blue),
        ("green", .green),
        ("orange", .orange),
        ("pink", .pink),
        ("purple", .purple),
        ("red", .red),
        ("yellow", .yellow),
        ("black", .black),
        ("white", .white)
    ]

    private let systemIcons: [String] = [
        "plus", "checkmark", "xmark", "star", "heart", "paperplane", "pencil", "trash", "gear", "bell"
    ]

    private var resolvedColor: Color {
        colorOptions.first(where: { $0.name == selectedColorName })?.color ?? .accent
    }

    private var resolvedIcon: Image? {
        guard useIcon else { return nil }
        return Image(systemName: selectedSystemIcon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Label", text: $label)
                    Toggle("Use Icon", isOn: $useIcon)
                    if useIcon {
                        Picker("System Icon", selection: $selectedSystemIcon) {
                            ForEach(systemIcons, id: \.self) { name in
                                Label(name, systemImage: name)
                                    .labelStyle(.titleAndIcon)
                                    .tag(name)
                            }
                        }
                    }
                }

                Section("Style") {
                    Picker("Button Style", selection: $selectedStyle) {
                        ForEach(availableStyles, id: \.self) { style in
                            Text(styleNames[style] ?? "").tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Appearance") {
                    Picker("Color", selection: $selectedColorName) {
                        ForEach(colorOptions, id: \.name) { option in
                            HStack {
                                Circle().fill(option.color).frame(width: 16, height: 16)
                                Text(option.name)
                            }
                            .tag(option.name)
                        }
                    }
                }

                Section("Preview") {
                    VStack(spacing: 20) {
                        CustomIpadButton(
                            label: label,
                            icon: resolvedIcon,
                            color: resolvedColor,
                            style: selectedStyle
                        ) {
                            print("clicked")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("CustomIpadButton Preview")
        }
    }
}

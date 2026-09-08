import UIKit
import FaceLivenessKit

/// Android `SettingsActivity` — camera lens + liveness threshold only.
final class SettingsViewController: UIViewController {
    private struct ThresholdRow {
        let title: String
        let key: String
        let min: Float
        let max: Float
    }

    private struct PickerConfig {
        let title: String
        let key: String
        let options: [(String, String)]
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var valueLabels: [String: UILabel] = [:]
    private var pickerConfigs: [String: PickerConfig] = [:]
    private var thresholdRowsByKey: [String: ThresholdRow] = [:]

    private let thresholdRows: [ThresholdRow] = [
        ThresholdRow(title: "Liveness", key: "liveness_threshold", min: 0, max: 1),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        for row in thresholdRows { thresholdRowsByKey[row.key] = row }

        view.backgroundColor = FPColor.bg
        title = "Settings"
        ScreenChrome.showInnerBar(on: self)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
        ])

        contentStack.addArrangedSubview(cameraSection())
        contentStack.addArrangedSubview(thresholdsSection())
        contentStack.addArrangedSubview(resetSection())
        refreshAllValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
        refreshAllValues()
    }

    private func cameraSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(sectionTitle("Camera"))
        stack.addArrangedSubview(pickerRow(PickerConfig(
            title: "Camera lens",
            key: "camera_lens",
            options: [("Front", "front"), ("Back", "back")]
        )))
        return wrapCard(stack)
    }

    private func thresholdsSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.addArrangedSubview(sectionTitle("Thresholds"))
        stack.addArrangedSubview(pickerRow(PickerConfig(
            title: "Liveness Level",
            key: "liveness_level",
            options: [("High Accuracy", "0"), ("Light Weight", "1")]
        )))
        for row in thresholdRows {
            stack.addArrangedSubview(thresholdRow(row))
        }
        return wrapCard(stack)
    }

    private func resetSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(sectionTitle("Reset"))
        let button = UIButton(type: .system)
        button.setTitle("Restore default settings", for: .normal)
        button.setTitleColor(FPColor.accent, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(restoreDefaults), for: .touchUpInside)
        stack.addArrangedSubview(button)
        return wrapCard(stack)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = FPColor.muted
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func wrapCard(_ stack: UIStackView) -> UIView {
        let card = UIView()
        card.applyAndroidCardStyle()
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        return card
    }

    private func pickerRow(_ config: PickerConfig) -> UIView {
        pickerConfigs[config.key] = config
        let title = UILabel()
        title.text = config.title
        title.textColor = FPColor.text
        title.font = .systemFont(ofSize: 16)

        let value = UILabel()
        value.textColor = FPColor.accent
        value.font = .systemFont(ofSize: 15)
        value.textAlignment = .right
        valueLabels[config.key] = value

        let row = UIStackView(arrangedSubviews: [title, value])
        row.axis = .horizontal
        row.distribution = .fill
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        value.setContentHuggingPriority(.required, for: .horizontal)

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: row.topAnchor),
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            row.heightAnchor.constraint(equalToConstant: 36),
        ])
        button.tag = config.key.hashValue
        button.accessibilityIdentifier = config.key
        button.addTarget(self, action: #selector(openPicker(_:)), for: .touchUpInside)
        return row
    }

    private func thresholdRow(_ row: ThresholdRow) -> UIView {
        let title = UILabel()
        title.text = row.title
        title.textColor = FPColor.text
        title.font = .systemFont(ofSize: 16)

        let value = UILabel()
        value.textColor = FPColor.accent
        value.font = .systemFont(ofSize: 15)
        valueLabels[row.key] = value

        let header = UIStackView(arrangedSubviews: [title, value])
        header.axis = .horizontal

        let slider = UISlider()
        slider.minimumValue = row.min
        slider.maximumValue = row.max
        slider.minimumTrackTintColor = FPColor.accent
        slider.maximumTrackTintColor = FPColor.stroke
        slider.thumbTintColor = FPColor.accent
        slider.tag = row.key.hashValue
        slider.accessibilityIdentifier = row.key
        slider.addTarget(self, action: #selector(thresholdChanged(_:)), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [header, slider])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func refreshAllValues() {
        for (key, label) in valueLabels {
            if let picker = pickerConfigs[key] {
                let raw = AppSettings.defaults.string(forKey: key) ?? picker.options.first?.1 ?? ""
                label.text = picker.options.first(where: { $0.1 == raw })?.0 ?? raw
            } else if let row = thresholdRowsByKey[key] {
                let raw = AppSettings.defaults.string(forKey: key) ?? "0.5"
                label.text = raw
                if let slider = findSlider(key: key) {
                    slider.value = Float(raw) ?? row.min
                }
            }
        }
    }

    private func findSlider(key: String) -> UISlider? {
        func walk(_ view: UIView) -> UISlider? {
            if let slider = view as? UISlider, slider.accessibilityIdentifier == key {
                return slider
            }
            for child in view.subviews {
                if let found = walk(child) { return found }
            }
            return nil
        }
        return walk(contentStack)
    }

    @objc private func openPicker(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier, let config = pickerConfigs[key] else { return }
        let sheet = UIAlertController(title: config.title, message: nil, preferredStyle: .actionSheet)
        for option in config.options {
            sheet.addAction(UIAlertAction(title: option.0, style: .default) { _ in
                AppSettings.defaults.set(option.1, forKey: key)
                self.refreshAllValues()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func thresholdChanged(_ sender: UISlider) {
        guard let key = sender.accessibilityIdentifier else { return }
        let text = String(format: "%.2f", sender.value)
        AppSettings.defaults.set(text, forKey: key)
        valueLabels[key]?.text = text
    }

    @objc private func restoreDefaults() {
        AppSettings.restoreDefaults()
        refreshAllValues()
    }
}

import UIKit
import FaceLivenessKit

/// Settings — camera lens, the passive score threshold, and the full active-liveness configuration.
///
/// Mirrors Android `ui/SettingsActivity` + `xml/root_preferences`. The screen only writes
/// `UserDefaults`; `AppSettings` turns those into `ActiveLivenessOptions`.
final class SettingsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var valueLabels: [String: UILabel] = [:]

    private struct Picker { let title: String; let key: String; let options: [(String, String)] }
    private var pickers: [String: Picker] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
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

        buildSections()
        refreshValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
        refreshValues()
    }

    private func buildSections() {
        contentStack.addArrangedSubview(card("Camera", [
            pickerRow(Picker(title: "Camera lens", key: AppSettings.keyCameraLens, options: [("Front", "front"), ("Back", "back")])),
        ]))
        contentStack.addArrangedSubview(card("Passive liveness", [
            sliderRow(title: "Score threshold", key: AppSettings.keyLivenessThreshold, min: 0, max: 1),
        ]))
        contentStack.addArrangedSubview(card("Active liveness", [
            challengesRow(),
            pickerRow(Picker(title: "Challenges per attempt", key: AppSettings.keyCount,
                             options: (1...5).map { ("\($0)", "\($0)") })),
            toggleRow(title: "Random order", key: AppSettings.keyRandomize, defaultOn: AppSettings.defaultRandomize),
        ]))
        contentStack.addArrangedSubview(card("Active liveness tuning", [
            numberRow(title: "Frames allowed per stage", key: AppSettings.keyFramesWait),
            numberRow(title: "Head turn angle (°)", key: AppSettings.keyYaw),
            numberRow(title: "Head tilt angle (°)", key: AppSettings.keyPitch),
            sliderRow(title: "Smile confidence", key: AppSettings.keySmile, min: 0, max: 1),
            sliderRow(title: "Eye-closed confidence", key: AppSettings.keyBlink, min: 0, max: 1),
            numberRow(title: "Blinks required", key: AppSettings.keyBlinksNumber),
            sliderRow(title: "Move-closer growth", key: AppSettings.keyPerspective, min: 0, max: 1),
            numberRow(title: "Start alignment tolerance (°)", key: AppSettings.keyAlignAngle),
            sliderRow(title: "Minimum face size", key: AppSettings.keyMinFace, min: 0, max: 1),
            sliderRow(title: "Minimum image quality", key: AppSettings.keyQuality, min: 0, max: 1),
            toggleRow(title: "Invert left / right", key: AppSettings.keyInvertTurn, defaultOn: false),
            toggleRow(title: "Invert up / down", key: AppSettings.keyInvertTilt, defaultOn: false),
        ]))

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Restore default settings", for: .normal)
        resetButton.setTitleColor(FPColor.accent, for: .normal)
        resetButton.contentHorizontalAlignment = .left
        resetButton.titleLabel?.font = .systemFont(ofSize: 16)
        resetButton.addTarget(self, action: #selector(restoreDefaults), for: .touchUpInside)
        contentStack.addArrangedSubview(card("Reset", [resetButton]))
    }

    // MARK: - Rows

    private func card(_ titleText: String, _ rows: [UIView]) -> UIView {
        let stack = UIStackView(arrangedSubviews: [sectionTitle(titleText)] + rows)
        stack.axis = .vertical
        stack.spacing = 12
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

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = FPColor.muted
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func titleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = FPColor.text
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }

    private func valueLabel(for key: String, align: NSTextAlignment = .right) -> UILabel {
        let label = UILabel()
        label.textColor = FPColor.accent
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = align
        label.setContentHuggingPriority(.required, for: .horizontal)
        valueLabels[key] = label
        return label
    }

    private func tappableRow(_ content: UIView, action: Selector, key: String) -> UIView {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = key
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.addSubview(content)
        container.addSubview(button)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func pickerRow(_ config: Picker) -> UIView {
        pickers[config.key] = config
        let row = UIStackView(arrangedSubviews: [titleLabel(config.title), valueLabel(for: config.key)])
        row.axis = .horizontal
        return tappableRow(row, action: #selector(openPicker(_:)), key: config.key)
    }

    private func numberRow(title: String, key: String) -> UIView {
        let row = UIStackView(arrangedSubviews: [titleLabel(title), valueLabel(for: key)])
        row.axis = .horizontal
        return tappableRow(row, action: #selector(openNumber(_:)), key: key)
    }

    private func challengesRow() -> UIView {
        let row = UIStackView(arrangedSubviews: [titleLabel("Challenges"), valueLabel(for: AppSettings.keyChecks)])
        row.axis = .horizontal
        return tappableRow(row, action: #selector(openChallenges), key: AppSettings.keyChecks)
    }

    private func toggleRow(title: String, key: String, defaultOn: Bool) -> UIView {
        let toggle = UISwitch()
        toggle.onTintColor = FPColor.accent
        toggle.isOn = AppSettings.boolPref(key, defaultOn)
        toggle.accessibilityIdentifier = key
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [titleLabel(title), toggle])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }

    private func sliderRow(title: String, key: String, min: Float, max: Float) -> UIView {
        let header = UIStackView(arrangedSubviews: [titleLabel(title), valueLabel(for: key)])
        header.axis = .horizontal

        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.minimumTrackTintColor = FPColor.accent
        slider.maximumTrackTintColor = FPColor.stroke
        slider.thumbTintColor = FPColor.accent
        slider.accessibilityIdentifier = key
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [header, slider])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    // MARK: - Values

    private func refreshValues() {
        for (key, label) in valueLabels {
            if let picker = pickers[key] {
                let raw = AppSettings.defaults.string(forKey: key) ?? picker.options.first?.1 ?? ""
                label.text = picker.options.first(where: { $0.1 == raw })?.0 ?? raw
            } else if key == AppSettings.keyChecks {
                let count = (AppSettings.defaults.stringArray(forKey: key) ?? AppSettings.defaultCheckKeys).count
                label.text = "\(count) of \(ActiveCheck.allCases.count)"
            } else {
                label.text = AppSettings.defaults.string(forKey: key) ?? ""
                if let slider = findSlider(key: key) {
                    slider.value = Float(label.text ?? "") ?? slider.minimumValue
                }
            }
        }
    }

    private func findSlider(key: String) -> UISlider? {
        func walk(_ view: UIView) -> UISlider? {
            if let slider = view as? UISlider, slider.accessibilityIdentifier == key { return slider }
            for child in view.subviews { if let found = walk(child) { return found } }
            return nil
        }
        return walk(contentStack)
    }

    // MARK: - Actions

    @objc private func openPicker(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier, let config = pickers[key] else { return }
        let sheet = UIAlertController(title: config.title, message: nil, preferredStyle: .actionSheet)
        for option in config.options {
            sheet.addAction(UIAlertAction(title: option.0, style: .default) { _ in
                AppSettings.defaults.set(option.1, forKey: key)
                self.refreshValues()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func openNumber(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier else { return }
        let alert = UIAlertController(title: nil, message: "Enter a value", preferredStyle: .alert)
        alert.addTextField { field in
            field.keyboardType = .numbersAndPunctuation
            field.text = AppSettings.defaults.string(forKey: key)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let text = (alert.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespaces)
            if !text.isEmpty, Float(text) != nil {
                AppSettings.defaults.set(text, forKey: key)
                self.refreshValues()
            }
        })
        present(alert, animated: true)
    }

    @objc private func openChallenges() {
        navigationController?.pushViewController(ChallengesPickerViewController(), animated: true)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        guard let key = sender.accessibilityIdentifier else { return }
        AppSettings.defaults.set(sender.isOn, forKey: key)
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        guard let key = sender.accessibilityIdentifier else { return }
        let text = String(format: "%.2f", sender.value)
        AppSettings.defaults.set(text, forKey: key)
        valueLabels[key]?.text = text
    }

    @objc private func restoreDefaults() {
        AppSettings.restoreDefaults()
        // Rebuild so toggles/sliders reflect the restored values.
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        valueLabels.removeAll()
        pickers.removeAll()
        buildSections()
        refreshValues()
    }
}

/// The pool the active-liveness sequence is drawn from — one switch per challenge.
/// Mirrors the Android multi-select `active_checks` preference.
final class ChallengesPickerViewController: UIViewController {
    private var selected = Set(AppSettings.defaults.stringArray(forKey: AppSettings.keyChecks) ?? AppSettings.defaultCheckKeys)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FPColor.bg
        title = "Challenges"
        ScreenChrome.showInnerBar(on: self)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, check) in ActiveCheck.allCases.enumerated() {
            let title = UILabel()
            title.text = check.title
            title.textColor = FPColor.text
            title.font = .systemFont(ofSize: 16)
            let toggle = UISwitch()
            toggle.onTintColor = FPColor.accent
            toggle.isOn = selected.contains(check.key)
            toggle.tag = index
            toggle.addTarget(self, action: #selector(challengeToggled(_:)), for: .valueChanged)
            let row = UIStackView(arrangedSubviews: [title, toggle])
            row.axis = .horizontal
            row.alignment = .center
            stack.addArrangedSubview(row)
        }

        let card = UIView()
        card.applyAndroidCardStyle()
        card.addSubview(stack)
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
    }

    @objc private func challengeToggled(_ sender: UISwitch) {
        let checks = ActiveCheck.allCases
        guard sender.tag >= 0, sender.tag < checks.count else { return }
        let key = checks[sender.tag].key
        if sender.isOn { selected.insert(key) } else { selected.remove(key) }
        // Keep the canonical enum order when persisting.
        let ordered = checks.map { $0.key }.filter { selected.contains($0) }
        AppSettings.defaults.set(ordered, forKey: AppSettings.keyChecks)
    }
}

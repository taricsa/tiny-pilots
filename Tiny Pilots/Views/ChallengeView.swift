import UIKit
import SpriteKit

class ChallengeView: UIView {
    
    // MARK: - Properties
    
    // UI Elements
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let codeTextField = UITextField()
    private let submitButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    // Callback for when a challenge code is submitted
    var onSubmit: ((String) -> Void)?
    
    // Callback for when the view is dismissed
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Configure the view
        backgroundColor = UIColor.black.withAlphaComponent(0.9)
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        
        // Add and configure UI elements
        setupTitleLabel()
        setupDescriptionLabel()
        setupCodeTextField()
        setupSubmitButton()
        setupCancelButton()
        setupActivityIndicator()
        setupErrorLabel()
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupTitleLabel() {
        titleLabel.text = "Enter Challenge Code"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel.text = "Enter a challenge code to compete with friends. Challenge codes are valid for 24 hours."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func setupCodeTextField() {
        codeTextField.placeholder = "Enter code (e.g. ABCD-1234)"
        codeTextField.font = UIFont.systemFont(ofSize: 18)
        codeTextField.textColor = .white
        codeTextField.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        codeTextField.layer.cornerRadius = 10
        codeTextField.layer.borderWidth = 1
        codeTextField.layer.borderColor = UIColor.lightGray.cgColor
        codeTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: codeTextField.frame.height))
        codeTextField.leftViewMode = .always
        codeTextField.autocapitalizationType = .allCharacters
        codeTextField.autocorrectionType = .no
        codeTextField.returnKeyType = .done
        codeTextField.delegate = self
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(codeTextField)
        
        NSLayoutConstraint.activate([
            codeTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            codeTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            codeTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            codeTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupSubmitButton() {
        submitButton.setTitle("Submit", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.backgroundColor = UIColor.systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 20),
            submitButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 10),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cancelButton.backgroundColor = UIColor.darkGray
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 10
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -10),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupErrorLabel() {
        errorLabel.text = ""
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func submitButtonTapped() {
        guard let code = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
            showError("Please enter a challenge code")
            return
        }
        
        // Format the code (remove any existing hyphens and add one in the middle)
        let formattedCode = formatChallengeCode(code)
        
        // Show loading indicator
        activityIndicator.startAnimating()
        submitButton.isEnabled = false
        cancelButton.isEnabled = false
        
        // Validate the code
        validateChallengeCode(formattedCode) { [weak self] isValid, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.submitButton.isEnabled = true
                self?.cancelButton.isEnabled = true
                
                if isValid {
                    // Call the submit callback with the formatted code
                    self?.onSubmit?(formattedCode)
                } else {
                    // Show error message
                    if let error = error {
                        self?.showError(error.localizedDescription)
                    } else {
                        self?.showError("Invalid challenge code")
                    }
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismissKeyboard()
        onDismiss?()
    }
    
    @objc private func dismissKeyboard() {
        codeTextField.resignFirstResponder()
    }
    
    // MARK: - Helper Methods
    
    private func formatChallengeCode(_ code: String) -> String {
        // Remove any existing hyphens or spaces
        let cleanCode = code.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        
        // If the code is 8 characters, insert a hyphen in the middle
        if cleanCode.count == 8 {
            let index = cleanCode.index(cleanCode.startIndex, offsetBy: 4)
            return cleanCode[..<index] + "-" + cleanCode[index...]
        }
        
        return cleanCode
    }
    
    private func validateChallengeCode(_ code: String, completion: @escaping (Bool, Error?) -> Void) {
        // Simple challenge code validation (replace with actual GameCenter validation)
        DispatchQueue.global().async {
            // Simulate validation delay
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                // Basic validation - code should be 6-8 characters alphanumeric
                let isValid = code.count >= 6 && code.count <= 8 && code.allSatisfy { $0.isLetter || $0.isNumber }
                completion(isValid, isValid ? nil : NSError(domain: "ChallengeValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid challenge code format"]))
            }
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // Shake animation for error feedback
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.5, 2.5, 0.0]
        codeTextField.layer.add(animation, forKey: "shake")
    }
    
    // MARK: - Public Methods
    
    /// Show the challenge view in the specified view controller
    static func show(in viewController: UIViewController, onSubmit: @escaping (String) -> Void, onDismiss: (() -> Void)? = nil) {
        // Create a container view that covers the entire screen
        let containerView = UIView(frame: viewController.view.bounds)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        containerView.alpha = 0
        
        // Create the challenge view
        let challengeView = ChallengeView(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        challengeView.center = containerView.center
        challengeView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        challengeView.onSubmit = { code in
            // Animate out
            UIView.animate(withDuration: 0.3, animations: {
                containerView.alpha = 0
                challengeView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { _ in
                containerView.removeFromSuperview()
                onSubmit(code)
            })
        }
        challengeView.onDismiss = {
            // Animate out
            UIView.animate(withDuration: 0.3, animations: {
                containerView.alpha = 0
                challengeView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { _ in
                containerView.removeFromSuperview()
                onDismiss?()
            })
        }
        
        // Add views to the hierarchy
        containerView.addSubview(challengeView)
        viewController.view.addSubview(containerView)
        
        // Animate in
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
            challengeView.transform = .identity
        }
    }
}

// MARK: - UITextFieldDelegate

extension ChallengeView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        submitButtonTapped()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Hide error when user starts typing again
        errorLabel.isHidden = true
        
        // Allow only alphanumeric characters, hyphens, and spaces
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "- "))
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
} 
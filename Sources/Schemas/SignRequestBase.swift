import Foundation

/// A request to create a sign request object
public class SignRequestBase: Codable {
    private enum CodingKeys: String, CodingKey {
        case parentFolder = "parent_folder"
        case isDocumentPreparationNeeded = "is_document_preparation_needed"
        case redirectUrl = "redirect_url"
        case declinedRedirectUrl = "declined_redirect_url"
        case areTextSignaturesEnabled = "are_text_signatures_enabled"
        case emailSubject = "email_subject"
        case emailMessage = "email_message"
        case areRemindersEnabled = "are_reminders_enabled"
        case name
        case prefillTags = "prefill_tags"
        case daysValid = "days_valid"
        case externalId = "external_id"
        case isPhoneVerificationRequiredToView = "is_phone_verification_required_to_view"
        case templateId = "template_id"
    }

    public let parentFolder: FolderMini
    /// Indicates if the sender should receive a `prepare_url` in the response to complete document preparation via UI.
    public let isDocumentPreparationNeeded: Bool?
    /// When specified, signature request will be redirected to this url when a document is signed.
    public let redirectUrl: String?
    /// The uri that a signer will be redirected to after declining to sign a document.
    public let declinedRedirectUrl: String?
    /// Disables the usage of signatures generated by typing (text).
    public let areTextSignaturesEnabled: Bool?
    /// Subject of sign request email. This is cleaned by sign request. If this field is not passed, a default subject will be used.
    public let emailSubject: String?
    /// Message to include in sign request email. The field is cleaned through sanitization of specific characters. However, some html tags are allowed. Links included in the message are also converted to hyperlinks in the email. The message may contain the following html tags including `a`, `abbr`, `acronym`, `b`, `blockquote`, `code`, `em`, `i`, `ul`, `li`, `ol`, and `strong`. Be aware that when the text to html ratio is too high, the email may end up in spam filters. Custom styles on these tags are not allowed. If this field is not passed, a default message will be used.
    public let emailMessage: String?
    /// Reminds signers to sign a document on day 3, 8, 13 and 18. Reminders are only sent to outstanding signers.
    public let areRemindersEnabled: Bool?
    /// Name of the sign request.
    public let name: String?
    /// When a document contains sign related tags in the content, you can prefill them using this `prefill_tags` by referencing the 'id' of the tag as the `external_id` field of the prefill tag.
    public let prefillTags: [SignRequestPrefillTag]?
    /// Set the number of days after which the created signature request will automatically expire if not completed. By default, we do not apply any expiration date on signature requests, and the signature request does not expire.
    public let daysValid: Int?
    /// This can be used to reference an ID in an external system that the sign request is related to.
    public let externalId: String?
    /// Forces signers to verify a text message prior to viewing the document. You must specify the phone number of signers to have this setting apply to them.
    public let isPhoneVerificationRequiredToView: Bool?
    /// When a signature request is created from a template this field will indicate the id of that template.
    public let templateId: String?

    /// Initializer for a SignRequestBase.
    ///
    /// - Parameters:
    ///   - parentFolder: FolderMini
    ///   - isDocumentPreparationNeeded: Indicates if the sender should receive a `prepare_url` in the response to complete document preparation via UI.
    ///   - redirectUrl: When specified, signature request will be redirected to this url when a document is signed.
    ///   - declinedRedirectUrl: The uri that a signer will be redirected to after declining to sign a document.
    ///   - areTextSignaturesEnabled: Disables the usage of signatures generated by typing (text).
    ///   - emailSubject: Subject of sign request email. This is cleaned by sign request. If this field is not passed, a default subject will be used.
    ///   - emailMessage: Message to include in sign request email. The field is cleaned through sanitization of specific characters. However, some html tags are allowed. Links included in the message are also converted to hyperlinks in the email. The message may contain the following html tags including `a`, `abbr`, `acronym`, `b`, `blockquote`, `code`, `em`, `i`, `ul`, `li`, `ol`, and `strong`. Be aware that when the text to html ratio is too high, the email may end up in spam filters. Custom styles on these tags are not allowed. If this field is not passed, a default message will be used.
    ///   - areRemindersEnabled: Reminds signers to sign a document on day 3, 8, 13 and 18. Reminders are only sent to outstanding signers.
    ///   - name: Name of the sign request.
    ///   - prefillTags: When a document contains sign related tags in the content, you can prefill them using this `prefill_tags` by referencing the 'id' of the tag as the `external_id` field of the prefill tag.
    ///   - daysValid: Set the number of days after which the created signature request will automatically expire if not completed. By default, we do not apply any expiration date on signature requests, and the signature request does not expire.
    ///   - externalId: This can be used to reference an ID in an external system that the sign request is related to.
    ///   - isPhoneVerificationRequiredToView: Forces signers to verify a text message prior to viewing the document. You must specify the phone number of signers to have this setting apply to them.
    ///   - templateId: When a signature request is created from a template this field will indicate the id of that template.
    public init(parentFolder: FolderMini, isDocumentPreparationNeeded: Bool? = nil, redirectUrl: String? = nil, declinedRedirectUrl: String? = nil, areTextSignaturesEnabled: Bool? = nil, emailSubject: String? = nil, emailMessage: String? = nil, areRemindersEnabled: Bool? = nil, name: String? = nil, prefillTags: [SignRequestPrefillTag]? = nil, daysValid: Int? = nil, externalId: String? = nil, isPhoneVerificationRequiredToView: Bool? = nil, templateId: String? = nil) {
        self.parentFolder = parentFolder
        self.isDocumentPreparationNeeded = isDocumentPreparationNeeded
        self.redirectUrl = redirectUrl
        self.declinedRedirectUrl = declinedRedirectUrl
        self.areTextSignaturesEnabled = areTextSignaturesEnabled
        self.emailSubject = emailSubject
        self.emailMessage = emailMessage
        self.areRemindersEnabled = areRemindersEnabled
        self.name = name
        self.prefillTags = prefillTags
        self.daysValid = daysValid
        self.externalId = externalId
        self.isPhoneVerificationRequiredToView = isPhoneVerificationRequiredToView
        self.templateId = templateId
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentFolder = try container.decode(FolderMini.self, forKey: .parentFolder)
        isDocumentPreparationNeeded = try container.decodeIfPresent(Bool.self, forKey: .isDocumentPreparationNeeded)
        redirectUrl = try container.decodeIfPresent(String.self, forKey: .redirectUrl)
        declinedRedirectUrl = try container.decodeIfPresent(String.self, forKey: .declinedRedirectUrl)
        areTextSignaturesEnabled = try container.decodeIfPresent(Bool.self, forKey: .areTextSignaturesEnabled)
        emailSubject = try container.decodeIfPresent(String.self, forKey: .emailSubject)
        emailMessage = try container.decodeIfPresent(String.self, forKey: .emailMessage)
        areRemindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .areRemindersEnabled)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        prefillTags = try container.decodeIfPresent([SignRequestPrefillTag].self, forKey: .prefillTags)
        daysValid = try container.decodeIfPresent(Int.self, forKey: .daysValid)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        isPhoneVerificationRequiredToView = try container.decodeIfPresent(Bool.self, forKey: .isPhoneVerificationRequiredToView)
        templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parentFolder, forKey: .parentFolder)
        try container.encodeIfPresent(isDocumentPreparationNeeded, forKey: .isDocumentPreparationNeeded)
        try container.encodeIfPresent(redirectUrl, forKey: .redirectUrl)
        try container.encodeIfPresent(declinedRedirectUrl, forKey: .declinedRedirectUrl)
        try container.encodeIfPresent(areTextSignaturesEnabled, forKey: .areTextSignaturesEnabled)
        try container.encodeIfPresent(emailSubject, forKey: .emailSubject)
        try container.encodeIfPresent(emailMessage, forKey: .emailMessage)
        try container.encodeIfPresent(areRemindersEnabled, forKey: .areRemindersEnabled)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(prefillTags, forKey: .prefillTags)
        try container.encodeIfPresent(daysValid, forKey: .daysValid)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(isPhoneVerificationRequiredToView, forKey: .isPhoneVerificationRequiredToView)
        try container.encodeIfPresent(templateId, forKey: .templateId)
    }
}

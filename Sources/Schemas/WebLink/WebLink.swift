import Foundation

/// Web links are objects that point to URLs. These objects
/// are also known as bookmarks within the Box web application.
/// 
/// Web link objects are treated similarly to file objects,
/// they will also support most actions that apply to regular files.
public class WebLink: WebLinkMini {
    private enum CodingKeys: String, CodingKey {
        case parent
        case description
        case pathCollection = "path_collection"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case trashedAt = "trashed_at"
        case purgedAt = "purged_at"
        case createdBy = "created_by"
        case modifiedBy = "modified_by"
        case ownedBy = "owned_by"
        case sharedLink = "shared_link"
        case itemStatus = "item_status"
    }

    public let parent: FolderMini?

    /// The description accompanying the web link. This is
    /// visible within the Box web application.
    public let description: String?

    public let pathCollection: WebLinkPathCollectionField?

    /// When this file was created on Box’s servers.
    public let createdAt: Date?

    /// When this file was last updated on the Box
    /// servers.
    public let modifiedAt: Date?

    /// When this file was moved to the trash.
    public let trashedAt: Date?

    /// When this file will be permanently deleted.
    public let purgedAt: Date?

    public let createdBy: UserMini?

    public let modifiedBy: UserMini?

    public let ownedBy: UserMini?

    public let sharedLink: WebLinkSharedLinkField?

    /// Whether this item is deleted or not. Values include `active`,
    /// `trashed` if the file has been moved to the trash, and `deleted` if
    /// the file has been permanently deleted
    public let itemStatus: WebLinkItemStatusField?

    /// Initializer for a WebLink.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this web link
    ///   - type: `web_link`
    ///   - etag: The entity tag of this web link. Used with `If-Match`
    ///     headers.
    ///   - url: The URL this web link points to
    ///   - sequenceId: 
    ///   - name: The name of the web link
    ///   - parent: 
    ///   - description: The description accompanying the web link. This is
    ///     visible within the Box web application.
    ///   - pathCollection: 
    ///   - createdAt: When this file was created on Box’s servers.
    ///   - modifiedAt: When this file was last updated on the Box
    ///     servers.
    ///   - trashedAt: When this file was moved to the trash.
    ///   - purgedAt: When this file will be permanently deleted.
    ///   - createdBy: 
    ///   - modifiedBy: 
    ///   - ownedBy: 
    ///   - sharedLink: 
    ///   - itemStatus: Whether this item is deleted or not. Values include `active`,
    ///     `trashed` if the file has been moved to the trash, and `deleted` if
    ///     the file has been permanently deleted
    public init(id: String, type: WebLinkBaseTypeField = WebLinkBaseTypeField.webLink, etag: String? = nil, url: String? = nil, sequenceId: String? = nil, name: String? = nil, parent: FolderMini? = nil, description: String? = nil, pathCollection: WebLinkPathCollectionField? = nil, createdAt: Date? = nil, modifiedAt: Date? = nil, trashedAt: Date? = nil, purgedAt: Date? = nil, createdBy: UserMini? = nil, modifiedBy: UserMini? = nil, ownedBy: UserMini? = nil, sharedLink: WebLinkSharedLinkField? = nil, itemStatus: WebLinkItemStatusField? = nil) {
        self.parent = parent
        self.description = description
        self.pathCollection = pathCollection
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.trashedAt = trashedAt
        self.purgedAt = purgedAt
        self.createdBy = createdBy
        self.modifiedBy = modifiedBy
        self.ownedBy = ownedBy
        self.sharedLink = sharedLink
        self.itemStatus = itemStatus

        super.init(id: id, type: type, etag: etag, url: url, sequenceId: sequenceId, name: name)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parent = try container.decodeIfPresent(FolderMini.self, forKey: .parent)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        pathCollection = try container.decodeIfPresent(WebLinkPathCollectionField.self, forKey: .pathCollection)
        if let _createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = try Utils.Dates.dateTimeFromString(dateTime: _createdAt)
        } else {
            createdAt = nil
        }

        if let _modifiedAt = try container.decodeIfPresent(String.self, forKey: .modifiedAt) {
            modifiedAt = try Utils.Dates.dateTimeFromString(dateTime: _modifiedAt)
        } else {
            modifiedAt = nil
        }

        if let _trashedAt = try container.decodeIfPresent(String.self, forKey: .trashedAt) {
            trashedAt = try Utils.Dates.dateTimeFromString(dateTime: _trashedAt)
        } else {
            trashedAt = nil
        }

        if let _purgedAt = try container.decodeIfPresent(String.self, forKey: .purgedAt) {
            purgedAt = try Utils.Dates.dateTimeFromString(dateTime: _purgedAt)
        } else {
            purgedAt = nil
        }

        createdBy = try container.decodeIfPresent(UserMini.self, forKey: .createdBy)
        modifiedBy = try container.decodeIfPresent(UserMini.self, forKey: .modifiedBy)
        ownedBy = try container.decodeIfPresent(UserMini.self, forKey: .ownedBy)
        sharedLink = try container.decodeIfPresent(WebLinkSharedLinkField.self, forKey: .sharedLink)
        itemStatus = try container.decodeIfPresent(WebLinkItemStatusField.self, forKey: .itemStatus)

        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(parent, forKey: .parent)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(pathCollection, forKey: .pathCollection)
        if let createdAt {
            try container.encode(Utils.Dates.dateTimeToString(dateTime: createdAt), forKey: .createdAt)
        }

        if let modifiedAt {
            try container.encode(Utils.Dates.dateTimeToString(dateTime: modifiedAt), forKey: .modifiedAt)
        }

        if let trashedAt {
            try container.encode(Utils.Dates.dateTimeToString(dateTime: trashedAt), forKey: .trashedAt)
        }

        if let purgedAt {
            try container.encode(Utils.Dates.dateTimeToString(dateTime: purgedAt), forKey: .purgedAt)
        }

        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(modifiedBy, forKey: .modifiedBy)
        try container.encodeIfPresent(ownedBy, forKey: .ownedBy)
        try container.encodeIfPresent(sharedLink, forKey: .sharedLink)
        try container.encodeIfPresent(itemStatus, forKey: .itemStatus)
        try super.encode(to: encoder)
    }

}

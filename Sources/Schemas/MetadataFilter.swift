import Foundation

/// A metadata template to filter the search results by.
public class MetadataFilter: Codable {
    private enum CodingKeys: String, CodingKey {
        case scope
        case templateKey
        case filters
    }

    /// Specifies the scope of the template to filter search results by.
    /// 
    /// This will be `enterprise_{enterprise_id}` for templates defined
    /// for use in this enterprise, and `global` for general templates
    /// that are available to all enterprises using Box.
    public let scope: MetadataFilterScopeField?
    /// The key of the template to filter search results by.
    /// 
    /// In many cases the template key is automatically derived
    /// of its display name, for example `Contract Template` would
    /// become `contractTemplate`. In some cases the creator of the
    /// template will have provided its own template key.
    /// 
    /// Please [list the templates for an enterprise][list], or
    /// get all instances on a [file][file] or [folder][folder]
    /// to inspect a template's key.
    /// 
    /// [list]: e://get-metadata-templates-enterprise
    /// [file]: e://get-files-id-metadata
    /// [folder]: e://get-folders-id-metadata
    public let templateKey: String?
    public let filters: MetadataFilterFiltersField?

    /// Initializer for a MetadataFilter.
    ///
    /// - Parameters:
    ///   - scope: Specifies the scope of the template to filter search results by.
    ///     
    ///     This will be `enterprise_{enterprise_id}` for templates defined
    ///     for use in this enterprise, and `global` for general templates
    ///     that are available to all enterprises using Box.
    ///   - templateKey: The key of the template to filter search results by.
    ///     
    ///     In many cases the template key is automatically derived
    ///     of its display name, for example `Contract Template` would
    ///     become `contractTemplate`. In some cases the creator of the
    ///     template will have provided its own template key.
    ///     
    ///     Please [list the templates for an enterprise][list], or
    ///     get all instances on a [file][file] or [folder][folder]
    ///     to inspect a template's key.
    ///     
    ///     [list]: e://get-metadata-templates-enterprise
    ///     [file]: e://get-files-id-metadata
    ///     [folder]: e://get-folders-id-metadata
    ///   - filters: MetadataFilterFiltersField?
    public init(scope: MetadataFilterScopeField? = nil, templateKey: String? = nil, filters: MetadataFilterFiltersField? = nil) {
        self.scope = scope
        self.templateKey = templateKey
        self.filters = filters
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scope = try container.decodeIfPresent(MetadataFilterScopeField.self, forKey: .scope)
        templateKey = try container.decodeIfPresent(String.self, forKey: .templateKey)
        filters = try container.decodeIfPresent(MetadataFilterFiltersField.self, forKey: .filters)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(scope, forKey: .scope)
        try container.encodeIfPresent(templateKey, forKey: .templateKey)
        try container.encodeIfPresent(filters, forKey: .filters)
    }
}

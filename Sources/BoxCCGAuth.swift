import Foundation

/// Configuration for Server Authentication with Client Credentials Grant
public class CCGConfig {

    /// The client ID of the application requesting authentication
    public let clientId: String

    /// The Box client secret of the application requesting authentication
    public let clientSecret: String

    /// The ID of the Box Developer Edition enterprise
    public let enterpriseId: String?

    /// The user id to authenticate
    public let userId: String?

    ///Object responsible for storing token.
    public let tokenStorage: TokenStorage

    ///  Initializer
    ///
    /// - Parameters:
    /// - clientId: The client ID of the application requesting authentication.
    /// - clientSecret: The Box client secret of the application requesting authentication
    /// - enterpriseId: The ID of the Box Developer Edition enterprise.
    ///   This param may be `nil`, if the caller knows that it will not be authenticating as an enterprise instance / service account.
    ///   If `userId` is passed, this value is not used.
    /// - userId: The user id to authenticate.  This value is not required, but if it is provided, then the user  will be auto-authenticated at the time of the first API call.
    ///   Should be set to `nil` if the intention is to authenticate as the  enterprise instance / service account. If both `enterprise_id` and
    ///   `userId` are non-`nil`, the `user` takes precedense when `refreshToken()` is called.
    /// - tokenStorage: Object responsible for storing token. If no custom implementation provided, the token will be stored in memory.
    public init(
        clientId: String,
        clientSecret: String,
        enterpriseId: String? = nil,
        userId: String? = nil,
        tokenStorage: TokenStorage = InMemoryTokenStorage()
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.enterpriseId = enterpriseId
        self.userId = userId
        self.tokenStorage = tokenStorage
    }

    ///  Initializer
    ///
    /// - Parameters:
    /// - clientId: The client ID of the application requesting authentication.
    /// - clientSecret: The Box client secret of the application requesting authentication
    /// - enterpriseId: The ID of the Box Developer Edition enterprise.
    /// - tokenStorage: Object responsible for storing token. If no custom implementation provided, the token will be stored in memory.
    convenience public init(
        clientId: String,
        clientSecret: String,
        enterpriseId: String,
        tokenStorage: TokenStorage = InMemoryTokenStorage()
    ) {
        self.init(clientId: clientId, clientSecret: clientSecret, enterpriseId: enterpriseId, userId: nil, tokenStorage: tokenStorage)
    }

    ///  Initializer
    ///
    /// - Parameters:
    /// - clientId: The client ID of the application requesting authentication.
    /// - clientSecret: The Box client secret of the application requesting authentication
    /// - userId: The user id to authenticate.  This value is not required, but if it is provided, then the user  will be auto-authenticated at the time of the first API call.
    /// - tokenStorage: Object responsible for storing token. If no custom implementation provided, the token will be stored in memory.
    convenience public init(
        clientId: String,
        clientSecret: String,
        userId: String,
        tokenStorage: TokenStorage = InMemoryTokenStorage()
    ) {
        self.init(clientId: clientId, clientSecret: clientSecret, enterpriseId: nil, userId: userId, tokenStorage: tokenStorage)
    }
}

/// Server Authentication with Client Credentials Grant
public class BoxCCGAuth: Authentication {

    /// Configuration object of Client Credentials Grant auth.
    public let config: CCGConfig

    /// `box_subject_id` used in requesting CCG access token
    public private(set) var subjectId: String?

    /// `box_subject_type` used in requesting CCG access token
    public private(set) var subjectType: TokenBoxSubjectType?

    /// Token storage
    public let tokenStorage: TokenStorage

    /// Initializer
    ///
    /// - Parameters:
    ///   - config: Configuration object of Client Credentials Grant auth
    /// - Throws: The GeneralError if neither `userId` nor `enterpriseId` is set.
    public init(config: CCGConfig) {
        if let userId = config.userId {
            self.subjectId = userId
            self.subjectType = TokenBoxSubjectType.user
        } else if let enterpriseId = config.enterpriseId {
            self.subjectId = enterpriseId
            self.subjectType = TokenBoxSubjectType.enterprise
        }

        self.config = config
        self.tokenStorage = config.tokenStorage
    }

    /// Return a current access token or get a new one when not available.
    ///
    /// - Parameters:
    ///   - networkSession: The Networking Session object which  provides the URLSession
    /// - Returns: The access
    /// - Throws: An error if for any reason the token cannot be fetched.
    public func retrieveToken(networkSession: NetworkSession? = nil) async throws -> AccessToken {
        let token = try await self.tokenStorage.get()
        if let token {
            return token
        }

        return try await refreshToken(networkSession: networkSession)
    }

    /// Refresh token
    ///
    /// - Parameters:
    ///   - networkSession: The Networking Session object  which  provides the URLSession
    /// - Returns: The refreshed access
    /// - Throws: An error if for any reason the token cannot be refreshed.
    public func refreshToken(networkSession: NetworkSession? = nil) async throws -> AccessToken {
        let (subjectId, subjectType) = try guardAuthParameters()
        let params: [String: String] = [
            "grant_type": TokenGrantType.clientCredentials.rawValue,
            "client_id": self.config.clientId,
            "client_secret": self.config.clientSecret,
            "box_subject_id": subjectId,
            "box_subject_type": subjectType.rawValue
        ]

        let response: FetchResponse = try await NetworkClient.shared.fetch(
            url: "https://api.box.com/oauth2/token",
            options: FetchOptions(
                method: .post,
                body: Utils.Url.urlEncodeFrom(dictionary: params),
                contentType: "application/x-www-form-urlencoded",
                networkSession: networkSession
            )
        )

        let newToken = try AccessToken.decode(from: response.content)
        try await self.tokenStorage.store(token: newToken)
        return newToken
    }

    /// Set authentication as user. The new token will be automatically fetched with a next API.
    ///
    /// May be one of this application's created App User. Depending on the
    /// configured User Access Level, may also be any other App User or Managed User in the enterprise.
    ///
    /// - Parameters:
    ///   - userId: The id of the user to authenticate.
    public func asUser(userId: String) async throws {
        self.subjectId = userId
        self.subjectType = .user
        try await self.tokenStorage.clear()
    }

    /// Set authentication as enterprise. The new token will be automatically fetched with a next API call.
    ///
    /// - Parameters:
    ///   - userId: The ID of the Box Developer Edition enterprise.
    public func asEnterprise(enterpriseId: String) async throws {
        self.subjectId = enterpriseId
        self.subjectType = .enterprise
        try await self.tokenStorage.clear()
    }

    /// Ensure that required parameters are present.
    ///
    /// - Returns: A tuple with valid subjectId and subjectType
    /// - Throws: An error if for any required params are not present.
    func guardAuthParameters() throws -> (String, TokenBoxSubjectType) {
        guard let subjectId = self.subjectId, let subjectType = self.subjectType else {
            throw AuthError(message: .authorizationInitialization("Either enterpriseId or userId must be set when creating BoxCCGAuth."))
        }

        return (subjectId, subjectType)
    }
}

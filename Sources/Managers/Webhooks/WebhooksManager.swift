import Foundation

public class WebhooksManager {
    public let auth: Authentication?
    public let networkSession: NetworkSession?

    public init(auth: Authentication? = nil, networkSession: NetworkSession? = nil) {
        self.auth = auth
        self.networkSession = networkSession
    }

    /// Returns all defined webhooks for the requesting application.
    /// 
    /// This API only returns webhooks that are applied to files or folders that are
    /// owned by the authenticated user. This means that an admin can not see webhooks
    /// created by a service account unless the admin has access to those folders, and
    /// vice versa.
    ///
    /// - Parameters:
    ///   - queryParams: Query parameters of getWebhooks method
    ///   - headers: Headers of getWebhooks method
    /// - Returns: The `Webhooks`.
    /// - Throws: The `GeneralError`.
    public func getWebhooks(queryParams: GetWebhooksQueryParamsArg = GetWebhooksQueryParamsArg(), headers: GetWebhooksHeadersArg = GetWebhooksHeadersArg()) async throws -> Webhooks {
        let queryParamsMap: [String: String] = Utils.Dictionary.prepareParams(map: ["marker": Utils.Strings.toString(value: queryParams.marker), "limit": Utils.Strings.toString(value: queryParams.limit)])
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/webhooks")", options: FetchOptions(method: "GET", params: queryParamsMap, headers: headersMap, responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try Webhooks.deserialize(from: response.text)
    }

    /// Creates a webhook.
    ///
    /// - Parameters:
    ///   - requestBody: Request body of createWebhook method
    ///   - headers: Headers of createWebhook method
    /// - Returns: The `Webhook`.
    /// - Throws: The `GeneralError`.
    public func createWebhook(requestBody: CreateWebhookRequestBodyArg, headers: CreateWebhookHeadersArg = CreateWebhookHeadersArg()) async throws -> Webhook {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/webhooks")", options: FetchOptions(method: "POST", headers: headersMap, body: requestBody.serialize(), contentType: "application/json", responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try Webhook.deserialize(from: response.text)
    }

    /// Retrieves a specific webhook
    ///
    /// - Parameters:
    ///   - webhookId: The ID of the webhook.
    ///     Example: "3321123"
    ///   - headers: Headers of getWebhookById method
    /// - Returns: The `Webhook`.
    /// - Throws: The `GeneralError`.
    public func getWebhookById(webhookId: String, headers: GetWebhookByIdHeadersArg = GetWebhookByIdHeadersArg()) async throws -> Webhook {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/webhooks/")\(webhookId)", options: FetchOptions(method: "GET", headers: headersMap, responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try Webhook.deserialize(from: response.text)
    }

    /// Updates a webhook.
    ///
    /// - Parameters:
    ///   - webhookId: The ID of the webhook.
    ///     Example: "3321123"
    ///   - requestBody: Request body of updateWebhookById method
    ///   - headers: Headers of updateWebhookById method
    /// - Returns: The `Webhook`.
    /// - Throws: The `GeneralError`.
    public func updateWebhookById(webhookId: String, requestBody: UpdateWebhookByIdRequestBodyArg = UpdateWebhookByIdRequestBodyArg(), headers: UpdateWebhookByIdHeadersArg = UpdateWebhookByIdHeadersArg()) async throws -> Webhook {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/webhooks/")\(webhookId)", options: FetchOptions(method: "PUT", headers: headersMap, body: requestBody.serialize(), contentType: "application/json", responseFormat: "json", auth: self.auth, networkSession: self.networkSession))
        return try Webhook.deserialize(from: response.text)
    }

    /// Deletes a webhook.
    ///
    /// - Parameters:
    ///   - webhookId: The ID of the webhook.
    ///     Example: "3321123"
    ///   - headers: Headers of deleteWebhookById method
    /// - Throws: The `GeneralError`.
    public func deleteWebhookById(webhookId: String, headers: DeleteWebhookByIdHeadersArg = DeleteWebhookByIdHeadersArg()) async throws {
        let headersMap: [String: String] = Utils.Dictionary.prepareParams(map: Utils.Dictionary.merge([:], headers.extraHeaders))
        let response: FetchResponse = try await NetworkClient.shared.fetch(url: "\("https://api.box.com/2.0/webhooks/")\(webhookId)", options: FetchOptions(method: "DELETE", headers: headersMap, responseFormat: nil, auth: self.auth, networkSession: self.networkSession))
    }

}

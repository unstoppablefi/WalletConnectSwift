//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct WCURL: Hashable, CustomStringConvertible {

    public var bridgeURL: URL
    public var topic: String
    public var key: String

    public var description: String {
        return "bridge: \(bridgeURL.absoluteString); topic: \(topic); key: \(key)"
    }

}

/// Session is a connection between dApp and Wallet
public struct Session {

    public var url: WCURL
    public var peerId: String
    public var clientMeta: ClientMeta

    public struct ClientMeta: Codable {

        var name: String
        var description: String
        var icons: [URL]
        var url: URL

    }

    public struct Info: Codable {

        public var approved: Bool
        public var accounts: [String]
        public var chainId: Int

    }

    enum SessionCreationError: Error {
        case wrongRequestFormat
    }

    /// https://docs.walletconnect.org/tech-spec#session-request
    init?(wcSessionRequest request: Request) throws {
        struct ParamsArrayWrapper: Codable {
            var peerId: String
            var peerMeta: ClientMeta
        }
        let data = try JSONEncoder().encode(request.payload.params)
        let array = try JSONDecoder().decode([ParamsArrayWrapper].self, from: data)
        guard array.count == 1 else { throw SessionCreationError.wrongRequestFormat }
        let wrapper = array[0]
        self.url = request.url
        self.peerId = wrapper.peerId
        self.clientMeta = wrapper.peerMeta
    }

    func creationResponse(requestId: JSONRPC_2_0.IDType, info: Session.Info) -> Response {
        let infoValueData = try! JSONEncoder().encode(info)
        let infoValue = try! JSONDecoder().decode(JSONRPC_2_0.ValueType.self, from: infoValueData)
        let result = JSONRPC_2_0.Response.Payload.value(infoValue)
        let JSONRPCResponse = JSONRPC_2_0.Response(result: result, id: requestId)
        return Response(payload: JSONRPCResponse, url: self.url)
    }

}
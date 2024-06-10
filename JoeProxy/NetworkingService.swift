import Foundation
import NIO
import NIOSSL
import NIOHTTP1

protocol NetworkingService {
    func startServer(completion: @escaping (Result<Void, Error>) -> Void) throws
    func stopServer(completion: @escaping (Result<Void, Error>) -> Void) throws
}

class DefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    private let certificateService: CertificateService

    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService, certificateService: CertificateService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
        self.certificateService = certificateService
    }

    func startServer(completion: @escaping (Result<Void, Error>) -> Void) throws {
        print("Starting SSL server setup...")
        
        // Ensure the certificate and PEM files exist
        if !FileManager.default.fileExists(atPath: certificateService.certificateURL.path) || !FileManager.default.fileExists(atPath: certificateService.pemURL.path) {
            print("Certificate and/or PEM files are missing at paths:")
            print("Certificate path: \(certificateService.certificateURL.path)")
            print("PEM path: \(certificateService.pemURL.path)")
            completion(.failure(NSError(domain: "SSLServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Certificate and/or PEM files are missing"])))
            return
        }

        let certificateURL = certificateService.certificateURL
        let pemURL = certificateService.pemURL
        print("Certificate path: \(certificateURL)")
        print("PEM path: \(pemURL)")

        // Create SSL context
        let sslContext: NIOSSLContext
        do {
            let certChain = try NIOSSLCertificate.fromPEMFile(certificateURL.path)
            let key = try NIOSSLPrivateKey(file: pemURL.path, format: .pem)
            let tlsConfig = TLSConfiguration.forServer(certificateChain: certChain.map { .certificate($0) }, privateKey: .privateKey(key))
            sslContext = try NIOSSLContext(configuration: tlsConfig)
            print("SSL context created successfully.")
        } catch {
            print("Failed to create SSL context: \(error)")
            completion(.failure(error))
            return
        }
        
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                print("Initializing child channel...")
                return channel.pipeline.addHandler(NIOSSLServerHandler(context: sslContext)).flatMap {
                    channel.pipeline.addHTTPServerHandlers().flatMap {
                        channel.pipeline.addHandler(SSLHandler(filteringService: self.filteringService, loggingService: self.loggingService))
                    }
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        do {
            channel = try bootstrap.bind(host: "localhost", port: 8443).wait()
            print("Server started and listening on \(String(describing: channel?.localAddress))")
            completion(.success(()))
        } catch {
            print("Failed to start server: \(error)")
            completion(.failure(error))
        }
    }

    func stopServer(completion: @escaping (Result<Void, Error>) -> Void) {
        print("Stopping SSL server...")
        do {
            try channel?.close().wait()
            try group?.syncShutdownGracefully()
            print("Server stopped.")
            completion(.success(()))
        } catch {
            print("Failed to stop server: \(error)")
            completion(.failure(error))
        }
    }
}

extension ChannelPipeline {
    func addHTTPServerHandlers() -> EventLoopFuture<Void> {
        return self.addHandler(HTTPServerPipelineHandler()).flatMap {
            self.addHandler(HTTPResponseEncoder()).flatMap {
                self.addHandler(ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)))
            }
        }
    }
}

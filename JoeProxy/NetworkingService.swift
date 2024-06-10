import Foundation
import NIO
import NIOSSL
import NIOHTTP1

protocol NetworkingService {
    func startServer(completion: @escaping (Result<Void, Error>) -> Void) throws
    func stopServer(completion: @escaping (Result<Void, Error>) -> Void)
}

class DefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private var group: MultiThreadedEventLoopGroup?
    var channel: Channel?
    private let certificateService: CertificateService
    private let fileIO: NonBlockingFileIO
    
    private(set) var serverIP: String?
    private(set) var serverPort: Int?
    
    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService, certificateService: CertificateService, fileIO: NonBlockingFileIO) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
        self.certificateService = certificateService
        self.fileIO = fileIO
    }
    
    func startServer(completion: @escaping (Result<Void, Error>) -> Void) throws {
        print("Starting SSL server setup...")
        
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
        
        let sslContext: NIOSSLContext
        do {
            let certChain = try NIOSSLCertificate.fromPEMFile(certificateURL.path)
            let key = try NIOSSLPrivateKey(file: pemURL.path, format: .pem)
            let tlsConfig = TLSConfiguration.makeServerConfiguration(certificateChain: certChain.map { .certificate($0) }, privateKey: .privateKey(key))
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
                    channel.pipeline.addHandler(HTTPResponseEncoder()).flatMap {
                        channel.pipeline.addHandler(ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes))).flatMap {
                            channel.pipeline.addHandler(HTTPServerPipelineHandler())
                        }
                    }
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        
        do {
            channel = try bootstrap.bind(host: "localhost", port: 0).wait() // Bind to port 0 for dynamic port assignment
            if let localAddress = channel?.localAddress, let assignedPort = localAddress.port {
                serverPort = assignedPort
                switch localAddress {
                case .v4(let address):
                    serverIP = address.host
                case .v6(let address):
                    serverIP = address.host
                default:
                    break
                }
                print("Server started and listening on \(localAddress) serverIP \(serverIP) serverPort \(serverPort)")
                
            }
            completion(.success(()))
        } catch {
            print("Failed to start server: \(error)")
            completion(.failure(error))
        }
    }
    
    func stopServer(completion: @escaping (Result<Void, Error>) -> Void) {
        print("Stopping SSL server...")
        guard let channel = channel else {
            completion(.success(()))
            return
        }

        // Close the channel and handle the shutdown gracefully
        channel.close().whenComplete { [weak self] result in
            guard let self = self else {
                completion(.success(()))
                return
            }

            self.group!.shutdownGracefully { error in
                if let error = error {
                    print("Failed to stop server: \(error)")
                    completion(.failure(error))
                } else {
                    print("Server stopped.")
                    completion(.success(()))
                }
            }
        }
    }
    
//    private func makeDummyFuture() -> EventLoopFuture<Void> {
//        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let promise = eventLoopGroup.next().makePromise(of: Void.self)
//        promise.succeed(())
//        return promise.futureResult
//    }
}

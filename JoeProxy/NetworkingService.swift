import Foundation
import NIO
import NIOSSL

protocol NetworkingService {
    func startServer() throws
    func stopServer() throws
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

    func startServer() throws {
        print("Starting SSL server setup...")
        
        // Ensure the certificate and PEM files exist
        guard FileManager.default.fileExists(atPath: certificateService.certificateURL.path),
              FileManager.default.fileExists(atPath: certificateService.pemURL.path) else {
            print("Certificate and/or PEM files are missing at paths:")
            print("Certificate path: \(certificateService.certificateURL.path)")
            print("PEM path: \(certificateService.pemURL.path)")
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
            throw error
        }
        
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                print("Initializing child channel...")
                return channel.pipeline.addHandler(NIOSSLServerHandler(context: sslContext)).flatMap {
                    channel.pipeline.addHandler(SSLHandler(filteringService: self.filteringService, loggingService: self.loggingService))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        do {
            channel = try bootstrap.bind(host: "localhost", port: 8443).wait()
            print("Server started and listening on \(String(describing: channel?.localAddress))")
        } catch {
            print("Failed to start server: \(error)")
            group = nil
            throw error
        }
    }

    func stopServer() throws {
        print("Stopping SSL server...")
        defer {
            group = nil
            channel = nil
        }
        do {
            try channel?.close().wait()
            try group?.syncShutdownGracefully()
            print("Server stopped.")
        } catch {
            print("Failed to stop server gracefully: \(error)")
            throw error
        }
    }
}

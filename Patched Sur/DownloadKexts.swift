//
//  DownloadKexts.swift
//  Patched Sur

//
//  Created by Benjamin Sova on 12/08/20.
//

import SwiftUI
import Files
import SwiftShell

struct DownloadView: View {
    @State var downloadStatus = "Downloading Kexts..."
    @State var setVarsTool: Data?
    @State var setVarsZip: File?
    @State var setVarsSave: Folder?
    @Binding var p: Int
    @State var buttonBG = Color.red
    @State var downloadSize = 553578200
    @State var installSize = 21382031300000
    @State var downloadProgress = CGFloat(0)
    @State var installProgress = CGFloat(0)
    @State var currentSize = 10
    @Binding var installInfo: InstallAssistant?
    @State var kextDownloaded = false
    let timer = Timer.publish(every: 0.25, on: .current, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Downloading Kexts and macOS").bold()
            Text("The kext patches allow you to use hardware like WiFi and USB ports, so that your Mac stays at its full functionality. macOS is being downloaded straight from Apple, in the form of an InstallAssistant.pkg file. With this, we can extract out the Installer app then start a macOS install.")
                .padding(10)
                .multilineTextAlignment(.center)
            if downloadStatus == "Downloading Kexts..." {
                VStack {
                    ZStack {
                        if kextDownloaded {
                            Color.secondary
                                .frame(width: 230)
                                .cornerRadius(10)
                        } else {
                            ProgressBar(value: $downloadProgress, length: 230)
                                .onReceive(timer, perform: { _ in
                                    DispatchQueue.global(qos: .background).async {
                                        if let sizeCode = try? call("stat -f %z ~/.patched-sur/big-sur-micropatcher.zip") {
                                            currentSize = Int(Float(sizeCode) ?? 10000)
                                            downloadProgress = CGFloat(Float(sizeCode) ?? 10000) / CGFloat(downloadSize)
                                        }
                                    }
                                })
                        }
                        Text(kextDownloaded ? "Downloaded Kexts" : "Downloading Kexts...")
                            .foregroundColor(.white)
                            .lineLimit(4)
                            .onAppear {
                                DispatchQueue.global(qos: .background).async {
                                    if !AppInfo.usePredownloaded {
                                        do {
                                            print("Cleaning up before download...")
                                            _ = try Folder.home.createSubfolderIfNeeded(at: ".patched-sur")
                                            _ = try? Folder(path: "~/.patched-sur/big-sur-micropatcher").delete()
                                            _ = try? call("rm -rf ~/.patched-sur/big-sur-micropatcher*")
                                            _ = try? File(path: "~/.patched-sur/big-sur-micropatcher.zip").delete()
                                            _ = try? File(path: "~/.patched-sur/Helper.app.zip").delete()
                                            _ = try? call("rm -rf ~/.patched-sur/Helper.app")
                                            _ = try? call("rm -rf ~/.patched-sur/__MACOSX")
                                            print("Starting download of micropatcher...")
                                            if let sizeString = try? call("curl -sI https://www.dropbox.com/s/wb55vorpsid82mh/big-sur-micropatcher.zip?dl=1 | grep -i Content-Length | awk '{print $2}'"), let sizeInt = Int(sizeString) {
                                                downloadSize = sizeInt
                                            }
                                            try call("curl -Lo ~/.patched-sur/big-sur-micropatcher.zip https://www.dropbox.com/s/wb55vorpsid82mh/big-sur-micropatcher.zip?dl=1")
                                            print("Unzipping kexts...")
                                            try call("unzip ~/.patched-sur/big-sur-micropatcher.zip -d ~/.patched-sur")
                                            print("Downloading Helper...")
                                            try call("curl -Lo ~/.patched-sur/Helper.app.zip https://github.com/patched-sur/patched-sur.github.io/raw/main/Helper.app.zip")
                                            print("Unzipping Helper...")
                                            try call("unzip ~/.patched-sur/Helper.app.zip -d ~/.patched-sur")
                                            print("Post-download clean up...")
                                            _ = try? File(path: "~/.patched-sur/big-sur-micropatcher.zip").delete()
                                            _ = try? File(path: "~/.patched-sur/Helper.app.zip").delete()
                                            _ = try? call("rm -rf ~/.patched-sur/__MACOSX")
                                            print("Finished downloading the micropatcher!")
                                            kextDownloaded = true
                                        } catch {
                                            downloadStatus = error.localizedDescription
                                        }
                                    } else {
                                        kextDownloaded = true
                                    }
                                }
                            }
                            .padding(6)
                            .padding(.horizontal, 4)
                    }
                }.fixedSize()
                ZStack {
                    ProgressBar(value: $installProgress, length: 230)
                        .onReceive(timer, perform: { _ in
                            DispatchQueue.global(qos: .background).async {
                                if let sizeCode = try? call("stat -f %z ~/.patched-sur/InstallAssistant.pkg") {
                                    currentSize = Int(Float(sizeCode) ?? 10000)
                                    installProgress = CGFloat(Float(sizeCode) ?? 10000) / CGFloat(installSize)
                                }
                            }
                        })
                    Text("Downloading macOS...")
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .onAppear {
                            DispatchQueue.global(qos: .background).async {
                                if !AppInfo.usePredownloaded {
                                    do {
                                        _ = try? call("sleep 3")
                                        _ = try? call("rm -rf ~/.patched-sur/InstallAssistant.pkg")
                                        if let sizeString = try? call("curl -sI \(installInfo!.url) | grep -i Content-Length | awk '{print $2}'"), let sizeInt = Int(sizeString) {
                                            installSize = sizeInt
                                        }
                                        try call("curl -Lo ~/.patched-sur/InstallAssistant.pkg \(installInfo!.url)")
                                        p = 4
                                    } catch {
                                        downloadStatus = error.localizedDescription
                                    }
                                } else {
                                    p = 4
                                }
                            }
                        }
                        .padding(6)
                        .padding(.horizontal, 4)
                }.fixedSize()
            } else {
                VStack {
                    Button {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(downloadStatus, forType: .string)
                    } label: {
                        ZStack {
                            buttonBG
                                .cornerRadius(10)
                                .frame(minWidth: 200, maxWidth: 450)
                                .onHover(perform: { hovering in
                                    buttonBG = hovering ? Color.red.opacity(0.7) : .red
                                })
                                .onAppear(perform: {
                                    if buttonBG != .red && buttonBG != Color.red.opacity(0.7) {
                                        buttonBG = .red
                                    }
                                })
                            Text(downloadStatus)
                                .foregroundColor(.white)
                                .lineLimit(4)
                                .padding(6)
                                .padding(.horizontal, 4)
                        }
                    }.buttonStyle(BorderlessButtonStyle())
                    Text("Click to Copy")
                        .font(.caption)
                }.fixedSize()
            }
        }
    }
}

struct ProgressBar: View {
    @Binding var value: CGFloat
    var length: CGFloat = 285
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().frame(minWidth: length)
                .opacity(0.3)
                .foregroundColor(.accentColor)
            
            Rectangle().frame(width: min(value*length, length))
                .foregroundColor(.accentColor)
                .animation(.linear)
        }.cornerRadius(10)
    }
}

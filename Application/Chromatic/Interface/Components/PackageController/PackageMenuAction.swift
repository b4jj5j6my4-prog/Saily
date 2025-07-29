//
//  PackageMenuAction.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/24.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import PathListTableViewController
import SafariServices
import SPIndicator
import UIKit

class PackageMenuAction {
    enum ActionDescriptor: String, CaseIterable {
        case directInstall
        case install
        case reinstall
        case downgrade
        case update
        case remove
        case cancelQueue
        case versionControl
        case blockUpdate
        case unblockUpdate
        case download
        case collectAndSave
        case collectAndOverwrite
        case removeCollect
        case copyMeta
        case revealFiles

        func describe() -> String {
            switch self {
            case .directInstall:
                NSLocalizedString("DIRECT_INSTALL", comment: "Direct Install")
            case .install:
                NSLocalizedString("INSTALL", comment: "Install")
            case .reinstall:
                NSLocalizedString("REINSTALL", comment: "Reinstall")
            case .downgrade:
                NSLocalizedString("DOWNGRADE", comment: "Downgrade")
            case .update:
                NSLocalizedString("UPDATE", comment: "Update")
            case .remove:
                NSLocalizedString("REMOVE", comment: "Remove")
            case .cancelQueue:
                NSLocalizedString("CANCEL_QUEUE", comment: "Cancel Queue")
            case .versionControl:
                NSLocalizedString("VERSION_CONTROL", comment: "Version Control")
            case .blockUpdate:
                NSLocalizedString("BLOCK_UPDATE", comment: "Block Update")
            case .unblockUpdate:
                NSLocalizedString("UNBLOCK_UPDATE", comment: "Unblock Update")
            case .download:
                NSLocalizedString("DOWNLOAD", comment: "Download")
            case .collectAndSave:
                NSLocalizedString("COLLECT_AND_SAVE", comment: "Collect And Save")
            case .collectAndOverwrite:
                NSLocalizedString("COLLECT_AND_OVERWRITE", comment: "Collect And Overwrite")
            case .removeCollect:
                NSLocalizedString("REMOVE_COLLECT", comment: "Remove Collect")
            case .copyMeta:
                NSLocalizedString("COPY_META", comment: "Copy Meta")
            case .revealFiles:
                NSLocalizedString("REVEAL_FILES", comment: "Reveal Files")
            }
        }

        func icon() -> UIImage? {
            switch self {
            case .directInstall:
                UIImage(systemName: "paperplane")
            case .install:
                UIImage(systemName: "arrow.down.square")
            case .reinstall:
                UIImage(systemName: "arrow.clockwise.circle")
            case .downgrade:
                UIImage(systemName: "arrow.down.circle")
            case .update:
                UIImage(systemName: "arrow.up.circle")
            case .remove:
                UIImage(systemName: "xmark.circle")
            case .cancelQueue:
                UIImage(systemName: "circle.dashed")
            case .versionControl:
                UIImage(systemName: "list.triangle")
            case .blockUpdate:
                UIImage(systemName: "hand.raised")
            case .unblockUpdate:
                UIImage(systemName: "face.dashed")
            case .download:
                UIImage(systemName: "icloud.and.arrow.down")
            case .collectAndSave:
                UIImage(systemName: "rosette")
            case .collectAndOverwrite:
                UIImage(systemName: "rosette")
            case .removeCollect:
                UIImage(systemName: "circle.dashed")
            case .copyMeta:
                UIImage(systemName: "circle.dashed")
            case .revealFiles:
                UIImage(systemName: "doc.text.magnifyingglass")
            }
        }
    }

    struct MenuAction {
        let descriptor: ActionDescriptor
        let block: (Package, UIView) -> Void
        let eligibleForPerform: (Package) -> (Bool)
    }

    // MARK: - ACTIONS

    // MARK: - INSTALL KIND

    static let resolveInstallRequest = { (package: Package, view: UIView) in
        if let version = package.latestVersion,
           let trimmedPackage = PackageCenter
           .default
           .trim(package: package, toVersion: version),
           let action = TaskManager.PackageAction(action: .install,
                                                  represent: trimmedPackage,
                                                  isUserRequired: true)
        {
            let architecture = trimmedPackage.latestMetadata?["architecture"] as? String ?? ""
            if !architecture.contains("iphoneos-arm64e") {
                let packageId = trimmedPackage.identity
                let version = trimmedPackage.latestVersion ?? "unknown"
                let repoHost = trimmedPackage.repoRef?.host

                let title = NSLocalizedString("PACKAGE_NOT_UPDATED", comment: "Not Updated")

                let isSpecialRepo = ["apt.procurs.us", "ellekit.space"].contains(repoHost)
                let msg = isSpecialRepo ?
                    NSLocalizedString("CONTACT_ROOTHIDE_DEV", comment: "Please contact @roothideDev to update it") :
                    String(format: NSLocalizedString("PACKAGE_UPDATE_REQUIRED_FORMAT", comment: "%@(%@)\n\nYou can contact the developer of this package to update it for roothide, or you can try to convert it via roothide Patcher."), packageId, version)

                let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)

                let isPatcherInstalled = PackageCenter.default.obtainPackageInstallationInfo(with: "com.roothide.patcher") != nil

                if !isSpecialRepo {
                    let patchActionTitle = isPatcherInstalled ?
                        NSLocalizedString("CONVERT_BUTTON", comment: "Convert") :
                        NSLocalizedString("GET_PATCHER", comment: "Get Patcher")

                    let patchAction = UIAlertAction(title: patchActionTitle, style: .destructive) { _ in
                        if isPatcherInstalled {
                            alert.dismiss(animated: true) {
                                let isLocalPackage = trimmedPackage.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil

                                if isLocalPackage {
                                    if let localPath = trimmedPackage.latestMetadata?[DirectInstallInjectedPackageLocationKey] as? String {
                                        if IsAppAvailable("com.roothide.patcher") {
                                            let result = ShareFileToApp("com.roothide.patcher", localPath)

                                            if !result {
                                                SPIndicator.present(
                                                    title: NSLocalizedString("SHARE_FAILED", comment: "Share Failed"),
                                                    message: NSLocalizedString("FAILED_TO_OPEN_PATCHER", comment: "Failed to open Patcher"),
                                                    preset: .error
                                                )
                                            }
                                        } else {
                                            SPIndicator.present(
                                                title: NSLocalizedString("ERROR", comment: "Error"),
                                                message: NSLocalizedString("PATCHER_NOT_INSTALLED", comment: "Patcher not installed"),
                                                preset: .error
                                            )
                                        }
                                    } else {
                                        SPIndicator.present(
                                            title: NSLocalizedString("ERROR", comment: "Error"),
                                            message: NSLocalizedString("INVALID_PACKAGE_PATH", comment: "Invalid package path"),
                                            preset: .error
                                        )
                                    }
                                } else {
                                    let progressAlert = UIAlertController(
                                        title: NSLocalizedString("DOWNLOADING", comment: "Downloading..."),
                                        message: NSLocalizedString("REDIRECTING", comment: "Redirecting..."),
                                        preferredStyle: .alert
                                    )

                                    let progressView = UIProgressView(progressViewStyle: .default)
                                    progressView.progress = 0
                                    progressView.translatesAutoresizingMaskIntoConstraints = false

                                    progressAlert.view.addSubview(progressView)
                                    NSLayoutConstraint.activate([
                                        progressView.leadingAnchor.constraint(equalTo: progressAlert.view.leadingAnchor, constant: 20),
                                        progressView.trailingAnchor.constraint(equalTo: progressAlert.view.trailingAnchor, constant: -20),
                                        progressView.bottomAnchor.constraint(equalTo: progressAlert.view.bottomAnchor, constant: -60),
                                        progressView.heightAnchor.constraint(equalToConstant: 2),
                                    ])

                                    let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel) { _ in
                                        NotificationCenter.default.removeObserver(PackageMenuAction.self, name: .DownloadProgress, object: nil)
                                    }
                                    progressAlert.addAction(cancelAction)

                                    view.parentViewController?.present(progressAlert, animated: true)

                                    NotificationCenter.default.addObserver(
                                        forName: .DownloadProgress,
                                        object: nil,
                                        queue: .main
                                    ) { notification in
                                        guard let info = notification.object as? CariolNetwork.DownloadNotification,
                                              info.representUrl == trimmedPackage.obtainDownloadLink()
                                        else {
                                            return
                                        }

                                        if !info.completed {
                                            let progress = info.progress.fractionCompleted

                                            let currentBytes = info.progress.completedUnitCount
                                            let totalBytes = info.progress.totalUnitCount

                                            let currentMB = currentBytes > 0 ? CariolNetwork.shared.byteFormat(bytes: Int(currentBytes)) : "0KB"
                                            let totalMB = totalBytes > 0 ? CariolNetwork.shared.byteFormat(bytes: Int(totalBytes)) : NSLocalizedString("UNKNOWN_SIZE", comment: "Unknown size")

                                            progressView.progress = Float(progress)
                                            progressAlert.message = "\(currentMB)/\(totalMB)"
                                            return
                                        }

                                        guard info.completed, let fileURL = info.targetLocation, info.error == nil else {
                                            progressAlert.dismiss(animated: true)
                                            if let error = info.error {
                                                SPIndicator.present(
                                                    title: NSLocalizedString("DOWNLOAD_FAILED", comment: "Download Failed"),
                                                    message: error.localizedDescription,
                                                    preset: .error
                                                )
                                            }
                                            NotificationCenter.default.removeObserver(PackageMenuAction.self, name: .DownloadProgress, object: nil)
                                            return
                                        }

                                        NotificationCenter.default.removeObserver(PackageMenuAction.self, name: .DownloadProgress, object: nil)

                                        progressAlert.dismiss(animated: true) {
                                            if let correctFileURL = CariolNetwork.shared.obtainDownloadedFile(for: trimmedPackage) {
                                                if IsAppAvailable("com.roothide.patcher") {
                                                    let result = ShareFileToApp("com.roothide.patcher", correctFileURL.path)

                                                    if !result {
                                                        SPIndicator.present(
                                                            title: NSLocalizedString("SHARE_FAILED", comment: "Share Failed"),
                                                            message: NSLocalizedString("FAILED_TO_OPEN_PATCHER", comment: "Failed to open Patcher"),
                                                            preset: .error
                                                        )
                                                    }
                                                } else {
                                                    SPIndicator.present(
                                                        title: NSLocalizedString("ERROR", comment: "Error"),
                                                        message: NSLocalizedString("PATCHER_NOT_INSTALLED", comment: "Patcher not installed"),
                                                        preset: .error
                                                    )
                                                }
                                            } else {
                                                SPIndicator.present(
                                                    title: NSLocalizedString("ERROR", comment: "Error"),
                                                    message: NSLocalizedString("FAILED_TO_GET_FILE", comment: "Failed to get file"),
                                                    preset: .error
                                                )
                                            }
                                        }
                                    }

                                    CariolNetwork.shared.syncDownloadRequest(packageList: [trimmedPackage])
                                }
                            }
                        } else {
                            alert.dismiss(animated: true) {
                                if let url = URL(string: "sileo://package/com.roothide.patcher") {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }
                        }
                    }
                    alert.addAction(patchAction)
                }

                let okTitle = isSpecialRepo ?
                    NSLocalizedString("OK", comment: "OK") :
                    NSLocalizedString("CANCEL", comment: "Cancel")

                let okAction = UIAlertAction(title: okTitle, style: .cancel) { _ in
                    alert.dismiss(animated: true, completion: nil)
                }
                alert.addAction(okAction)

                view.parentViewController?.present(alert, animated: true, completion: nil)
                return
            }

            // MARK: - DIRECT INSTALL

            if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                let result = TaskManager
                    .shared
                    .startPackageResolution(action: action)
                resolveAction(result: result, view: view)
                return
            }

            // MARK: - PAID

            if let tag = package.latestMetadata?["tag"],
               tag.contains("cydia::commercial")
            {
                // MARK: - GET ACCOUNT

                if !DeviceInfo.current.useRealDeviceInfo {
                    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                                  message: NSLocalizedString("CANNOT_SIGNIN_PAYMENT_WITHOUT_REAL_DEVICE_ID", comment: "Cannot sign in without using real device identities, check your settings."),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                                  style: .default,
                                                  handler: nil))
                    view.parentViewController?.present(alert, animated: true, completion: nil)
                    return
                }

                guard let repoUrl = package.repoRef,
                      let repo = RepositoryCenter.default.obtainImmutableRepository(withUrl: repoUrl)
                else {
                    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                                  message: NSLocalizedString("BROKEN_RESOURCE", comment: "Broken Resource"),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                                  style: .default,
                                                  handler: nil))
                    view.parentViewController?.present(alert, animated: true, completion: nil)
                    return
                }
                guard let signin = PaymentManager.shared.obtainStoredTokenInfomation(for: repo) else {
                    PaymentManager.shared.startUserAuthenticate(window: view.window ?? UIWindow(),
                                                                controller: view.parentViewController,
                                                                repoUrl: repoUrl) {}
                    return
                }
                let alert = UIAlertController(title: "⏳",
                                              message: NSLocalizedString("COMMUNICATING_WITH_VENDER",
                                                                         comment: "Communicating with vender"),
                                              preferredStyle: .alert)
                view.parentViewController?.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    alert.dismiss(animated: true, completion: nil)
                }

                // MARK: - GET PACKAGE INFO

                DispatchQueue.global().async {
                    PaymentManager.shared.obtainPackageInfo(for: repoUrl, withPackageIdentity: package.identity) { info in
                        DispatchQueue.main.async {
                            guard let info else { return }
                            debugPrint(info)
                            if info.purchased == true {
                                // MARK: - OK FOR DOWNLOAD

                                DispatchQueue.global().async {
                                    let readDownload = PaymentManager
                                        .shared
                                        .queryDownloadLinkAndWait(withPackage: package)
                                    DispatchQueue.main.async {
                                        alert.dismiss(animated: true, completion: nil)
                                        guard let download = readDownload,
                                              let version = trimmedPackage.latestVersion,
                                              var meta = trimmedPackage.latestMetadata
                                        else {
                                            return
                                        }
                                        meta["filename"] = download.absoluteString
                                        let virtualPackage = Package(identity: trimmedPackage.identity,
                                                                     payload: [version: meta],
                                                                     repoRef: repoUrl)
                                        guard let newAction = TaskManager.PackageAction(action: .install,
                                                                                        represent: virtualPackage,
                                                                                        isUserRequired: true)
                                        else {
                                            return
                                        }

                                        let result = TaskManager
                                            .shared
                                            .startPackageResolution(action: newAction)
                                        resolveAction(result: result, view: view)
                                    }
                                }
                            } else if info.available ?? false {
                                // MARK: - NEED BUY

                                let window = view.window ?? UIWindow()
                                alert.dismiss(animated: true, completion: nil)
                                DispatchQueue.global().async {
                                    _ = PaymentManager
                                        .shared
                                        .initPurchaseAndWait(for: repoUrl,
                                                             withPackageIdentity: package.identity,
                                                             window: window)
                                }
                            } else {
                                // MARK: - NOT AVAILABLE

                                alert.dismiss(animated: true) {
                                    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                                                  message: NSLocalizedString("VERNDER_PACKAGE_NOT_AVAILABLE", comment: "Package not available, contact vender for support"),
                                                                  preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                                                  style: .default,
                                                                  handler: nil))
                                    view.parentViewController?.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
                return
            }

            // MARK: - DO

            let result = TaskManager
                .shared
                .startPackageResolution(action: action)
            resolveAction(result: result, view: view)
        }
    }

    static let allMenuActions: [MenuAction] = [
        // MARK: - DIRECT INSTALL

        .init(descriptor: .directInstall,
              block: resolveInstallRequest,
              eligibleForPerform: { package in
                  if TaskManager
                      .shared
                      .isQueueContains(package: package.identity)
                  {
                      return false
                  }
                  return package
                      .latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil
              }),

        // MARK: - INSTALL

        .init(descriptor: .install,
              block: resolveInstallRequest,
              eligibleForPerform: { package in
                  if TaskManager
                      .shared
                      .isQueueContains(package: package.identity)
                  {
                      return false
                  }
                  if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                      return false
                  }
                  if package.obtainDownloadLink() == PackageBadUrl {
                      return false
                  }
                  return PackageCenter
                      .default
                      .obtainPackageInstallationInfo(with: package.identity)
                      == nil
              }),

        // MARK: - UPDATE

        .init(descriptor: .update,
              block: resolveInstallRequest,
              eligibleForPerform: { package in
                  if TaskManager.shared.isQueueContains(package: package.identity) { return false }
                  if package.obtainDownloadLink() == PackageBadUrl {
                      return false
                  }
                  if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                      return false
                  }
                  if let info = PackageCenter
                      .default
                      .obtainPackageInstallationInfo(with: package.identity),
                      PackageCenter
                      .default
                      .obtainUpdateForPackage(with: package.identity,
                                              version: info.version)
                      .count > 0
                  {
                      if let info = PackageCenter
                          .default
                          .obtainPackageInstallationInfo(with: package.identity),
                          let current = package.latestVersion
                      {
                          if Package.compareVersion(current, b: info.version)
                              == .aIsSmallerThenB
                          {
                              return false
                          }
                      }
                      return true
                  }
                  return false
              }),

        // MARK: - REINSTALL

        .init(descriptor: .reinstall,
              block: resolveInstallRequest,
              eligibleForPerform: { package in
                  if package.obtainDownloadLink() == PackageBadUrl {
                      return false
                  }
                  if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                      return false
                  }
                  if TaskManager.shared.isQueueContains(package: package.identity) { return false }
                  let info = PackageCenter
                      .default
                      .obtainPackageInstallationInfo(with: package.identity)
                  return info?.version == package.latestVersion && info?.version != nil
              }),

        // MARK: - DOWNGRADE

        .init(descriptor: .downgrade,
              block: resolveInstallRequest,
              eligibleForPerform: { package in
                  if TaskManager.shared.isQueueContains(package: package.identity) { return false }
                  if package.obtainDownloadLink() == PackageBadUrl {
                      return false
                  }
                  if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                      return false
                  }
                  let _info = PackageCenter
                      .default
                      .obtainPackageInstallationInfo(with: package.identity)
                  guard let info = _info, let current = package.latestVersion else { return false }
                  return Package.compareVersion(current, b: info.version) == .aIsSmallerThenB
              }),

        // MARK: - REMOVE

        .init(descriptor: .remove,
              block: { package, view in
                  if let action = TaskManager.PackageAction(action: .remove,
                                                            represent: package,
                                                            isUserRequired: true)
                  {
                      let result = TaskManager
                          .shared
                          .startPackageResolution(action: action)
                      resolveAction(result: result, view: view)
                  }
              },
              eligibleForPerform: { package in
                  if TaskManager.shared.isQueueContains(package: package.identity) { return false }
                  return PackageCenter
                      .default
                      .obtainPackageInstallationInfo(with: package.identity)
                      != nil
              }),

        // MARK: - CANCEL QUEUE

        .init(descriptor: .cancelQueue,
              block: { package, view in
                  let result = TaskManager
                      .shared
                      .cancelActionWithPackage(identity: package.identity)
                  resolveAction(result: result, view: view)
              },
              eligibleForPerform: {
                  TaskManager.shared.isQueueContainsUserRequest(package: $0.identity)
              }),

        // MARK: - VERSION CONTROL

        .init(descriptor: .versionControl,
              block: { package, view in
                  let target = PackageVersionControlController()
                  target.currentPackage = package
                  view.parentViewController?.present(next: target)
              },
              eligibleForPerform: { _ in true }),

        // MARK: - UPDATE CONTROL

        .init(descriptor: .blockUpdate, block: { package, _ in
            PackageCenter.default.blockedUpdateTable.append(package.identity)
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }, eligibleForPerform: { package in
            !PackageCenter.default.blockedUpdateTable.contains(package.identity)
        }),

        .init(descriptor: .unblockUpdate, block: { package, _ in
            PackageCenter.default.blockedUpdateTable.removeAll(package.identity)
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }, eligibleForPerform: { package in
            PackageCenter.default.blockedUpdateTable.contains(package.identity)
        }),

        // MARK: - DOWNLOAD

        .init(descriptor: .download, block: { package, sender in
            let target = SFSafariViewController(url: package.obtainDownloadLink())
            target.modalTransitionStyle = .coverVertical
            target.modalPresentationStyle = .formSheet
            sender
                .window?
                .topMostViewController?
                .present(target, animated: true, completion: nil)
        }, eligibleForPerform: { package in
            if let tag = package.latestMetadata?["tag"],
               tag.contains("cydia::commercial")
            {
                return false
            }
            if package.obtainDownloadLink() == PackageBadUrl {
                return false
            }
            if package.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                return false
            }
            return UIApplication.shared.canOpenURL(package.obtainDownloadLink())
        }),

        // MARK: - COLLECT AND SAVE

        .init(descriptor: .collectAndSave, block: { package, _ in
            var fetch = InterfaceBridge
                .collectedPackages
                .filter { $0.identity != package.identity }
            guard package.repoRef != nil else {
                SPIndicator.present(title: NSLocalizedString("TIPS1", comment: "Please search - long press [package list] - overwrite collection"),
                                    preset: .error,
                                    from: .center)
                return
            }
            fetch.append(package)
            InterfaceBridge.collectedPackages = fetch
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }, eligibleForPerform: { package in
            !InterfaceBridge
                .collectedPackages
                .map(\.identity)
                .contains(package.identity)
        }),
        .init(descriptor: .collectAndOverwrite, block: { package, _ in
            var fetch = InterfaceBridge
                .collectedPackages
                .filter { $0.identity != package.identity }
            guard package.repoRef != nil else {
                SPIndicator.present(title: NSLocalizedString("TIPS1", comment: "Please search - long press [package list] - overwrite collection"),
                                    preset: .error,
                                    from: .center)
                return
            }
            fetch.append(package)
            InterfaceBridge.collectedPackages = fetch
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }, eligibleForPerform: { package in
            InterfaceBridge
                .collectedPackages
                .map(\.identity)
                .contains(package.identity)
        }),
        .init(descriptor: .removeCollect, block: { package, _ in
            var fetch = InterfaceBridge
                .collectedPackages
                .filter { $0.identity != package.identity }
            InterfaceBridge.collectedPackages = fetch
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }, eligibleForPerform: { package in
            InterfaceBridge
                .collectedPackages
                .map(\.identity)
                .contains(package.identity)
        }),

        // MARK: - COPY META

        .init(descriptor: .copyMeta, block: { package, view in
            let text = (package.latestMetadata ?? [:])
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
            if InterfaceBridge.enableShareSheet {
                let activityViewController = UIActivityViewController(activityItems: [text],
                                                                      applicationActivities: nil)
                activityViewController
                    .popoverPresentationController?
                    .sourceView = view
                view
                    .parentViewController?
                    .present(activityViewController, animated: true, completion: nil)
            } else {
                UIPasteboard.general.string = text
                SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                    message: nil,
                                    preset: .done,
                                    haptic: .success,
                                    from: .top,
                                    completion: nil)
            }
        }, eligibleForPerform: { _ in true }),

        // MARK: - REVEAL FILES

        .init(descriptor: .revealFiles, block: { package, view in
            var path: String?
            if FileManager
                .default
                .fileExists(atPath: "/Library/dpkg/info/\(package.identity).list")
            {
                path = "/Library/dpkg/info/\(package.identity).list"
            }
            if FileManager
                .default
                .fileExists(atPath: "/var/jb/Library/dpkg/info/\(package.identity).list")
            {
                path = "/var/jb/Library/dpkg/info/\(package.identity).list"
            }
            guard let path else { return }
            let controller = PathListTableViewController(path: path)
            controller.pressToCopy = true
            controller.showFullPath = true
            controller.allowSearch = true
            view
                .window?
                .topMostViewController?
                .present(next: controller)
        },
        eligibleForPerform: { package in
            FileManager
                .default
                .fileExists(atPath: "/Library/dpkg/info/\(package.identity).list")
                ||
                FileManager
                .default
                .fileExists(atPath: "/var/jb/Library/dpkg/info/\(package.identity).list")
        }),
    ]

    // MARK: ACTIONS -

    static func presentPackageActionError(view: UIView) {
        let target = PackageDiagnosticController()
        view.parentViewController?.present(next: target)
    }

    static func resolveAction(result: TaskManager.PackageResolutionResult, view: UIView) {
        switch result {
        case .success:
            let text = NSLocalizedString("SUCCESSFULLY_QUEUED", comment: "Successfully Queued")
            SPIndicator.present(title: text,
                                preset: .done)
        case .breaksOther, .missingRequired:
            presentPackageActionError(view: view)
        case .brokenResource, .removeErrorTooManyDependency, .unknownError:
            SPIndicator.present(title: NSLocalizedString("UNKNOWN_ERROR_OCCURRED", comment: "Unknown Error Occurred"),
                                preset: .error)
        }
    }
}

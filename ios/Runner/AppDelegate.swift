import Flutter
import UIKit
import PushKit
import CallKit
import AVFAudio
import WebRTC
import Security
import flutter_callkit_incoming
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  lazy var callsEngine = FlutterEngine(name: "01support", project: nil, allowHeadlessExecution: true)
  private var supportAcceptedIds = Set<String>()
  private var supportTerminalIds = Set(UserDefaults.standard.stringArray(forKey:"01support.terminal_ids") ?? [])
  private var supportAlertToken: String?
  private var supportRegistry: PKPushRegistry?
  private var supportChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    callsEngine.run()
    GeneratedPluginRegistrant.register(with: callsEngine)
    configureSupportCalls(callsEngine.binaryMessenger)
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }


  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
    supportAlertToken = deviceToken.map { String(format: "%02x", $0) }.joined()
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    supportChannel?.invokeMethod("alertTokenChanged", arguments: nil)
  }
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if userInfo["type"] as? String == "support.call.cancelled", let id = userInfo["callId"] as? String,
       (userInfo["recipient"] as? String ?? userInfo["agentId"] as? String) == supportSession()?["identity"] {
      markSupportTerminal(id)
      let data = flutter_callkit_incoming.Data(id: id, nameCaller: "", handle: "", type: 0)
      SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data)
    }
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  private func configureSupportCalls(_ messenger: FlutterBinaryMessenger) {
    supportChannel = FlutterMethodChannel(name: "01calls/native", binaryMessenger: messenger)
    supportChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enableVoip": self?.enableSupportVoip(); result(nil)
      case "getAlertToken": result(self?.supportAlertToken)
      case "showSupportMissed":
        let count = (call.arguments as? [String:Any])?["count"] as? Int ?? 0
        self?.showSupportMissed(count)
        result(nil)
      case "enableAlerts": UIApplication.shared.registerForRemoteNotifications(); result(nil)
      case "disableVoip": self?.supportRegistry?.desiredPushTypes = []; result(nil)
      case "isSandbox":
        #if DEBUG
        result(true)
        #else
        result(false)
        #endif
      default: result(FlutterMethodNotImplemented)
      }
    }
    if supportSession() != nil { enableSupportVoip() }
  }
  private func showSupportMissed(_ count: Int) {
    let center = UNUserNotificationCenter.current()
    center.removeDeliveredNotifications(withIdentifiers: ["support-missed"])
    center.removePendingNotificationRequests(withIdentifiers: ["support-missed"])
    guard count > 0 else { return }
    let content = UNMutableNotificationContent()
    content.title = "Appels assistance"
    content.body = "\(count) appel\(count > 1 ? "s" : "") manqué\(count > 1 ? "s" : "")"
    content.threadIdentifier = "support-missed"
    content.userInfo = ["type":"support.call.missed"]
    center.add(UNNotificationRequest(identifier:"support-missed", content:content, trigger:nil))
  }
  private func enableSupportVoip() {
    #if !targetEnvironment(simulator)
    if supportRegistry == nil {
      supportRegistry = PKPushRegistry(queue: .main)
      supportRegistry?.delegate = self
    }
    supportRegistry?.desiredPushTypes = [.voIP]
    #endif
  }
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    guard type == .voIP else { return }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance.setDevicePushTokenVoIP(pushCredentials.token.map { String(format: "%02x", $0) }.joined())
    supportChannel?.invokeMethod("voipTokenChanged", arguments: nil)
  }
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance.setDevicePushTokenVoIP("")
  }
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    guard type == .voIP, let id = payload.dictionaryPayload["callId"] as? String, UUID(uuidString: id) != nil else { completion(); return }
    let values = payload.dictionaryPayload
    let data = flutter_callkit_incoming.Data(id: id, nameCaller: values["callerName"] as? String ?? "01 Supplies", handle: "Appel assistance", type: 0)
    data.appName = "01 Supplies"
    data.supportsVideo = false
    data.supportsHolding = false
    data.supportsGrouping = false
    data.supportsUngrouping = false
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let expiry = (values["expiresAt"] as? String).flatMap { formatter.date(from: $0) }
    let recipient = values["recipient"] as? String ?? values["agentId"] as? String
    let valid = (values["type"] as? String) == "support.call.invited" && recipient == supportSession()?["identity"] && (expiry?.timeIntervalSinceNow ?? 0) > 0 && !supportTerminalIds.contains(id)
    data.duration = max(1, min(45000, Int((expiry?.timeIntervalSinceNow ?? 0) * 1000)))
    // PushKit requires immediate reporting, including stale deliveries.
    SwiftFlutterCallkitIncomingPlugin.sharedInstance.showCallkitIncoming(data, fromPushKit: true) {
      completion()
      if !valid { if !self.supportAcceptedIds.contains(id) { SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data) } }
      else { self.validateSupportInvitation(id, data:data) }
    }
  }
  private func markSupportTerminal(_ id: String) {
    supportAcceptedIds.remove(id)
    supportTerminalIds.insert(id)
    // Keep tombstones across process death without retaining call content.
    if supportTerminalIds.count > 256 { supportTerminalIds = Set(supportTerminalIds.prefix(256)) }
    UserDefaults.standard.set(Array(supportTerminalIds),forKey:"01support.terminal_ids")
  }
  private func validateSupportInvitation(_ id: String, data: flutter_callkit_incoming.Data, mayRefresh: Bool = true) {
    guard !supportTerminalIds.contains(id), let identity = supportSession()?["identity"],
      let token = supportSession()?["token"], let base = supportValue("support_url"),
      let url = URL(string:base.trimmingCharacters(in:CharacterSet(charactersIn:"/")) + "/supportCalls/get") else {
      SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data); return
    }
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization")
    request.setValue("application/json",forHTTPHeaderField:"Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject:["callId":id])
    URLSession.shared.dataTask(with:request) { payload,response,_ in
      DispatchQueue.main.async {
        if (response as? HTTPURLResponse)?.statusCode == 401 && mayRefresh {
          self.refreshSupportSession { refreshed in
            if refreshed { self.validateSupportInvitation(id,data:data,mayRefresh:false) }
            else { SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data) }
          }
          return
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200, let payload = payload,
          let call = (try? JSONSerialization.jsonObject(with:payload)) as? [String:Any] else {
          SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data); return
        }
        if call["status"] as? String == "accepted", call["agentId"] as? String == identity, self.supportAcceptedIds.contains(id) { return }
        let offered = (call["offers"] as? [String] ?? []).contains(identity)
        let declined = (call["declinedBy"] as? [String] ?? []).contains(identity)
        let ringing = call["status"] as? String == "ringing"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let deadline = (call["expiresAt"] as? String).flatMap { formatter.date(from:$0) }
        let unexpired = (deadline?.timeIntervalSinceNow ?? 0) > 0
        let unclaimed = call["agentId"] as? String == nil
        let current = self.supportSession()?["identity"] == identity
        if !ringing || !offered || declined || !unexpired || !unclaimed || !current || self.supportTerminalIds.contains(id) {
          self.markSupportTerminal(id)
          SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(data)
        }
      }
    }.resume()
  }
  private func supportValue(_ account: String) -> String? {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "01supplies.chat.support", kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Foundation.Data else { return nil }
    return String(data: data, encoding: .utf8)
  }
  private func supportSession() -> [String: String]? {
    guard let value = supportValue("01supplies.chat.support_session"), let data = value.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String:String]
  }
  private func supportCommand(_ method: String, id: String, mayRefresh: Bool = true, completion: @escaping (Bool) -> Void) {
    guard let token = supportSession()?["token"], let base = supportValue("support_url"), let url = URL(string: base.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/supportCalls/" + method) else { completion(false); return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["callId":id])
    URLSession.shared.dataTask(with: request) { _, response, _ in
      let status = (response as? HTTPURLResponse)?.statusCode
      if status == 401 && mayRefresh {
        self.refreshSupportSession { refreshed in
          if refreshed { self.supportCommand(method, id:id, mayRefresh:false, completion:completion) }
          else { completion(false) }
        }
      } else { DispatchQueue.main.async { completion(status == 200) } }
    }.resume()
  }
  private func refreshSupportSession(_ completion: @escaping (Bool) -> Void) {
    guard let identity = supportSession()?["identity"],
      let upstream = UserDefaults.standard.string(forKey:"flutter.token"), !upstream.isEmpty,
      let device = supportValue("01supplies.chat.support_device"),
      let base = supportValue("support_url"),
      let url = URL(string:base.trimmingCharacters(in: CharacterSet(charactersIn:"/")) + "/auth/exchange") else { completion(false); return }
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("application/json", forHTTPHeaderField:"Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject:["accessToken":upstream,"host":"chat","deviceId":device])
    URLSession.shared.dataTask(with:request) { data,response,_ in
      DispatchQueue.main.async {
        guard (response as? HTTPURLResponse)?.statusCode == 200,
          let data = data, let value = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any],
          value["identity"] as? String == identity, self.supportSession()?["identity"] == identity,
          let token = value["token"] as? String,
          let stored = try? JSONSerialization.data(withJSONObject:["identity":identity,"token":token]) else { completion(false); return }
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"01supplies.chat.support",kSecAttrAccount as String:"01supplies.chat.support_session"]
        let result = SecItemUpdate(query as CFDictionary,[kSecValueData as String:stored] as CFDictionary)
        completion(result == errSecSuccess)
      }
    }.resume()
  }
  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    supportAcceptedIds.insert(call.uuid.uuidString.lowercased())
    supportCommand("accept", id: call.uuid.uuidString.lowercased()) { accepted in
      if accepted { action.fulfill() } else { self.markSupportTerminal(call.uuid.uuidString.lowercased()); action.fail(); SwiftFlutterCallkitIncomingPlugin.sharedInstance.endCall(call.data) }
    }
  }
  func onDecline(_ call: Call, _ action: CXEndCallAction) { markSupportTerminal(call.uuid.uuidString.lowercased()); supportCommand("reject", id: call.uuid.uuidString.lowercased()) { _ in }; action.fulfill() }
  func onEnd(_ call: Call, _ action: CXEndCallAction) { markSupportTerminal(call.uuid.uuidString.lowercased()); supportCommand("end", id: call.uuid.uuidString.lowercased()) { _ in }; action.fulfill() }
  func onTimeOut(_ call: Call) { markSupportTerminal(call.uuid.uuidString.lowercased()) }
  func providerDidReset() {
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    supportChannel?.invokeMethod("supportProviderReset", arguments:nil)
  }
  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }
  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
  }
}

class SupportSceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene, let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = FlutterViewController(engine: delegate.callsEngine, nibName: nil, bundle: nil)
    self.window = window
    window.makeKeyAndVisible()
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}

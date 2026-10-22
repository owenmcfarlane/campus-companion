import SwiftUI
import WebKit

struct PlannerWebView: UIViewRepresentable {
    @ObservedObject var model: PlannerModel
    func makeCoordinator() -> Coordinator { Coordinator(model) }
    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "campusCompanionWidget")
        let script = """
        (() => {
          if (location.origin !== 'https://planner.example.org') return;
          window.__stickyEpoch = -1;
          window.__stickyPaused = true;
          let busy = false, pending = false;
          async function sync() {
            if (window.__stickyPaused || document.visibilityState === 'hidden') return;
            if (busy) { pending = true; return; }
            busy = true;
            const epoch = window.__stickyEpoch;
            try {
              const r = await fetch('/api/widget-plan', {cache:'no-store',credentials:'same-origin'});
              if (r.status === 401) window.webkit.messageHandlers.campusCompanionWidget.postMessage({epoch, clear:true});
              if (r.ok) {
                const text = await r.text();
                if (text.length <= 131072) window.webkit.messageHandlers.campusCompanionWidget.postMessage({epoch, data:text});
              }
            } catch (_) {} finally { busy = false; if (pending) { pending = false; void sync(); } }
          }
          window.addEventListener('campus-companion-plan-changed', sync);
          window.addEventListener('campus-companion-sync', sync);
          document.addEventListener('visibilitychange', () => { if(document.visibilityState==='visible') sync(); });
          window.addEventListener('online', sync);
          sync();
          setInterval(sync, 60000);
        })();
        """
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let configuration = WKWebViewConfiguration(); configuration.userContentController = controller
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator; view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.isInspectable = false
        view.load(URLRequest(url: model.destination))
        context.coordinator.lastDestination = model.destination
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        if context.coordinator.lastDestination != model.destination {
            context.coordinator.lastDestination = model.destination
            view.load(URLRequest(url: model.destination))
        }
        if context.coordinator.bridgeEpoch != model.bridgeEpoch {
            context.coordinator.bridgeEpoch = model.bridgeEpoch
            view.evaluateJavaScript("window.__stickyEpoch = \(model.bridgeEpoch); window.__stickyPaused = \(model.bridgePaused ? "true" : "false");", completionHandler: nil)
        }
        if context.coordinator.refresh != model.refreshToken {
            context.coordinator.refresh = model.refreshToken
            view.evaluateJavaScript("window.dispatchEvent(new Event('campus-companion-sync'))", completionHandler: nil)
        }
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let model: PlannerModel
        var lastDestination: URL?
        var refresh = 0
        var bridgeEpoch = 0
        init(_ model: PlannerModel) { self.model = model }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame,
                  message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == CampusCompanionWidgetConfiguration.siteHost,
                  [0,443].contains(message.frameInfo.securityOrigin.port),
                  let body = message.body as? [String: Any], let epoch = body["epoch"] as? Int,
                  !model.bridgePaused, epoch == model.bridgeEpoch else { return }
            if body["clear"] as? Bool == true { model.clear(); return }
            guard let raw = body["data"] as? String, let data = raw.data(using: .utf8), data.count <= 131072,
                  !model.bridgePaused, epoch == model.bridgeEpoch else { return }
            model.receive(data)
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if url.host == CampusCompanionWidgetConfiguration.siteHost && url.path == "/api/logout" { model.clear() }
            if navigationAction.targetFrame == nil {
                UIApplication.shared.open(url); decisionHandler(.cancel); return
            }
            guard ["https", "http", "about"].contains(url.scheme ?? "") else {
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard webView.url?.host == CampusCompanionWidgetConfiguration.siteHost else { return }
            webView.evaluateJavaScript("window.__stickyEpoch = \(model.bridgeEpoch); window.__stickyPaused = \(model.bridgePaused ? "true" : "false"); window.dispatchEvent(new Event('campus-companion-sync'));", completionHandler: nil)
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            model.message = "Couldn’t connect. Your saved widget remains available."
        }
    }
}

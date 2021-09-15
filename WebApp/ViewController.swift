//  ViewController.swift
//  Hybrid WebApp
//
//  Created by Igor Maximo on 14/05/19.
//  Copyright © 2019 Igor Maximo. All rights reserved.

import UIKit
import WebKit
import SafariServices
import CoreData
import UserNotifications
//import FirebaseInstanceID
import FirebaseMessaging

class ViewController: UIViewController, WKNavigationDelegate {
    
    private var webView = WKWebView() // Componente principal, tela.
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    var speedTestCompletionHandler: ((_ megabytesPerSecond: Double?, _ error: NSError?) -> ())!
    
    public var firebaseToken = "" // Para pegar o firebase Token
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Instancia o firebase no projeto
        /*           InstanceID.instanceID().instanceID { (result, error) in
         if let error = error {
         print("Error fetching remote instange ID: \(error)")
         } else if let result = result {
         print("Remote instance ID token: \(result.token)")
         self.firebaseToken = result.token
         }
         }
         */
        
        
        
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.firebaseToken = token
                //   self.fcmRegTokenMessage.text  = "Remote FCM registration token: \(token)"
            }
        }
        //            if UIDevice.current.model.hasPrefix("iPad") {
        //                print("iPad")
        //                UIDevice.current.userInterfaceIdiom == .phone
        //            } else {
        //                print("iPhone or iPod Touch")
        //            }
        let config = WKWebViewConfiguration()
        config.add(script: .getUrlAtDocumentStartScript, scriptMessageHandler: self)
        config.add(script: .getUrlAtDocumentEndScript, scriptMessageHandler: self)
        
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame:  UIScreen.main.bounds, configuration: config)
        webView.navigationDelegate = self
        view.addSubview(webView)
        // Desabilita efeito visual de rolagem nativo do iOS
        webView.scrollView.bounces = false
        
        // Para funcionar a href tel: ao clicar
        webView.configuration.dataDetectorTypes = [.phoneNumber]
        
        // Para funcionar landscape quando for necessario
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        
        // Cadastro de funcoes JS que WKWebView tem que ficar escutando o tempo todo
        webView.configuration.userContentController.add(self, name: "autenticacao") // Para salvar credenciais de usuario
        webView.configuration.userContentController.add(self, name: "setAutenticacaoCampos") // Para setar valores nos campos
        webView.configuration.userContentController.add(self, name: "swiftResetaCredenciais") // Para resetar as credenciais
        webView.configuration.userContentController.add(self, name: "downloadBoletoPDF") // Para realizar download de PDF
        webView.configuration.userContentController.add(self, name: "downloadNotaFiscalPDF") // Para realizar download de PDF
        ////////////////////////
        
        // Acesso a aplicacao enviando um POST
        let url = NSURL (string: "http://187.95.0.22/producao/central/indexIOSTempOldServer.php")
        // Envia informacoes via post para seguranca
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // POST values
        let post: String = "token=dSCFnNcJaAcORusC9eTZsuaNgGQcGDYjWapAnHJEHlTZXCbWhw"
        let postData: Data = post.data(using: String.Encoding.ascii, allowLossyConversion: true)!
        // Carrega a webview
        request.httpBody = postData
        webView.load(request as URLRequest)
        ////////////////////////
        self.view.addSubview(webView)                 // Add our webview to the view controller view so we can see it
    }
    
    // full screen enabled
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // Func que recebe um json array com as credenciais do usuario e grava no banco sqlite
    func gravaAutenticacaoSQLiteCoreData(stringJsonArray: String) {
        var cpfcnpj = ""
        var senha = ""
        var tipo = ""
        
        do {
            if let json = converteStringJsonArrayParaJSONArray(stringJson: stringJsonArray) as? [[String: String]] {
                for data in json {
                    //print(String(data["cpfcnpj"]!))
                    cpfcnpj = String(data["cpfcnpj"]!)
                    senha = String(data["senha"]!)
                    tipo = String(data["tipo"]!)
                }
            }
        }
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////// SQLITE - CORE DATA
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Gerenciamento", in: context)
        let newUser = NSManagedObject(entity: entity!, insertInto: context)
        
        newUser.setValue(cpfcnpj, forKey: "cpfcnpj")
        newUser.setValue(senha, forKey: "senha")
        newUser.setValue(tipo, forKey: "tipo")
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
        
        let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Gerenciamento")
        //request.predicate = NSPredicate(format: "age = %@", "12")
        request2.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request2)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "cpfcnpj") as! String)
                print(data.value(forKey: "senha") as! String)
                print(data.value(forKey: "tipo") as! String)
            }
        } catch {
            print("Failed")
        }
    }
    
    
    
    
    // Para gravar os tokens do firebase no banco de dados
    internal func atualizaTokenDBFirebase(cpfCnpj: String, token: String) {
        
        // print("==============================================> caiu " + cpfCnpj)
        // Acesso a aplicacao enviando um POST
        let url = NSURL (string: "http://187.95.0.22/producao/central/indexFirebaseOldServer.php")
        
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let post: String = "token=" + self.firebaseToken + "&user=" +  cpfCnpj + "&dispositivo=iPhone"
        let postData: Data = post.data(using: String.Encoding.ascii, allowLossyConversion: true)!
        
        request.httpBody = postData
        
        NSURLConnection(request: request as URLRequest, delegate: nil, startImmediately: true)
        
        
        //  let connection = NSURLConnection(request: request, delegate:nil, startImmediately: true)
    }
    
    // func que converte string de jsonarray para jsonarray de verdade
    private func converteStringJsonArrayParaJSONArray(stringJson: String) -> [Dictionary<String,Any>] {
        let data = stringJson.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>] {
                return jsonArray // use the json here
            } else {
                print("bad json")
            }
        } catch let error as NSError {
            print(error)
        }
        return [["ret":"null"]]
    }
    
    
    
    
    // Preenche campos com as credenciais salvas no SQLite CoreData
    func preencheCamposCredenciais() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Gerenciamento")
        request2.returnsObjectsAsFaults = false
        
        var jsonString = ""
        
        var cpfcnpj : String = ""
        var senha : String = ""
        var tipo : String = ""
        
        
        do {
            let result = try context.fetch(request2)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "cpfcnpj") as! String)
                print(data.value(forKey: "senha") as! String)
                print(data.value(forKey: "tipo") as! String)
                
                cpfcnpj = data.value(forKey: "cpfcnpj") as! String
                senha = data.value(forKey: "senha") as! String
                tipo = data.value(forKey: "tipo") as! String
                
                //json com credenciais
                jsonString = "{\"cpfcnpj\":\"\(data.value(forKey: "cpfcnpj") as! String)\",\"senha\":\"\(data.value(forKey: "senha") as! String)\", \"tipo\":\"\(data.value(forKey: "tipo") as! String)\"}"
            }
            
            // Grava token do firebase
            self.atualizaTokenDBFirebase(cpfCnpj: cpfcnpj, token: self.firebaseToken)
        } catch {
            print("Failed")
        }
        
        print(jsonString)
        // chamando function js
        let js = "swiftGetCredenciaisSalvasSQLite('{\"cpfcnpj\":\"\(cpfcnpj)\",\"senha\":\"\(senha)\", \"tipo\":\"\(tipo)\"}');"
        webView.evaluateJavaScript(js) { (result, error) in
            if error != nil {
                print(result)
            }
        }
        
        
    }
    
    // Realizar truncate da tabela gerenciamento
    func deleteAllData(entity: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
        
        /*
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
         let managedContext = appDelegate.persistentContainer.viewContext
         let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
         fetchRequest.returnsObjectsAsFaults = false
         
         do {
         let results = try managedContext.fetch(fetchRequest)
         for managedObject in results {
         let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
         managedContext.delete(managedObjectData)
         print("deletado")
         }
         } catch let error as NSError {
         print("Delete all data in \(entity) error : \(error) \(error.userInfo)")
         } */
    }
}


extension ViewController: WKScriptMessageHandler {
    // FUNC QUE FICA ESCUTANDO O JS EM TEMPO DE EXECUCAO
    func userContentController (_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Ponte JS (Bridge) - Para autenticar
        if message.name == "autenticacao" {
            gravaAutenticacaoSQLiteCoreData(stringJsonArray: (message.body as! String))
        }
        // Ponte JS (Bridge) - Para auto setar valores nos campos login/senha
        if message.name == "setAutenticacaoCampos" {
            preencheCamposCredenciais()
        }
        
        // Ponte JS (Bridge) - Para realizar download de faturas PDF
        if message.name == "downloadBoletoPDF" {
            if let instaurl = URL(string: message.body as! String), UIApplication.shared.canOpenURL(instaurl) {
                
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(instaurl)
                } else {
                    UIApplication.shared.openURL(instaurl)
                }
            }
        }
        
        // Ponte JS (Bridge) - Para realizar download de notas fiscais PDF
        if message.name == "downloadNotaFiscalPDF" {
            if let instaurl = URL(string: message.body as! String),
               UIApplication.shared.canOpenURL(instaurl) {
                
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(instaurl)
                } else {
                    UIApplication.shared.openURL(instaurl)
                }
            }
        }
        
        // Ponte JS (Bridge) - Para resetar as credenciais salvas no banco
        if message.name == "swiftResetaCredenciais" {
            print(message.body)
            deleteAllData(entity: "Gerenciamento")
        }
        
        
        if let script = WKUserScript.Defined(rawValue: message.name), let url = message.webView?.url {
            
            switch script {
            case .getUrlAtDocumentStartScript:
                return
            // print("start: \(url)")
            case .getUrlAtDocumentEndScript:
                if String("\(url)").contains("index") { // se link for o index ele chama a funcao
                    preencheCamposCredenciais()
                }
            }
        }
    }
}




extension WKWebView {
    func load(urlString: String) {
        if let url = URL(string: urlString) {
            load(URLRequest(url: url))
        }
    }
}

extension WKUserScript {
    enum Defined: String {
        case getUrlAtDocumentStartScript = "GetUrlAtDocumentStart"
        case getUrlAtDocumentEndScript = "GetUrlAtDocumentEnd"
        
        var name: String { return rawValue }
        
        private var injectionTime: WKUserScriptInjectionTime {
            switch self {
            case .getUrlAtDocumentStartScript: return .atDocumentStart
            case .getUrlAtDocumentEndScript: return .atDocumentEnd
            }
        }
        
        private var forMainFrameOnly: Bool {
            switch self {
            case .getUrlAtDocumentStartScript: return false
            case .getUrlAtDocumentEndScript: return false
            }
        }
        
        private var source: String {
            switch self {
            case .getUrlAtDocumentEndScript, .getUrlAtDocumentStartScript:
                return "webkit.messageHandlers.\(name).postMessage(document.URL)"
            }
        }
        
        fileprivate func create() -> WKUserScript {
            return WKUserScript(source: source,
                                injectionTime: injectionTime,
                                forMainFrameOnly: forMainFrameOnly)
        }
    }
}

extension WKWebViewConfiguration {
    func add(script: WKUserScript.Defined, scriptMessageHandler: WKScriptMessageHandler) {
        userContentController.addUserScript(script.create())
        userContentController.add(scriptMessageHandler, name: script.name)
    }
}

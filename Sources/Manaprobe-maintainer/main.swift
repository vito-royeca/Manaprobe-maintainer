import Foundation
import DotEnv

let pwd = ProcessInfo.processInfo.environment["PWD"]
let path = "\(pwd ?? "")/.env"
var env = try DotEnv.read(path: path)
env.load()

if let host = ProcessInfo.processInfo.environment["DATABASE_HOST"],
    let port = ProcessInfo.processInfo.environment["DATABASE_PORT"],
    let portInt = Int(port),
    let database = ProcessInfo.processInfo.environment["DATABASE_NAME"],
    let user = ProcessInfo.processInfo.environment["DATABASE_USER"],
    let password = ProcessInfo.processInfo.environment["DATABASE_PASSWORD"],
    let fullUpdate = ProcessInfo.processInfo.environment["FULL_UPDATE"],
    let fullUpdateBool = Bool(fullUpdate),
    let imagesPath = ProcessInfo.processInfo.environment["IMAGES_PATH"] {
    
    let maintainer = Maintainer(host: host,
                                port: portInt,
                                database: database,
                                user: user,
                                password: password,
                                isFullUpdate: fullUpdateBool,
                                imagesPath: imagesPath)
    try await maintainer.updateDatabase()

} else {
    print("Error in environment variables")
}








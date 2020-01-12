import Alamofire


/// Upload API base url
let uploadAPIBaseUrl: String = "https://upload.uploadcare.com"


public struct Uploadcare {
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String) {
		self.publicKey = publicKey
	}
	
	
	/// Method for integration testing
	public static func sayHi() {
		print("Uploadcare says Hi!")
	}
}

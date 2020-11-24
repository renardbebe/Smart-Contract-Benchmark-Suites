 

pragma solidity ^0.4.2;
contract Sign {

	address public AddAuthority;	
	mapping (uint32 => bytes32) Cert;	
	
	event EventNotarise (address indexed Signer, bytes Donnees_Signature, bytes Donnees_Reste);

	 
	
	function Sign() {AddAuthority = msg.sender;}

	function () {throw;}  
	
	function destroy() {if (msg.sender == AddAuthority) {selfdestruct(AddAuthority);}}
	
	function SetCert (uint32 _IndiceIndex, bytes32 _Cert) {
		Cert [_IndiceIndex] = _Cert;
	}				
	
	function GetCert (uint32 _IndiceIndex) returns (bytes32 _Valeur)  {
		_Valeur = Cert [_IndiceIndex];
	}		
	

 	 

	function VerifSignature (bytes _Signature, bytes _Reste) returns (bool) {
		 
		 
		 
		bytes32 r;
		bytes32 s;
		uint8 v;
		bytes32 hash;
		address Signer;
        assembly {
            r := mload(add(_Signature, 32))
            s := mload(add(_Signature, 64))
             
            v := and(mload(add(_Signature, 65)), 255)
            hash := mload(add(_Reste, 32))
            Signer := mload(add(_Reste, 52))
        }		
		return Signer == ecrecover(hash, v, r, s);
	}
	
	function VerifCert (uint32 _IndiceIndex, bool _log, bytes _Signature, bytes _Reste) returns (uint status) {					
		status = 0;
		 
		if (Cert [_IndiceIndex] != 0) {
			status = 1;
			 
			if (VerifSignature (_Signature, _Reste)) {
				 
				address Signer;
				assembly {Signer := mload(add(_Reste, 52))}		
			} else {
				 
				status = 2;							
			}		
			 
			if (_log) {
				EventNotarise (Signer, _Signature, _Reste);
				status = 3;							
			}
		}
		return (status);
	}
	
}
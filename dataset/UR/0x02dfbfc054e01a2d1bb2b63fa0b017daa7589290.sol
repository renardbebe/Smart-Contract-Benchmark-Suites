 

 

pragma solidity ^0.4.2;

contract DGK {
     
    address owner = msg.sender;
     
    string public institution;
     
	mapping (bytes32 => string) fingerprintSignatureMapping;

     
	event SignatureAdded(string digitalFingerprint, string signature, uint256 timestamp);
     
    modifier isOwner() { if (msg.sender != owner) throw; _; }

     
    function SignedDigitalAsset(string _institution) {
        institution = _institution;
    }
     
	function addSignature(string digitalFingerprint, string signature)
        isOwner {
         
        fingerprintSignatureMapping[sha3(digitalFingerprint)] = signature;
         
        SignatureAdded(digitalFingerprint, signature, now);
	}

     
	function removeSignature(string digitalFingerprint)
        isOwner {
         
		fingerprintSignatureMapping[sha3(digitalFingerprint)] = "";
	}

     
	function getSignature(string digitalFingerprint) constant returns(string){
		return fingerprintSignatureMapping[sha3(digitalFingerprint)];
	}

     
    function removeSdaContract()
        isOwner {
        selfdestruct(owner);
    }
}
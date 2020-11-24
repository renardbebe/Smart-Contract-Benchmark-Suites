 

pragma solidity ^0.4.11;
 
contract CertiMe {
     
    struct Certificate {
        string certHash;
        address issuer_addr;
        address recepient_addr;
        string version;
        string content;
    }

    uint numCerts;
    mapping (uint => Certificate) public certificates;
    mapping (string => Certificate) certHashKey;

    function newCertificate(address beneficiary, string certHash, string version, string content ) public returns (uint certID) {
        certID = ++numCerts;  
         
        certificates[certID] = Certificate(certHash,msg.sender,beneficiary, version,content);
        certHashKey[certHash]=certificates[certID];
    }
 
   
    function getMatchCountAddress(uint addr_type,address value) public constant returns (uint){
        uint counter = 0;
        for (uint i=1; i<numCerts+1; i++) {
              if((addr_type==0&&certificates[i].issuer_addr==value)||(addr_type==1&&certificates[i].recepient_addr==value)){
                counter++;
              }
        }        
        return counter;
    }
    function getCertsByIssuer(address value) public constant returns (uint[]) {
        uint256[] memory matches=new uint[](getMatchCountAddress(0,value));
        uint matchCount=0;
        for (uint i=1; i<numCerts+1; i++) {
              if(certificates[i].issuer_addr==value){
                matches[matchCount++]=i;
              }
        }
        
        return matches;
    }
    function getCertsByRecepient(address value) public constant returns (uint[]) {
        uint256[] memory matches=new uint[](getMatchCountAddress(1,value));
        uint matchCount=0;
        for (uint i=1; i<numCerts+1; i++) {
              if(certificates[i].recepient_addr==value){
                matches[matchCount++]=i;
              }
        }
        
        return matches;
    }   

    function getMatchCountString(uint string_type,string value) public constant returns (uint){
        uint counter = 0;
        for (uint i=1; i<numCerts+1; i++) {
              if(string_type==0){
                if(stringsEqual(certificates[i].certHash,value)){
                    counter++;
                }
              }
              if(string_type==1){
                if(stringsEqual(certificates[i].version,value)){
                    counter++;
                }
              }
              if(string_type==2){
                if(stringsEqual(certificates[i].content,value)){
                    counter++;
                }
              }
        }        
        return counter;
    }
    
    function getCertsByProof(string value) public constant returns (uint[]) {
        uint256[] memory matches=new uint[](getMatchCountString(0,value));
        uint matchCount=0;
        for (uint i=1; i<numCerts+1; i++) {
              if(stringsEqual(certificates[i].certHash,value)){
                matches[matchCount++]=i;
              }
        }
        
        return matches;
    }    
    function getCertsByVersion(string value) public constant returns (uint[]) {
        uint256[] memory matches=new uint[](getMatchCountString(1,value));
        uint matchCount=0;
        for (uint i=1; i<numCerts+1; i++) {
              if(stringsEqual(certificates[i].version,value)){
                matches[matchCount++]=i;
              }
        }
        
        return matches;
    }
    function getCertsByContent(string value) public constant returns (uint[]) {
        uint256[] memory matches=new uint[](getMatchCountString(2,value));
        uint matchCount=0;
        for (uint i=1; i<numCerts+1; i++) {
              if(stringsEqual(certificates[i].content,value)){
                matches[matchCount++]=i;
              }
        }
        
        return matches;
    }
    
 
    
	function stringsEqual(string storage _a, string memory _b) internal constant returns (bool) {
		bytes storage a = bytes(_a);
		bytes memory b = bytes(_b);
		if (a.length != b.length)
			return false;
		 
		for (uint i = 0; i < a.length; i ++)
			if (a[i] != b[i])
				return false;
		return true;
	}    
    
}
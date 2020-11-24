 

 
pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
pragma solidity ^0.4.18;



contract ARTIDDigitalSign is Ownable{
    
     
     
    mapping(bytes32 => Version[]) digitalCertificateArchive;
    
    
    struct Version {
        uint8 version;
        bytes32 sign;
        uint256 timestamp;
    }

    function Sign(string guid, string hash) public onlyWhitelisted {
        address _signer = msg.sender;
        string memory addressString = toString(_signer);
         
        string memory concatenatedData = strConcat(addressString,guid);
        bytes32 hashed = keccak256(concatenatedData);
        
        uint8 version = 1;
        Version[] memory versions = digitalCertificateArchive[hashed];
        uint length =  versions.length;
        for(uint8 i = 0; i < length; i++)
        {
            version = i+2;
        }

        bytes32 hashedSign = keccak256(hash); 
        Version memory v = Version(version,hashedSign,now);
        digitalCertificateArchive[hashed].push(v);
        
    }

    function GetSign(string guid, address signer) public view returns(bytes32 sign, uint8 signedVersion,uint256 timestamp){
        address _signer = signer;
        string memory addressString = toString(_signer);
         
        string memory concatenatedData = strConcat(addressString,guid);
        bytes32 hashed = keccak256(concatenatedData);
        uint length =  digitalCertificateArchive[hashed].length;
        Version memory v = digitalCertificateArchive[hashed][length-1];
        return (v.sign, v.version, v.timestamp);
    }

    function GetSignVersion(string guid, address signer, uint version) public view returns(bytes32 sign, uint8 signedVersion,uint256 timestamp){
        address _signer = signer;
        string memory addressString = toString(_signer);
         
        string memory concatenatedData = strConcat(addressString,guid);
        bytes32 hashed = keccak256(concatenatedData);
        Version memory v = digitalCertificateArchive[hashed][version-1];
        return (v.sign, v.version, v.timestamp);
    }

    
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    
    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    
    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }
    
    function toString(address x) returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
    return string(bytesStringTrimmed);
}

    mapping (address => bool) whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    whitelist[msg.sender] == true;
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    whitelist[addr] = true;
    emit WhitelistedAddressAdded(addr);
  }

   
  function isInWhitelist(address addr)
    public
    view
    returns (bool)
  {
    return whitelist[addr] == true;
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    whitelist[addr] = false;
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }
    
}
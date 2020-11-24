 

pragma solidity ^0.4.15;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

interface AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

interface InterCrypto_Interface {
     
    event ConversionStarted(uint indexed conversionID);
    event ConversionSentToShapeShift(uint indexed conversionID, address indexed returnAddress, address indexed depositAddress, uint amount);
    event ConversionAborted(uint indexed conversionID, string reason);
    event Recovered(address indexed recoveredTo, uint amount);

     
    function getInterCryptoPrice() constant public returns (uint);
    function convert1(string _coinSymbol, string _toAddress) external payable returns (uint conversionID);
    function convert2(string _coinSymbol, string _toAddress, address _returnAddress) external payable returns(uint conversionID);
    function recover() external;
    function recoverable(address myAddress) constant public returns (uint);
    function cancelConversion(uint conversionID) external;
}

interface AbstractPublicResolver {
    function PublicResolver(address ensAddr);
    function supportsInterface(bytes4 interfaceID) constant returns (bool);
    function addr(bytes32 node) constant returns (address ret);
    function setAddr(bytes32 node, address addr);
    function hash(bytes32 node) constant returns (bytes32 ret);
    function setHash(bytes32 node, bytes32 hash);
}

contract usingInterCrypto is Ownable {
    AbstractENS public abstractENS;
    AbstractPublicResolver public abstractResolver;
    InterCrypto_Interface public interCrypto;
    
    bytes32 public ResolverNode;  
    bytes32 public InterCryptoNode;  
    
    function usingInterCrypto() public {
        setNetwork();
        updateResolver();
        updateInterCrypto();
        
    }
    
    function setNetwork() internal returns(bool) {
        if (getCodeSize(0x314159265dD8dbb310642f98f50C066173C1259b)>0){  
            abstractENS = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
            ResolverNode = 0xfdd5d5de6dd63db72bbc2d487944ba13bf775b50a80805fe6fcaba9b0fba88f5;  
            InterCryptoNode = 0x921a56636fce44f7cbd33eed763c940f580add9ffb4da7007f8ff6e99804a7c8;  
        }
        else if (getCodeSize(0xe7410170f87102df0055eb195163a03b7f2bff4a)>0){  
            abstractENS = AbstractENS(0xe7410170f87102df0055eb195163a03b7f2bff4a);
            ResolverNode = 0xf2cf3eab504436e1b5a541dd9fbc5ac8547b773748bbf2bb81b350ee580702ca;  
            InterCryptoNode = 0xbe93c9e419d658afd89a8650dd90e37e763e75da1e663b9d57494aedf27f3eaa;  
        }
        else if (getCodeSize(0x112234455c3a32fd11230c42e7bccd4a84e02010)>0){  
            abstractENS = AbstractENS(0x112234455c3a32fd11230c42e7bccd4a84e02010);
            ResolverNode = 0xf2cf3eab504436e1b5a541dd9fbc5ac8547b773748bbf2bb81b350ee580702ca;  
            InterCryptoNode = 0xbe93c9e419d658afd89a8650dd90e37e763e75da1e663b9d57494aedf27f3eaa;  
        }
        else {
            revert();
        }
    }
    
    function updateResolver() onlyOwner public {
        abstractResolver = AbstractPublicResolver(abstractENS.resolver(ResolverNode));
    }
        
    function updateInterCrypto() onlyOwner public {
        interCrypto = InterCrypto_Interface(abstractResolver.addr(InterCryptoNode));
    }
    
    function updateInterCryptonode(bytes32 newNodeName) onlyOwner public {
        InterCryptoNode = newNodeName;
    }
        
    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
        return _size;
    }
    
    function intercrypto_convert(uint amount, string _coinSymbol, string _toAddress) internal returns (uint conversionID) {
        return interCrypto.convert1.value(amount)(_coinSymbol, _toAddress);
    }
    
    function intercrypto_convert(uint amount, string _coinSymbol, string _toAddress, address _returnAddress) internal returns(uint conversionID) {
        return interCrypto.convert2.value(amount)(_coinSymbol, _toAddress, _returnAddress);
    }
    
     
     
    
     
     
     
     
     
     
     
     
     
     
     
     
}

contract InterCrypto_Wallet is usingInterCrypto {

    event Deposit(address indexed deposit, uint amount);
    event WithdrawalNormal(address indexed withdrawal, uint amount);
    event WithdrawalInterCrypto(uint indexed conversionID);

    mapping (address => uint) public funds;
    
    function InterCrypto_Wallet() {}

    function () payable {}
    
    function deposit() payable {
      if (msg.value > 0) {
          funds[msg.sender] += msg.value;
          Deposit(msg.sender, msg.value);
      }
    }
    
    function intercrypto_getInterCryptoPrice() constant public returns (uint) {
        return interCrypto.getInterCryptoPrice();
    }
    
    function withdrawalNormal() payable external {
        uint amount = funds[msg.sender] + msg.value;
        funds[msg.sender] = 0;
        if(msg.sender.send(amount)) {
            WithdrawalNormal(msg.sender, amount);
        }
        else {
            funds[msg.sender] = amount;
        }
    }
    
    function withdrawalInterCrypto(string _coinSymbol, string _toAddress) external payable {
        uint amount = funds[msg.sender] + msg.value;
        funds[msg.sender] = 0;
        uint conversionID = intercrypto_convert(amount, _coinSymbol, _toAddress);
        WithdrawalInterCrypto(conversionID);
    }
    
    
    function intercrypto_recover() onlyOwner public {
        interCrypto.recover();
    }
    
    function intercrypto_recoverable() constant public returns (uint) {
        return interCrypto.recoverable(this);
    }
    
    function intercrypto_cancelConversion(uint conversionID) onlyOwner external {
        interCrypto.cancelConversion(conversionID);
    }
    
    function kill() onlyOwner external {
        selfdestruct(owner);
    }
}
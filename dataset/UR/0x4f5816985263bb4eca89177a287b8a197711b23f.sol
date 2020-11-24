 

 
  
 
 
pragma solidity ^0.4.20;

  
contract abcResolverI{
    function getWalletAddress() public view returns (address);
    function getAddress() public view returns (address);
}

  
contract inviterBook{
    using SafeMath for *;
     
    address public owner;
    abcResolverI public resolver;
    address public wallet;
    address public lotto;
    
    mapping (address=>bytes32) _alias;
    mapping (bytes32=>address) _addressbook;
    mapping (address=>address) _inviter;
    mapping (address=>uint) _earnings;
    mapping (address=>bool) _isRoot;
    uint public rootNumber = 0;

     
    uint constant REGISTRATION_FEE = 10000000000000000;     
    
     

     
    modifier abcInterface {
        if((address(resolver)==0)||(getCodeSize(address(resolver))==0)){
            if(abc_initNetwork()){
                wallet = resolver.getWalletAddress();
                lotto = resolver.getAddress();
            }
        }
        else{
            if(wallet != resolver.getWalletAddress())
                wallet = resolver.getWalletAddress();

            if(lotto != resolver.getAddress())
                lotto = resolver.getAddress();
        }    
        
        _;        
    }    

     
    modifier onlyOwner {
        require(msg.sender == owner);
        
        _;
    }

    modifier onlyAuthorized{
        require(
            msg.sender == lotto
        );
        
        _;
    }
     
    event OnRegisterAlias(address user, bytes32 alias);
    event OnAddRoot(address root);
    event OnSetInviter(address user, address inviter);
    event OnWithdraw(address user, uint earning);
    event OnPay(address user, uint value);
    
     
    constructor() public{
        owner = msg.sender;
    }

     
     
     
    function addRoot(address addr) onlyOwner public{
        require(_inviter[addr] == address(0x0) && _isRoot[addr] == false); 
        _isRoot[addr] = true;
        rootNumber++;
        emit OnAddRoot(addr);
    }

     
    function isRoot(address addr) 
        public
        view 
        returns(bool)
    {
        return _isRoot[addr];
    }

     
    function isRoot() 
        public
        view 
        returns(bool)
    {
        return _isRoot[msg.sender];
    }

      
     function setOwner(address newOwner) 
        onlyOwner 
        public
    {
        require(newOwner != address(0x0));
        owner = newOwner;
    }    

     
     
     
      
    function hasInviter(address addr) 
        public 
        view
        returns(bool)
    {
        if(_inviter[addr] != address(0x0))
            return true;
        else
            return false;
    } 
          
    function hasInviter() 
        public 
        view
        returns(bool)
    {
        if(_inviter[msg.sender] != address(0x0))
            return true;
        else
            return false;
    } 

           
    function setInviter(string inviter) public{
          
        require(_isRoot[msg.sender] == false);

         
        require(_inviter[msg.sender] == address(0x0)); 

         
        bytes32 _name = stringToBytes32(inviter);        
        require(_addressbook[_name] != address(0x0));
        
         
        require(_addressbook[_name] != msg.sender);       

         
        require(isValidInviter(_addressbook[_name]));

        _inviter[msg.sender] = _addressbook[_name];
        emit OnSetInviter(msg.sender, _addressbook[_name]);
    }
        
    function setInviter(address addr, string inviter) 
        abcInterface
        public
        onlyAuthorized
    {
         
        require(_isRoot[addr] == false);

         
        require(_inviter[addr] == address(0x0)); 

         
        bytes32 _name = stringToBytes32(inviter);        
        require(_addressbook[_name] != address(0x0));

         
        require(_addressbook[_name] != addr);       

         
        require(isValidInviter(_addressbook[_name]));

        _inviter[addr] = _addressbook[_name];
        emit OnSetInviter(addr, _addressbook[_name]);
    }
 
      
    function setInviterXAddr(address inviter) public{
         
        require(_isRoot[msg.sender] == false);

         
        require(_inviter[msg.sender] == address(0x0)); 

         
        require(inviter != address(0x0));

         
        require(inviter != msg.sender);       

         
        require(_alias[inviter] != bytes32(0x0));

         
        require(isValidInviter(inviter));

        _inviter[msg.sender] = inviter;
        emit OnSetInviter(msg.sender, inviter);
    }
 
      
    function setInviterXAddr(address addr, address inviter) 
        abcInterface
        public
        onlyAuthorized
    {
          
        require(_isRoot[addr] == false);

         
        require(_inviter[addr] == address(0x0)); 

         
        require(inviter != address(0x0));

         
        require(inviter != addr);       

         
        require(_alias[inviter] != bytes32(0x0));

         
        require(isValidInviter(inviter));

         _inviter[addr] = inviter;
         emit OnSetInviter(addr, inviter);
    }
    
       
     function getInviter() 
        public 
        view
        returns(string)
     {
         if(!hasInviter(msg.sender)) return "";
        
         return bytes32ToString(_alias[_inviter[msg.sender]]);
     }  
 
        
     function getInviterAddr() 
        public 
        view
        returns(address)
     {
         return _inviter[msg.sender];
     } 

      
     function isValidInviter(address inviter)
        internal
        view
        returns(bool)
    {
        address addr = inviter;
        while(_inviter[addr] != address(0x0)){
            addr = _inviter[addr];
        } 
        
        if(_isRoot[addr] == true)
            return true;
        else
            return false;
    }
     
        
     function getEarning()
        public 
        view 
        returns (uint)
     {
         return _earnings[msg.sender];
     }

       
     function withdraw() public {
         uint earning = _earnings[msg.sender];
         if(earning>0){
             _earnings[msg.sender] = 0;
             msg.sender.transfer(earning);
             emit OnWithdraw(msg.sender, earning);             
         }
     }

      
    function() 
        abcInterface
        public 
        payable 
    {
        address addr = msg.sender;
        uint balance = msg.value;
        uint earning = 0;
        
        while(_inviter[addr] != address(0x0)){
            addr = _inviter[addr];
            earning = balance.div(2);
            balance = balance.sub(earning);
            _earnings[addr] = _earnings[addr].add(earning);
        }
        
        wallet.transfer(balance);
        emit OnPay(msg.sender, msg.value);
    }
     
      
    function pay(address addr) 
        abcInterface
        public 
        payable 
        onlyAuthorized
    {
        address _addr = addr;
        uint balance = msg.value;
        uint earning = 0;
        
        while(_inviter[_addr] != address(0x0)){
            _addr = _inviter[_addr];
            earning = balance.div(2);
            balance = balance.sub(earning);
            _earnings[_addr] = _earnings[_addr].add(earning);
        }
        
        wallet.transfer(balance);
        emit OnPay(addr, msg.value);
    }
     
          
     function registerAlias(string alias) 
        abcInterface 
        public 
        payable
     {
         require(msg.value >= REGISTRATION_FEE);
         
          
         bytes32 _name = nameFilter(alias);
         require(_addressbook[_name] == address(0x0));

          
         require(hasInviter() || _isRoot[msg.sender] == true);

         if(_alias[msg.sender] != bytes32(0x0)){
              
            _addressbook[_alias[msg.sender]] = address(0x0);
         }
         _alias[msg.sender] = _name;
         _addressbook[_name] = msg.sender;

         wallet.transfer(REGISTRATION_FEE);
          
         if(msg.value > REGISTRATION_FEE){
             msg.sender.transfer( msg.value.sub( REGISTRATION_FEE ));
         }
         emit OnRegisterAlias(msg.sender,_name);
     }    
     
        
     function aliasExist(string alias) 
        public 
        view 
        returns(bool) 
    {
        bytes32 _name = stringToBytes32(alias);
        if(_addressbook[_name] == address(0x0))
            return false;
        else
            return true;
     }
     
       
    function getAlias() 
        public 
        view 
        returns(string)
    {
         return bytes32ToString(_alias[msg.sender]);
    }

     
      
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0);
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78);
            require(_temp[1] != 0x58);
        }
        
         
        bool _hasNonNumber;
        
         
        for (uint256 i = 0; i < _length; i++)
        {
            require
            (
                 
                (_temp[i] > 0x40 && _temp[i] < 0x5b) || 
                 
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                 
                (_temp[i] > 0x2f && _temp[i] < 0x3a)
             );
                
             
            if (_hasNonNumber == false && _temp[i] > 0x3a)
                _hasNonNumber = true;    
        
        }
        
        require(_hasNonNumber == true);
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }    
 
     
    function stringToBytes32(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        if (_length > 32 || _length == 0) return "";
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }   

         
     function bytes32ToString(bytes32 x) 
        internal
        pure 
        returns (string) 
    {
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
     
      
    function abc_initNetwork() 
        internal 
        returns(bool) 
    { 
          
         if (getCodeSize(0xde4413799c73a356d83ace2dc9055957c0a5c335)>0){     
            resolver = abcResolverI(0xde4413799c73a356d83ace2dc9055957c0a5c335);
            return true;
         }
         
          
         if (getCodeSize(0xcaddb7e777f7a1d4d60914cdae52aca561d539e8)>0){     
            resolver = abcResolverI(0xcaddb7e777f7a1d4d60914cdae52aca561d539e8);
            return true;
         }         
          

         return false;
    }      
     
     function getCodeSize(address _addr) 
        internal 
        view 
        returns(uint _size) 
    {
         assembly {
             _size := extcodesize(_addr)
         }
    }
}

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) public pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) public pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
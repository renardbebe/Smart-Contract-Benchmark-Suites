 

pragma solidity ^0.4.18;

 
interface ERC20Token {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function balanceOf(address _owner) public view returns (uint);
    function allowance(address _owner, address _spender) public view returns (uint);    
}


 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    address public owner;

    function Ownable()
        public
    {        
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        assert(msg.sender == owner);    
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        owner = newOwner;
    } 
}


contract Freezable is Ownable {

    mapping (address => bool) public frozenAccount;      
    
    modifier onlyUnfrozen(address _target) {
        assert(!isFrozen(_target));
        _;
    }
    
     
    function isFrozen(address _target)
        public
        view
        returns (bool)
    {
        return frozenAccount[_target];
    }
}

contract Token is ERC20Token, Freezable {
     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances; 
    mapping (address => string) public data;
    uint    public totalSupply;
    uint    public timeTransferbleUntil = 1538262000;                         
    bool    public stopped = false;
 
    event Burn(address indexed from, uint256 value, string data);
    event LogStop();

    modifier transferable() {
        assert(!stopped);
        _;
    }

     
     
     
     
     
    function transfer(address _to, uint _value)
        public      
        onlyUnfrozen(msg.sender)                                           
        transferable()
        returns (bool)        
    {                         
        assert(_to != 0x0);                                                 
        assert(balances[msg.sender] >= _value);                             
        assert(!isFrozen(_to));                                             
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);  
        balances[_to] = SafeMath.add(balances[_to], _value);                
        Transfer(msg.sender, _to, _value);                                  
        return true;       
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public    
        onlyUnfrozen(_from)                                                
        transferable()                 
        returns (bool)
    {        
        assert(_to != 0x0);                                                
        assert(balances[_from] >= _value);                                 
        assert(_value <= allowances[_from][msg.sender]);                   
        assert(!isFrozen(_to));                                            
        balances[_from] = SafeMath.sub(balances[_from], _value);           
        balances[_to] = SafeMath.add(balances[_to], _value);               
        allowances[_from][msg.sender] = SafeMath.sub(allowances[_from][msg.sender], _value); 
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value)
        public
        returns (bool)
    {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint)
    {
        return allowances[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner)
        public
        view
        returns (uint)
    {
        return balances[_owner];
    }

     
     
     
    function burn(uint256 _value, string _data) 
        public 
        returns (bool success) 
    {
        assert(_value > 0);                                                 
        assert(balances[msg.sender] >= _value);                             
        uint previousTotal = totalSupply;                                   
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);  
        data[msg.sender] = _data;                                           
        totalSupply = SafeMath.sub(totalSupply, _value);                    
        assert(previousTotal - _value == totalSupply);                      
        Burn(msg.sender, _value, _data);
        return true;
    }

     
    function stop() 
        public
    {
        assert(now > timeTransferbleUntil);
        stopped = true;
        LogStop();
    }

    function totalSupply() 
        constant public 
        returns (uint) 
    {
        return totalSupply;
    }

    function getData(address addr) 
        public 
        view
        returns (string) 
    {
        return data[addr];
    }    
}


 
contract STP is Token {
    string  public name = "STASHPAY";
    string  public symbol = "STP";
    uint8   public decimals = 8;
    uint8   public publicKeySize = 65;
    address public sale = 0xB155c16c13FC1eD2F015e24D6C7Ae8Cc38cea74E;
    address public adviserAndBounty = 0xf40bF198eD3bE9d3E1312d2717b964b377135728;    
    mapping (address => string) public publicKeys;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;    

    event RegisterKey(address indexed _from, string _publicKey);
    event ModifyPublicKeySize(uint8 _size);

    function STP()
    public 
    {             
        uint256[29] memory owners = [
            uint256(0xb5e620f480007f0dfc26a56b0f7ccd8100eaf31b75dd40bae01f),
            uint256(0x162b3f376600078c63f73a2f46c19a4cd91e700203bbbe4084093),
            uint256(0x16bcc41e900004ae21e3c9b0e63dbc2832f1fa3e6e4dd60f42ae1),
            uint256(0x1c6bf52634000b9b206c23965553889ebdaee326d4da4a457b9b1),
            uint256(0x16bcc41e90000d26061a8d47cc712c61a8fa23ce21d593e50f668),
            uint256(0x110d9316ec000d69106be0299d0a83b9a9e32f2df85ec7739fa59),
            uint256(0x16bcc41e90000d6d813fd0394bfec48996e20d8fbcf55a003c19a),
            uint256(0x1c6bf52634000e34dc2c4481561224114ad004c824b1f9e142e31),
            uint256(0x110d9316ec0006e19b79b974fa039c1356f6814da22b0a04e8d29),
            uint256(0x16bcc41e900005d2f999136e12e54f4a9a873a9d9ab7407591249),
            uint256(0x110d9316ec0002b0013a364a997b9856127fd0ababef72baec159),
            uint256(0x16bcc41e90000db46260f78efa6c904d7dafc5c584ca34d5234be),
            uint256(0x1c6bf5263400073a4077adf235164f4944f138fc9d982ea549eba),
            uint256(0x9184e72a0003617280cabfe0356a2af3cb4f652c3aca3ab8216),
            uint256(0xb5e620f480003d106c1220c49f75ddb8a475b73a1517cef163f6),
            uint256(0x9184e72a000d6aaf14fee58fd90e6518179e94f02b5e0098a78),
            uint256(0x162b3f37660009c98c23e430b4270f47685e46d651b9150272b16),
            uint256(0xb5e620f48000cc3e7d55bba108b07c08d014f13fe0ee5c09ec08),
            uint256(0x110d9316ec000e4a92d9c2c31789250956b1b0b439cf72baf8a27),
            uint256(0x16bcc41e900002edc2b7f7191cf9414d9bf8febdd165b0cd91ee1),
            uint256(0x110d9316ec000332f79ebb69d00cb3f13fcb2be185ed944f64298),
            uint256(0x221b262dd80005594aae7ae31a3316691ab7a11de3ddee2f015e0),
            uint256(0x1c6bf52634000c08b91c50ed4303d1b90ffd47237195e4bfc165e),
            uint256(0x110d9316ec000bf6f7c6a13b9629b673c023e54fba4c2cd4ccbba),
            uint256(0x16bcc41e90000629048b47ed4fb881bacfb7ca85e7275cd663cf7),
            uint256(0x110d9316ec000451861e95aa32ce053f15f6ae013d1eface88e9e),
            uint256(0x16bcc41e9000094d79beb8c57e54ff3fce49ae35078c6df228b9c),
            uint256(0x1c6bf52634000e2b1430b79b5be8bf3c7d70eb4faf36926b369f3),
            uint256(0xb5e620f4800025b772bda67719d2ba404c04fa4390443bf993ed)
        ];

         

        totalSupply = 500000000 * 10**uint256(decimals); 
        balances[sale] = 360000000 * 10**uint256(decimals); 
        balances[adviserAndBounty] = 40000000 * 10**uint256(decimals);
            
        Transfer(0, sale, balances[sale]);
        Transfer(0, adviserAndBounty, balances[adviserAndBounty]);
        
         
        uint assignedTokens = balances[sale] + balances[adviserAndBounty];
        for (uint i = 0; i < owners.length; i++) {
            address addr = address(owners[i] & (D160 - 1));                     
            uint256 amount = owners[i] / D160;                                  
            balances[addr] = SafeMath.add(balances[addr], amount);              
            assignedTokens = SafeMath.add(assignedTokens, amount);              
            frozenAccount[addr] = true;                                         
            Transfer(0, addr, amount);                                          
        }        
         
        require(assignedTokens == totalSupply);             
    }  
    
    function registerKey(string publicKey)
    public
    transferable
    { 
        assert(balances[msg.sender] > 0);
        assert(bytes(publicKey).length <= publicKeySize);
              
        publicKeys[msg.sender] = publicKey; 
        RegisterKey(msg.sender, publicKey);    
    }           
  
    function modifyPublicKeySize(uint8 _publicKeySize)
    public
    onlyOwner
    { 
        publicKeySize = _publicKeySize;
    }

    function multiDistribute(uint256[] data) 
    public
    onlyUnfrozen(sale)
    onlyOwner 
    {
      for (uint256 i = 0; i < data.length; i++) {
        address addr = address(data[i] & (D160 - 1));
        uint256 amount = data[i] / D160;
        balances[sale] -= amount;                        
        balances[addr] += amount;                                       
        Transfer(sale, addr, amount);    
      }
    }

    function multiDistributeAdviserBounty(uint256[] data, bool freeze) 
    public
    onlyOwner
    {
        for (uint256 i = 0; i < data.length; i++) {
            address addr = address(data[i] & (D160 - 1));
            uint256 amount = data[i] / D160;
            distributeAdviserBounty(addr, amount, freeze);
        }
    }
   
    function distributeAdviserBounty(address addr, uint256 amount, bool freeze)
    public        
    onlyOwner 
    {   
         
        frozenAccount[addr] = freeze && balances[addr] == 0;

        balances[addr] = SafeMath.add(balances[addr], amount);
        balances[adviserAndBounty] = SafeMath.sub(balances[adviserAndBounty], amount);
        Transfer(adviserAndBounty, addr, amount);           
    }

     
    function distributionComplete()
    public
    onlyOwner
    {
        frozenAccount[sale] = true;
    }

    function setName(string _name)
    public 
    onlyOwner 
    {
        name = _name;
    }

    function setSymbol(string _symbol)
    public 
    onlyOwner 
    {
        symbol = _symbol;
    }
}
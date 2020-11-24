 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}





 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



 

 contract LockToken is StandardToken {
   using SafeMath for uint256;

   bool public isPublic;
   uint256 public unLockTime;
   PrivateToken public privateToken;

   modifier onlyPrivateToken() {
     require(msg.sender == address(privateToken));
     _;
   }

    

   function deposit(address _depositor, uint256 _value) public onlyPrivateToken returns(bool){
     require(_value != 0);
     balances[_depositor] = balances[_depositor].add(_value);
     emit Transfer(privateToken, _depositor, _value);
     return true;
   }

   constructor() public {
      
     unLockTime = 2556057600;
   }
 }

contract BCNTToken is LockToken{
  string public constant name = "Bincentive SIT Token";  
  string public constant symbol = "BCNT-SIT";  
  uint8 public constant decimals = 18;  
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  mapping(bytes => bool) internal signatures;
  event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

     
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        require(block.number <= _validUntil);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(transferPreSignedHashing(address(this), _to, _value, _fee, _nonce, _validUntil));

        address from = ECRecovery.recover(hashedTx, _signature);
        require(from != address(0));

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        signatures[_signature] = true;

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

     
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(bytes4(0x0a0fb66b), _token, _to, _value, _fee, _nonce, _validUntil);
    }
    function transferPreSignedHashingWithPrefix(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        return ECRecovery.toEthSignedMessageHash(transferPreSignedHashing(_token, _to, _value, _fee, _nonce, _validUntil));
    }

     
    constructor(address _admin) public {
        totalSupply_ = INITIAL_SUPPLY;
        privateToken = new PrivateToken(
          _admin, "Bincentive Private SIT Token", "BCNP-SIT", decimals, INITIAL_SUPPLY
       );
    }
}


 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}



 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


pragma solidity ^0.4.24;
pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract PrivateToken is StandardToken {
    using SafeMath for uint256;

    string public name;  
    string public symbol;  
    uint8 public decimals;  

    address public admin;
    bool public isPublic;
    uint256 public unLockTime;
    LockToken originToken;

    event StartPublicSale(uint256);
    event Deposit(address indexed from, uint256 value);
     
    function isDepositAllowed() internal view{
       
      require(isPublic);
      require(msg.sender == admin || block.timestamp > unLockTime);
    }

     
    function deposit() public returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[msg.sender];
      require(_value > 0);
      balances[msg.sender] = 0;
      require(originToken.deposit(msg.sender, _value));
      emit Deposit(msg.sender, _value);
    }

     
    function adminDeposit(address _depositor) public onlyAdmin returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[_depositor];
      require(_value > 0);
      balances[_depositor] = 0;
      require(originToken.deposit(_depositor, _value));
      emit Deposit(_depositor, _value);
    }

     
    function startPublicSale(uint256 _unLockTime) public onlyAdmin {
      require(!isPublic);
      isPublic = true;
      unLockTime = _unLockTime;
      emit StartPublicSale(_unLockTime);
    }

     
    function unLock() public onlyAdmin{
      require(isPublic);
      unLockTime = block.timestamp;
    }


    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

    constructor(address _admin, string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
      originToken = LockToken(msg.sender);
      admin = _admin;
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply_ = _totalSupply;
      balances[admin] = _totalSupply;
      emit Transfer(address(0), admin, _totalSupply);
    }
}
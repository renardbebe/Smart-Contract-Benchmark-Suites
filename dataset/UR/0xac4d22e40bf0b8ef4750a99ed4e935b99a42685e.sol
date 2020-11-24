 

pragma solidity ^0.4.23;

 
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

 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract Secured is Owned {
    address public admin;

    event SetAdmin(address indexed _admin);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        admin = _newAdmin;
        emit SetAdmin(admin);
    }
}


 
contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract BasicToken is ERC20 {
  using SafeMath for uint256;
  
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
}


 
contract Timelocked is Owned {
  uint256 public lockstart;
  uint256 public lockend;

  event SetTimelock(uint256 start, uint256 end);

   
  modifier notTimeLocked() {
    require((msg.sender == owner) || (now < lockstart || now > lockend));
    _;
  }

  function setTimeLock(uint256 _start, uint256 _end) public onlyOwner {
    require(_end > _start);
    lockstart = _start;
    lockend = _end;
    
    emit SetTimelock(_start, _end);
  }
  
  function releaseTimeLock() public onlyOwner {
    lockstart = 0;
    lockend = 0;
    
    emit SetTimelock(0, 0);
  }

}

 
contract MintableToken is BasicToken, Owned, Secured {
  event Mint(address indexed to, uint256 amount);

   
  function mint(
    uint256 _amount
  )
    onlyAdmin
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[owner] = balances[owner].add(_amount);
    emit Mint(owner, _amount);
    emit Transfer(address(0), owner, _amount);
    return true;
  }
}


 
contract BurnableToken is BasicToken, Owned, Secured {
   
  address public coldledger; 

  event SetColdledger(address ledger);
  event BurnForTransaction(address who, uint256 nft, string txtype, uint256 value);

  function setColdLedger(address ledger) public onlyOwner {
      require(ledger != address(0));
      coldledger = ledger;
      emit SetColdledger(ledger);
  }

    
  function reserveAll() public onlyOwner {
    uint256 val = balances[owner];
    balances[coldledger] = balances[coldledger].add(val);
    emit Transfer(owner, coldledger, val);
  }
  
   
  function burn(uint256 _nft, string _txtype, uint256 _value) public onlyAdmin {
    require(_value <= balances[coldledger]);

    balances[coldledger] = balances[coldledger].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit BurnForTransaction(coldledger, _nft, _txtype, _value);
    emit Transfer(coldledger, address(0), _value);
  }
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract AerToken is Timelocked, MintableToken, BurnableToken {

  string public name;
  string public symbol;
  uint256 public decimals;
  
  constructor(address coldledger) public {
    name = "Aeryus Token";
    symbol = "AER";
    decimals = 18;
    totalSupply_ = 4166666663000000000000000000;
    balances[msg.sender] = totalSupply_;
    setColdLedger(coldledger);
    
    emit Transfer(address(0), msg.sender, totalSupply_);
  }
  
   
  function transfer(address _to, uint256 _value) public notTimeLocked returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

     
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public notTimeLocked
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

     

     

     

    function () public payable {
        revert();
    }


     

     

     

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return BasicToken(tokenAddress).transfer(owner, tokens);

    }
}
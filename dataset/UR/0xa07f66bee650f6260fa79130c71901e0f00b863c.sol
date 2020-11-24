 

pragma solidity ^0.4.24;

 

 
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

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

 

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 

contract Token is MintableToken, NoOwner {
    string public symbol = "TKT";
    string public name = "Ticket token";
    uint8 public constant decimals = 18;

    address founder;  
    function init(address _founder) onlyOwner public {
        founder = _founder;
    }

    function getFounder() public returns(address) {
        return founder;
    }

     
    modifier canTransfer() {
        require(mintingFinished || msg.sender == founder);
        _;
    }

    function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

contract Crowdsale {
    using SafeMath for uint256;

    address manager;
    address owner;

    uint64 public startTimestamp;    
    uint64 public endTimestamp;      
    uint256 public goal;             
    uint256 public hardCap;          
    uint256 public rate;             

    uint256 public tokensSold;       
    uint256 public tokensMinted;     
    uint256 public collectedEther;   

    mapping(address => uint256) contributions;  

    Token public token;

    bool public finalized;

    modifier onlyOwner() {
      require((msg.sender == owner) || (msg.sender == manager));
      _;
    }

    constructor(
        uint64 _startTimestamp, uint64 _endTimestamp, uint256 _rate,
        uint256 _founderTokens, uint256 _goal, uint256 _hardCap,
        address _owner
        ) public {
      require(_startTimestamp > now);
        require(_startTimestamp < _endTimestamp);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        require(_hardCap > 0);
        hardCap = _hardCap;

        goal = _goal;

        require(_rate > 0);
        rate = _rate;

        owner = _owner;
        manager = msg.sender;

        token = new Token();
        token.init(owner);

        require(_founderTokens < _hardCap);
        mintTokens(owner, _founderTokens);
    }

     
    function () public payable {
        require(crowdsaleOpen());
        require(msg.value > 0);
        collectedEther = collectedEther.add(msg.value);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        uint256 amount = getTokensForValue(msg.value);
        tokensSold = tokensSold.add(amount);
        mintTokens(msg.sender, amount);
    }

     
    function getTokensForValue(uint256 value) public view returns(uint256) {
        return value.mul(rate);
    }


     
    function crowdsaleOpen() view public returns(bool) {
        return !finalized && (tokensMinted < hardCap) && (startTimestamp <= now) && (now <= endTimestamp);
    }

     
    function getTokensLeft() view public returns(uint256) {
        return hardCap.sub(tokensMinted);
    }

     
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);
        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));
    }

     
    function refund() public returns(bool) {
        return refundTo(msg.sender);
    }
    function refundTo(address beneficiary) public returns(bool) {
        require(contributions[beneficiary] > 0);
        require(finalized || (now > endTimestamp));
        require(tokensSold < goal);

        uint256 value = contributions[beneficiary];
        contributions[beneficiary] = 0;
        beneficiary.transfer(value);
        return true;
    }

     
    function finalizeCrowdsale() public onlyOwner {
        finalized = true;
        token.finishMinting();
        token.transferOwnership(owner);
        if (tokensSold >= goal && address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

     
    function claimEther() public onlyOwner {
        require(tokensSold >= goal);
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

}
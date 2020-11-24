 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract FUTC is StandardToken {
  using SafeMath for uint;

  string public constant name = "Futereum Centurian";
  string public constant symbol = "FUTC";
  uint8 public constant decimals = 0;

  address public admin;
  uint public totalEthReleased = 0;

  mapping(address => uint) public ethReleased;
  address[] public trackedTokens;
  mapping(address => bool) public isTokenTracked;
  mapping(address => uint) public totalTokensReleased;
  mapping(address => mapping(address => uint)) public tokensReleased;

  constructor() public {
    admin = msg.sender;
    totalSupply_ = 100000;
    balances[admin] = totalSupply_;
    emit Transfer(address(0), admin, totalSupply_);
  }

  function () public payable {}

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function changeAdmin(address _receiver) onlyAdmin external {
    admin = _receiver;
  }

   
  function claimEth() external {
    claimEthFor(msg.sender);
  }

   
  function claimEthFor(address payee) public {
    require(balances[payee] > 0);

    uint totalReceived = address(this).balance.add(totalEthReleased);
    uint payment = totalReceived.mul(
      balances[payee]).div(
        totalSupply_).sub(
          ethReleased[payee]
    );

    require(payment != 0);
    require(address(this).balance >= payment);

    ethReleased[payee] = ethReleased[payee].add(payment);
    totalEthReleased = totalEthReleased.add(payment);

    payee.transfer(payment);
  }

   
  function claimMyTokens() external {
    claimTokensFor(msg.sender);
  }

   
  function claimTokensFor(address payee) public {
    require(balances[payee] > 0);

    for (uint16 i = 0; i < trackedTokens.length; i++) {
      claimToken(trackedTokens[i], payee);
    }
  }

   
  function claimToken(address _tokenAddr, address _payee) public {
    require(balances[_payee] > 0);
    require(isTokenTracked[_tokenAddr]);

    uint payment = getUnclaimedTokenAmount(_tokenAddr, _payee);
    if (payment == 0) {
      return;
    }

    ERC20 Token = ERC20(_tokenAddr);
    require(Token.balanceOf(address(this)) >= payment);
    tokensReleased[address(Token)][_payee] = tokensReleased[address(Token)][_payee].add(payment);
    totalTokensReleased[address(Token)] = totalTokensReleased[address(Token)].add(payment);
    Token.transfer(_payee, payment);
  }

   
  function getUnclaimedTokenAmount(address tokenAddr, address payee) public view returns (uint) {
    ERC20 Token = ERC20(tokenAddr);
    uint totalReceived = Token.balanceOf(address(this)).add(totalTokensReleased[address(Token)]);
    uint payment = totalReceived.mul(
      balances[payee]).div(
        totalSupply_).sub(
          tokensReleased[address(Token)][payee]
    );
    return payment;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(msg.sender != _to);
    uint startingBalance = balances[msg.sender];
    require(super.transfer(_to, _value));

    transferChecks(msg.sender, _to, _value, startingBalance);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
    require(_from != _to);
    uint startingBalance = balances[_from];
    require(super.transferFrom(_from, _to, _value));

    transferChecks(_from, _to, _value, startingBalance);
    return true;
  }

  function transferChecks(address from, address to, uint checks, uint startingBalance) internal {

     
    uint claimedEth = ethReleased[from].mul(
      checks).div(
        startingBalance
    );

     
    ethReleased[to] = ethReleased[to].add(claimedEth);

     
    ethReleased[from] = ethReleased[from].sub(claimedEth);

    for (uint16 i = 0; i < trackedTokens.length; i++) {
      address tokenAddr = trackedTokens[i];

       
      uint claimed = tokensReleased[tokenAddr][from].mul(
        checks).div(
          startingBalance
      );

       
      tokensReleased[tokenAddr][to] = tokensReleased[tokenAddr][to].add(claimed);

       
      tokensReleased[tokenAddr][from] = tokensReleased[tokenAddr][from].sub(claimed);
    }
  }

  function trackToken(address _addr) onlyAdmin external {
    require(_addr != address(0));
    require(!isTokenTracked[_addr]);
    trackedTokens.push(_addr);
    isTokenTracked[_addr] = true;
  }

   
  function unTrackToken(address _addr, uint16 _position) onlyAdmin external {
    require(isTokenTracked[_addr]);
    require(trackedTokens[_position] == _addr);

    ERC20(_addr).transfer(_addr, ERC20(_addr).balanceOf(address(this)));
    trackedTokens[_position] = trackedTokens[trackedTokens.length-1];
    delete trackedTokens[trackedTokens.length-1];
    trackedTokens.length--;
  }
}
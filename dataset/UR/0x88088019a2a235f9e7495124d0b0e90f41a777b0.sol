 

pragma solidity 0.5.6;

 
 
 
contract SafeMath {
     
    constructor() public {
    }

     
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
 
 
contract iERC20Token {
  function balanceOf( address who ) public view returns (uint value);
  function allowance( address owner, address spender ) public view returns (uint remaining);
  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);
  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
   
   
   
   
   
}

 
 
contract iDividendToken {
  function checkDividends(address _addr) view public returns(uint _ethAmount, uint _daiAmount);
  function withdrawEthDividends() public returns (uint _amount);
  function withdrawDaiDividends() public returns (uint _amount);
}

contract ETT is iERC20Token, iDividendToken, SafeMath {

  event Transfer(address indexed from, address indexed to, uint amount);
  event Approval(address indexed from, address indexed to, uint amount);

  struct tokenHolder {
    uint tokens;            
    uint currentEthPoints;  
    uint lastEthSnapshot;   
    uint currentDaiPoints;  
    uint lastDaiSnapshot;   
  }

  bool    public isLocked;
  uint8   public decimals;
  address public daiToken;
  string  public symbol;
  string  public name;
  uint public    totalSupply;                                        
  uint public    holdoverEthBalance;                                 
  uint public    totalEthReceived;
  uint public    holdoverDaiBalance;                                 
  uint public    totalDaiReceived;

  mapping (address => mapping (address => uint)) private approvals;  
  mapping (address => tokenHolder) public tokenHolders;


   
   
   
  constructor(address _daiToken, uint256 _tokenSupply, uint8 _decimals, string memory _name, string memory _symbol) public {
    daiToken = _daiToken;
    totalSupply = _tokenSupply;
    decimals = _decimals;
    name = _name;
    symbol = _symbol;
    tokenHolders[msg.sender].tokens = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }


   
   
   


   
   
   
   
   
   
  function transfer(address _to, uint _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }


   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, safeSub(approvals[_from][msg.sender], _value));
    return true;
  }


   
   
   
   
  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != address(0));
     
    calcCurPointsForAcct(_from);
    tokenHolders[_from].tokens = safeSub(tokenHolders[_from].tokens, _value);
     
    if (tokenHolders[_to].lastEthSnapshot == 0)
      tokenHolders[_to].lastEthSnapshot = totalEthReceived;
    if (tokenHolders[_to].lastDaiSnapshot == 0)
      tokenHolders[_to].lastDaiSnapshot = totalDaiReceived;
     
    calcCurPointsForAcct(_to);
    tokenHolders[_to].tokens = safeAdd(tokenHolders[_to].tokens, _value);
    emit Transfer(_from, _to, _value);
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    balance = tokenHolders[_owner].tokens;
  }


   
   
   
   
   
   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }


   
   
   
   
   
   
   
   
   
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(msg.sender, _spender, safeAdd(approvals[msg.sender][_spender], _addedValue));
    return true;
  }

   
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    _approve(msg.sender, _spender, safeSub(approvals[msg.sender][_spender], _subtractedValue));
    return true;
  }


   
  function _approve(address _owner, address _spender, uint _value) internal {
    require(_owner != address(0));
    require(_spender != address(0));
    approvals[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }


  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return approvals[_owner][_spender];
  }

   
   
   

   
   
   
   
   
   
  function calcCurPointsForAcct(address _acct) internal {
    uint256 _newEthPoints = safeMul(safeSub(totalEthReceived, tokenHolders[_acct].lastEthSnapshot), tokenHolders[_acct].tokens);
    tokenHolders[_acct].currentEthPoints = safeAdd(tokenHolders[_acct].currentEthPoints, _newEthPoints);
    tokenHolders[_acct].lastEthSnapshot = totalEthReceived;
    uint256 _newDaiPoints = safeMul(safeSub(totalDaiReceived, tokenHolders[_acct].lastDaiSnapshot), tokenHolders[_acct].tokens);
    tokenHolders[_acct].currentDaiPoints = safeAdd(tokenHolders[_acct].currentDaiPoints, _newDaiPoints);
    tokenHolders[_acct].lastDaiSnapshot = totalDaiReceived;
  }


   
   
   
  function () external payable {
    holdoverEthBalance = safeAdd(holdoverEthBalance, msg.value);
    totalEthReceived = safeAdd(totalEthReceived, msg.value);
  }


   
   
   
   
  function payDai(uint256 _daiAmount) external {
    require(iERC20Token(daiToken).transferFrom(msg.sender, address(this), _daiAmount), "failed to transfer dai");
    holdoverDaiBalance = safeAdd(holdoverDaiBalance, _daiAmount);
    totalDaiReceived = safeAdd(totalDaiReceived, _daiAmount);
  }


   
   
   
   
   
  function updateDaiBalance() public {
    uint256 _actBalance = iERC20Token(daiToken).balanceOf(address(this));
    uint256 _daiAmount = safeSub(_actBalance, holdoverDaiBalance);
    holdoverDaiBalance = safeAdd(holdoverDaiBalance, _daiAmount);
    totalDaiReceived = safeAdd(totalDaiReceived, _daiAmount);
  }


   
   
   
  function checkDividends(address _addr) view public returns(uint _ethAmount, uint _daiAmount) {
     
    uint _currentEthPoints = tokenHolders[_addr].currentEthPoints +
      ((totalEthReceived - tokenHolders[_addr].lastEthSnapshot) * tokenHolders[_addr].tokens);
    _ethAmount = _currentEthPoints / totalSupply;
    uint _currentDaiPoints = tokenHolders[_addr].currentDaiPoints +
      ((totalDaiReceived - tokenHolders[_addr].lastDaiSnapshot) * tokenHolders[_addr].tokens);
    _daiAmount = _currentDaiPoints / totalSupply;
  }


   
   
   
  function withdrawEthDividends() public returns (uint _amount) {
    calcCurPointsForAcct(msg.sender);
    _amount = tokenHolders[msg.sender].currentEthPoints / totalSupply;
    uint _pointsUsed = safeMul(_amount, totalSupply);
    tokenHolders[msg.sender].currentEthPoints = safeSub(tokenHolders[msg.sender].currentEthPoints, _pointsUsed);
    holdoverEthBalance = safeSub(holdoverEthBalance, _amount);
    msg.sender.transfer(_amount);
  }

  function withdrawDaiDividends() public returns (uint _amount) {
    calcCurPointsForAcct(msg.sender);
    _amount = tokenHolders[msg.sender].currentDaiPoints / totalSupply;
    uint _pointsUsed = safeMul(_amount, totalSupply);
    tokenHolders[msg.sender].currentDaiPoints = safeSub(tokenHolders[msg.sender].currentDaiPoints, _pointsUsed);
    holdoverDaiBalance = safeSub(holdoverDaiBalance, _amount);
    require(iERC20Token(daiToken).transfer(msg.sender, _amount), "failed to transfer dai");
  }


}
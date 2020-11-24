 

pragma solidity >=0.4.22 <0.6.0;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a / b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }
}

contract ERC20Interface {
  uint256 public destorySupply;  
  uint256 public totalSupply;  
  function balanceOf(address _addr) public view returns (uint256);  
  function transfer(address _to, uint256 _value) public returns (bool);  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);  
  function approval(address _delegatee, uint256 _value) public returns (bool);  
  function allowance(address _owner, address _spender) public view returns (uint256);  
  function destory(uint256 _value) public returns (bool);  
  function destoryFrom(address _from, uint256 _value) public returns (bool);  

  event Transfer(address indexed _from, address indexed _to, uint256 _value);  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);  
  event Destory(address indexed _owner, uint256 _value);  

}

contract CIToken is ERC20Interface, SafeMath {
  address public owner; 

  mapping (address => uint256) public balances; 
  mapping (address => mapping (address => uint256)) public approvalBalance;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }


  function changeOwner(address _newOwner) external onlyOwner {
    require(_newOwner != address(0x0),"address cannot be empty.");
    require(_newOwner != owner,"address unchanged.");
    owner = _newOwner;
  }


   
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(balances[_from] >= _value,"insufficient number of tokens."); 
    require(_to != address(0x0),"address cannot be empty.");  
    require(balances[_to] + _value > balances[_to],"_value too large"); 

    uint256 previousBalance = safeAdd(balances[_from], balances[_to]);  
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(_from, _to, _value);

     
    assert (safeAdd(balances[_from], balances[_to]) == previousBalance);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(approvalBalance[_from][msg.sender] >= _value,"insufficient number of authorized tokens."); 
    approvalBalance[_from][msg.sender] = safeSub(approvalBalance[_from][msg.sender], _value);
    _transfer(_from, _to, _value);
    return true;
  }

   
  function approval(address _delegatee, uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value,"insufficient number of tokens.");
    require(_delegatee != address(0x0),"address cannot be empty.");
    approvalBalance[msg.sender][_delegatee] = _value;
    emit Approval(msg.sender, _delegatee, _value);
    return true;
  }

   
  function destory(uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value,"insufficient number of tokens.");
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    totalSupply = safeSub(totalSupply, _value);
    destorySupply = safeAdd(destorySupply, _value);
    emit Destory(msg.sender, _value);
    return true;
  }

   
  function destoryFrom(address _from, uint256 _value) public returns (bool) {
    require(approvalBalance[_from][msg.sender] >= _value,"insufficient number of authorized tokens.");
    require(balances[_from] >= _value,"insufficient number of tokens.");
    balances[_from] = safeSub(balances[_from], _value);
    approvalBalance[_from][msg.sender] = safeSub(approvalBalance[_from][msg.sender], _value);
    totalSupply = safeSub(totalSupply, _value);
    destorySupply = safeAdd(destorySupply, _value);
    emit Destory(msg.sender, _value);
    return true;
  }

   
  function balanceOf(address _addr) public view returns (uint256) {
    return balances[_addr];
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return approvalBalance[_owner][_spender];
  }
}

contract CI is CIToken {
   
  function () external { revert(); }

  string public constant name = "CI"; 
  string public constant symbol = "CI";
  uint8 public constant decimals = 18;

  constructor() public {
    owner = msg.sender;
    destorySupply = 0;
    totalSupply = formatDecimals(100000000);
    balances[owner] = totalSupply;
  }

   
  function formatDecimals(uint256 _value) internal pure returns (uint256){
    return _value * 10 ** uint256(decimals);
  }
}
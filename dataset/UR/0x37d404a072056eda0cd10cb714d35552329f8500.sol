 

pragma solidity ^0.4.24;
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256 _user);
  function transfer(address to, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public view returns (uint256 value);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
}

contract OnlyOwner {
  address public owner;
  address private controller;
  event Controller(address _user);
   
  constructor() public {
    owner = msg.sender;
    controller = owner;
  }


   
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
  
   
  modifier isController {
    require(msg.sender == controller);
    _;
  }
  
  function replaceController(address _user) isController public returns(bool){
    require(_user != address(0x0));
    controller = _user;
    emit Controller(controller);
    return true;   
  }

}

contract StandardToken is ERC20{
  using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Minted(address receiver, uint256 amount);
    
    
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool success){
       
      require(_from != address(0) && _from != _to);
      require(_to != address(0));
       
      balances[_from] = balances[_from].safeSub(_value);
       
      balances[_to] = balances[_to].safeAdd(_value);
      return true;
    }

  function transfer(address _to, uint256 _value) public returns (bool success) 
  { 
    require(_value <= balances[msg.sender]);
      _transfer(msg.sender,_to,_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      uint256 _allowance = allowed[_from][msg.sender];
       
      require(_value <= _allowance);
       
      require(balances[_to] + _value > balances[_to]);
       
      _transfer(_from,_to,_value);
       
      allowed[_from][msg.sender] = _allowance.safeSub(_value);
       
      emit Transfer(_from, _to, _value);
      return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
      return balances[_owner];
    }

    

   

  function approve(address _spender, uint256 _value) public returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }



}

contract XRT is StandardToken, OnlyOwner{
  uint8 public constant decimals = 18;
    uint256 private constant multiplier = 10**27;
    string public constant name = "XRT Token";
    string public constant symbol = "XRT";
    string public version = "X1.1";
    uint256 private maxSupply = multiplier;
    uint256 public totalSupply = (50*maxSupply)/100;
    uint256 private approvalCount =0;
    uint256 public minApproval =2;
    address public fundReceiver;
    
    constructor(address _takeBackAcc) public{
        balances[msg.sender] = totalSupply;
        fundReceiver = _takeBackAcc;
    }
    
    function maximumToken() public view returns (uint){
        return maxSupply;
    }
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    require(totalSupply <= maxSupply);
    _;
  }

   
  function mint(address _to, uint256 _amount) isOwner canMint public returns (bool) {
      uint256 newAmount = _amount.safeMul(multiplier.safeDiv(100));
      require(totalSupply <= maxSupply.safeSub(newAmount));
      totalSupply = totalSupply.safeAdd(newAmount);
    balances[_to] = balances[_to].safeAdd(newAmount);
    emit Mint(_to, newAmount);
    emit Transfer(address(0), _to, newAmount);
    return true;
  }

   
    function finishMinting() isOwner canMint public returns (bool) {
      mintingFinished = true;
      emit MintFinished();
      return true;
    }
    
    function setApprovalCount(uint _value) public isController {
        approvalCount = _value;
    }
    
    function setMinApprovalCount(uint _value) public isController returns (bool){
        require(_value > 0);
        minApproval = _value;
        return true;
    }
    
    function getApprovalCount() public view isController returns(uint){
        return approvalCount;
    }
    
    function getFundReceiver() public view isController returns(address){
        return fundReceiver;
    }
    
    function controllerApproval(address _from, uint256 _value) public isOwner returns (bool) {
        require(minApproval <= approvalCount); 
        balances[_from] = balances[_from].safeSub(_value);
       
      balances[fundReceiver] = balances[fundReceiver].safeAdd(_value);
        emit Transfer(_from,fundReceiver, _value);
        return true;
    }
}
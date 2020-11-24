 

pragma solidity 0.4.25;
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
   
  event SetNewController(address prev_controller, address new_controller);
   
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
  
  function replaceController(address new_controller) isController public returns(bool){
    require(new_controller != address(0x0));
	controller = new_controller;
    emit SetNewController(msg.sender,controller);
    return true;   
  }

}

contract StandardToken is ERC20{
  using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

  
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

contract CCN is StandardToken, OnlyOwner{
	uint256 public constant decimals = 18;
    string public constant name = "CustomContractNetwork";
    string public constant symbol = "CCN";
    string public constant version = "1.0";
    uint256 public constant totalSupply = 890000000000*10**18;
    uint256 private approvalCounts =0;
    uint256 private minRequiredApprovals =2;
    address public burnedTokensReceiver;
    
    constructor() public{
        balances[msg.sender] = totalSupply;
        burnedTokensReceiver = 0x0000000000000000000000000000000000000000;
    }

     
    function setApprovalCounts(uint _value) public isController {
        approvalCounts = _value;
    }
    
     
    function setMinApprovalCounts(uint _value) public isController returns (bool){
        require(_value > 0);
        minRequiredApprovals = _value;
        return true;
    }
    
     
    function getApprovalCount() public view isController returns(uint){
        return approvalCounts;
    }
    
      
    function getBurnedTokensReceiver() public view isController returns(address){
        return burnedTokensReceiver;
    }
    
    
    function controllerApproval(address _from, uint256 _value) public isOwner returns (bool) {
        require(minRequiredApprovals <= approvalCounts);
		require(_value <= balances[_from]);		
        balances[_from] = balances[_from].safeSub(_value);
        balances[burnedTokensReceiver] = balances[burnedTokensReceiver].safeAdd(_value);
        emit Transfer(_from,burnedTokensReceiver, _value);
        return true;
    }
}
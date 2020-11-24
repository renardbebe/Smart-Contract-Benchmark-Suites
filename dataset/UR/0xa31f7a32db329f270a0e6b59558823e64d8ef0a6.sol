 

pragma solidity ^0.5.12;

 
 
 
 
 
 
 
 
 
 


 
 
 
 

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath { 
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

contract Q8E20_Token is ERC20 {

    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;  
    address internal _admin;
    uint256 public _totalSupply;
    uint256 internal stakingLimit;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() public {  
        symbol = "Q8E20";  
        name = "Q8E20 Token"; 
        decimals = 8;
        _totalSupply = 100000000 * 10**uint256(decimals);
        _admin = msg.sender;
        initial();
    }  
    
    function initial() internal{
        balances[_admin] = 16180339 * 10**uint256(decimals);
        emit ERC20.Transfer(address(0), msg.sender, balances[_admin]);
        balances[address(this)] = 83819661 * 10**uint256(decimals);
        stakingLimit  = 25000 * 10**uint256(decimals);
    }

    function totalSupply() public view returns (uint256) {
	    return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function setStakingLimit(uint256 _amount) public returns (bool) {
        require(msg.sender == _admin);
        require(_amount > 0);
        stakingLimit = _amount * 10**uint(decimals);
        return true;
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(receiver != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit ERC20.Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit ERC20.Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit ERC20.Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function fromContract(address receiver, uint256 _amount) public returns (bool) {
        require( _admin == msg.sender );
        require(receiver != address(0));
        require( _amount > 0 );
        
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[receiver] = balances[receiver].add(_amount);
        emit ERC20.Transfer(address(this), receiver, _amount);
        return true;
    }
    
    function mint(address _receiver, uint256 _amount) public returns (bool) {
        require( _admin == msg.sender );
        require( _amount > 0 );
        require(balances[_receiver] >= stakingLimit);

        _totalSupply = _totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        return true;
    }
}
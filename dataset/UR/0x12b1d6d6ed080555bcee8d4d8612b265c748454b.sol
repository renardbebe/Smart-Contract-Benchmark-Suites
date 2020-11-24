 

pragma solidity ^0.5.12;

 
 
 
 
 
 
 
 
 
 
 


 
 
 
 

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
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

contract Allbandex_Token is ERC20 {

    string public  name;
    string public  symbol;
    uint8 public  decimals;  
    address internal _admin;
    uint256 totalSupply_;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;


   constructor() public {  
        symbol = "ABDX";  
        name = "Allbandex"; 
        decimals = 8;
        totalSupply_ = 300000000* 10**uint(decimals);
        _admin = msg.sender;
        balances[_admin] = totalSupply_;
        emit ERC20.Transfer(address(0), msg.sender, totalSupply_);
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit ERC20.Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit ERC20.Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit ERC20.Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function mint(uint256 _amount) public returns (bool) {
        require(_admin == msg.sender);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_admin] = balances[_admin].add(_amount);
        emit ERC20.Transfer(address(0),msg.sender,_amount);
        return true;
    }
}
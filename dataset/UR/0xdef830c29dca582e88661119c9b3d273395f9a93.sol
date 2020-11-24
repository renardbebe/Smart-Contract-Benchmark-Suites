 

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

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

contract Ownable {
  address public owner;


   
  constructor () public{
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(owner==msg.sender);
    _;
 }

   
  function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
  }
 
}
  
contract ERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BTNYToken is Ownable, ERC20 {

    using SafeMath for uint256;

     
    string public name = "Bitney";                 
    string public symbol = "BTNY";                   
    uint256 public decimals = 18;

    uint256 public _totalSupply = 1000000000e18;        

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;

     
    uint256 public price;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
     
     
    constructor () public{
         
        owner = msg.sender;

        balances[owner] = _totalSupply;
    }

     
     
    function () external payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        price = getPrice();
        require(price != 0 && recipient != 0x0);
        uint256 weiAmount = msg.value;
        uint256 tokenToSend = weiAmount.mul(price);
        
        balances[owner] = balances[owner].sub(tokenToSend);
        balances[recipient] = balances[recipient].add(tokenToSend);

        owner.transfer(msg.value);
        emit TokenPurchase(msg.sender, recipient, weiAmount, tokenToSend);
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

     
     
     
     
    function transfer(address to, uint256 value) public returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public returns (bool success)  {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public returns (bool success)  {
        require (balances[msg.sender] >= value && value > 0);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }
    
     
     
    function getPrice() public pure returns (uint256 result) {
        return 0;
    }
}
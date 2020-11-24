 

pragma solidity ^0.4.18;

 library SafeMath {
      function add(uint a, uint b) internal pure returns (uint c) {
          c = a + b;
          require(c >= a);
      }
      function sub(uint a, uint b) internal pure returns (uint c) {
          require(b <= a);
          c = a - b;
      }
      function mul(uint a, uint b) internal pure returns (uint c) {
          c = a * b;
          require(a == 0 || c / a == b);
      }
      function div(uint a, uint b) internal pure returns (uint c) {
          require(b > 0);
          c = a / b;
      }
  }
  
 contract ERXInterface {
      function totalSupply() public constant returns (uint);
      function balanceOf(address tokenOwner) public constant returns (uint balance);
      function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
      function transfer(address to, uint tokens) public returns (bool success);
      function approve(address spender, uint tokens) public returns (bool success);
      function transferFrom(address from, address to, uint tokens) public returns (bool success);
      event Transfer(address indexed from, address indexed to, uint tokens);
      event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  }
  
 contract ApproveAndCallFallBack {
      function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
  }
  
 contract Owned {
      address public owner;
      address public newOwner;
  
      event OwnershipTransferred(address indexed _from, address indexed _to);
  
      function Owned() public {
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
          OwnershipTransferred(owner, newOwner);
          owner = newOwner;
          newOwner = address(0);
      }
  }
  
 contract ERC20Connect is ERXInterface, Owned {
     using SafeMath for uint;
 
     string public symbol;
     string public  name;
     uint8 public decimals;
     uint public _totalSupply;
     uint256 public unitsOneEthCanBuy;     
     uint256 public totalEthInWei;           
     address public fundsWallet;          
     mapping(address => uint) balances;
     mapping(address => mapping(address => uint)) allowed;
 
     function ERC20Connect() public {
         symbol = "ERX";
         name = "ERC20Connect";
         decimals = 18;
         _totalSupply = 21000000 * 10**uint(decimals);
         balances[owner] = _totalSupply;
         Transfer(address(0), owner, _totalSupply);
         unitsOneEthCanBuy = 5000;                                     
         fundsWallet = msg.sender;                                   
     }
 
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - balances[address(0)];
     }
 
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return balances[tokenOwner];
     }
 
     function transfer(address to, uint tokens) public returns (bool success) {
         balances[msg.sender] = balances[msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         Transfer(msg.sender, to, tokens);
         return true;
     }
 
     function approve(address spender, uint tokens) public returns (bool success) {
         allowed[msg.sender][spender] = tokens;
         Approval(msg.sender, spender, tokens);
         return true;
     }
 
     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         balances[from] = balances[from].sub(tokens);
         allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         Transfer(from, to, tokens);
         return true;
     }
 
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
 
     function() payable public{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);

        fundsWallet.transfer(msg.value);                               
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
 
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERXInterface(tokenAddress).transfer(owner, tokens);
     }
 }
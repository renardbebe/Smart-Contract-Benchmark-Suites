 

pragma solidity ^0.4.18;

 
 
 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
  }

  function safeDiv(uint256 a, uint256 b) internal constant returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
  }

  function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
      assert(b <= a);
      return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
  }

}

 
 
 
 
contract ERC20Interface {
    function totalSupply() constant returns (uint);
    function balanceOf(address tokenOwner) constant returns (uint balance);
    function allowance(address tokenOwner, address spender) constant returns (uint remaining);
    function transfer(address to, uint tokens) returns (bool success);
    function approve(address spender, uint tokens) returns (bool success);
    function transferFrom(address from, address to, uint tokens) returns (bool success);

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


 
 
 
 
contract CrowdSale is ERC20Interface, Owned, SafeMath {
     
    address public tokenAddress;
     
    bytes8 public symbol;
     
    bytes16 public  name;
     
    uint256 public decimals;
     
    uint256 public _totalSupply;

     
    mapping(address => uint) tokenBalances;

    mapping(address => mapping(address => uint)) internal allowed;

         
    modifier nonZero() {
        require(msg.value != 0);
        _;
    }
     
     
     
    function CrowdSale(
            address _tokenAddress
            ) public {
                 
                symbol = "RPZX";
                name = "Rapidz";
                decimals = 18;
                _totalSupply = 5000000000000000000000000000;
                 
                tokenAddress=_tokenAddress;
                tokenBalances[tokenAddress] = _totalSupply; 
                Transfer(address(0), tokenAddress,_totalSupply); 
    }

     
     
     
    function totalSupply() constant returns (uint) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) constant returns (uint balance) {
        return tokenBalances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) returns (bool success) {

        tokenBalances[msg.sender] = safeSub(tokenBalances[msg.sender], tokens);
        tokenBalances[to] = safeAdd(tokenBalances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) returns (bool success) {
        tokenBalances[from] = safeSub(tokenBalances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        tokenBalances[to] = safeAdd(tokenBalances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


       
    function () nonZero payable {
        revert();
    } 


}
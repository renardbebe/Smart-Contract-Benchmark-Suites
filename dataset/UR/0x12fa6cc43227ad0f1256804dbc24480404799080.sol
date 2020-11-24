 

 
 
 
 
pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract ERC20Interface {
 
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(uint tokens);

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
}

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

 
 
 
 
contract OdinToken is ERC20Interface, Owned {

  using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
 
    bool private _whitelistAll;

    struct balanceData {  
       bool locked;
       uint balance;
       uint airDropQty;
    }

    mapping(address => balanceData) balances;
    mapping(address => mapping(address => uint)) allowed;


   
    function OdinToken() public {
        
         
        owner = msg.sender;
        symbol = "ODIN";
        name = "ODIN Token";
        decimals = 18;
        _whitelistAll=false;
        totalSupply = 100000000000000000000000;
        balances[owner].balance = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

     
     
     
    uint256 public totalSupply;


     
     
     
    function whitelistAddress(address tokenOwner) onlyOwner public returns (bool)    {
		balances[tokenOwner].airDropQty = 0;
		return true;
    }


     
    function whitelistAllAddresses() onlyOwner public returns (bool) {
        _whitelistAll = true;
        return true;
    }


     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner].balance;
    }

    function airdrop(address[] recipients, uint[] values) onlyOwner public {

    require(recipients.length <= 255);
    require (msg.sender==owner);
    require(recipients.length == values.length);
    for (uint i = 0; i < recipients.length; i++) {
        if (balances[recipients[i]].balance==0) {
          OdinToken.transfer(recipients[i], values[i]);
    }
    }
  }
  
    function canSpend(address tokenOwner, uint _value) public constant returns (bool success) {

        if (_value > balances[tokenOwner].balance) {return false;}      
        if (tokenOwner==address(0)) {return false;}                                

        if (tokenOwner==owner) {return true;}                                        
        if (_whitelistAll) {return true;}                                    
        if (balances[tokenOwner].airDropQty==0) {return true;}                       
        if (block.timestamp>1569974400) {return true;}                       

         
         if (block.timestamp < 1535760000) {return false;}

         
        if (block.timestamp < 1546214400 && (balances[tokenOwner].balance - _value) < (balances[tokenOwner].airDropQty / 10 * 9)) {
            return false;
        }

         
        if (block.timestamp < 1553990400 && (balances[tokenOwner].balance - _value) < balances[tokenOwner].airDropQty / 4 * 3) {
            return false;
        }

         
        if (block.timestamp < 1561852800 && (balances[tokenOwner].balance - _value) < balances[tokenOwner].airDropQty / 2) {
            return false;
        }

         
        if (block.timestamp < 1569974400 && (balances[tokenOwner].balance - _value) < balances[tokenOwner].airDropQty / 4) {
            return false;
        }
        
        return true;

    }

    function transfer(address to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {

        require (canSpend(msg.sender, _value));
        balances[msg.sender].balance = balances[msg.sender].balance.sub( _value);
        balances[to].balance = balances[to].balance.add( _value);
        if (msg.sender == owner) {
            balances[to].airDropQty = balances[to].airDropQty.add( _value);
        }
        emit Transfer(msg.sender, to,  _value);
        return true;
    }

    function approve(address spender, uint  _value) public returns (bool success) {

        require (canSpend(msg.sender, _value));

         
         

        allowed[msg.sender][spender] =  _value;
        emit Approval(msg.sender, spender,  _value);
        return true;
    }

    function transferFrom(address from, address to, uint  _value) onlyPayloadSize(3 * 32) public returns (bool success) {

        if (balances[from].balance >=  _value && allowed[from][msg.sender] >=  _value &&  _value > 0) {

            allowed[from][msg.sender].sub( _value);
            balances[from].balance = balances[from].balance.sub( _value);
            balances[to].balance = balances[to].balance.add( _value);
            emit Transfer(from, to,  _value);
          return true;
        } else {
          require(false);
        }
      }
    

     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    
     
     
     
    function burn(uint  _value) onlyOwner public returns (bool) {
        require((balances[owner].balance -  _value) >= 0);
        balances[owner].balance = balances[owner].balance.sub( _value);
        totalSupply = totalSupply.sub( _value);
        emit Burn( _value);
        return true;
    }

}
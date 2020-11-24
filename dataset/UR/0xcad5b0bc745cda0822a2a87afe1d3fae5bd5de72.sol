 

pragma solidity  ^0.4.21;

 
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

     
     
    uint public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint balance);

     
    function transfer(address _to, uint _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
    function approve(address _spender, uint _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint _value);
     
    event Mint(address _owner, uint _value);
     
    event MintFinished();
     
    event Burn(address indexed _from, uint _value);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        require(_value <= balances[msg.sender]);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transferFrom(_from, _to, _value);
        return true;
    }

    function _transferFrom(address _from, address _to, uint _value) internal {
        require(_to != address(0));  
        require(_value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
    }
}

contract TokenReceiver {
  function tokenFallback(address _sender, address _origin, uint _value) public returns (bool ok);
}

contract Burnable is ERC20Interface {

   
  function burnTokens(uint _value) public returns (bool success);

   
  function burnFrom(address _from, uint _value) public returns (bool success);

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract LEN is ERC20Token, Ownable {

    using SafeMath for uint;

    string public name = "LIQNET";          
    string public symbol = "LEN";                    
    uint8 public decimals = 8;                       
    bool public mintingFinished;          

    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);

     
    function mintTokens(address target, uint mintedAmount) public onlyOwner returns (bool success) {
        require(!mintingFinished);  
        totalSupply = totalSupply.add(mintedAmount);
        balances[target] = balances[target].add(mintedAmount);
        Mint(target, mintedAmount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool success) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

       
    function transfer(address _to, uint _value) public returns (bool success) {
        if (isContract(_to)) {
            return _transferToContract(msg.sender, _to, _value);
        } else {
            _transferFrom(msg.sender, _to, _value);
            return true;
        }
    }

     
    function burnTokens(uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(_from, _value);
    }

     
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
              
             length := extcodesize(_addr)
        }
        return (length > 0);
     }

    
    function _transferToContract(address _from, address _to, uint _value) private returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        TokenReceiver receiver = TokenReceiver(_to);
        receiver.tokenFallback(msg.sender, this, _value);
        return true;
    }
}
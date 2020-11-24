 

pragma solidity ^0.4.21;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract admined is owned {
    address public admin;

    function admined() public {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    function transferAdmin(address newAdmin) onlyOwner public {
        admin = newAdmin;
    }
}

 
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint256 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        uint256 decimalsToken,
        string tokenSymbol
    ) public {
        decimals = decimalsToken;
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        emit Transfer(0, msg.sender, totalSupply);
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        _burn(msg.sender, _value);
        return true;
    }
    
    function _burn(address _who, uint256 _value) internal {
        balanceOf[_who] = balanceOf[_who].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        _burn(_from, _value);
        return true;
    }

    function getBalance(address _to) view public returns(uint res) {
        return balanceOf[_to];
    }

}

contract CPROPToken is admined, TokenERC20  {
    function CPROPToken(
        uint256 initialSupply,
        string tokenName,
        uint256 decimalsToken,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, decimalsToken, tokenSymbol) public {
    }
}
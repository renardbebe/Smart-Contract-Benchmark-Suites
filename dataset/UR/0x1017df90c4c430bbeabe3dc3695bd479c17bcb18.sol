 

pragma solidity ^0.4.18;
 
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

 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public{
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    bool public stopped = false;

     
    modifier isRunning {
        require(!stopped);
        _;
    }
    function stop() public isRunning onlyOwner {
        stopped = true;
    }

    function start() public isRunning onlyOwner {
        stopped = false;
    }

     
    function transfer(address _to, uint256 _value) isRunning public returns (bool) {
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function batchTransfer(address[] _addresses, uint256[] _value) isRunning public returns (bool) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(transfer(_addresses[i], _value[i]));
        }
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) isRunning public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) isRunning public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) isRunning public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract DeepCoinToken is StandardToken {
    uint256 public totalSupply = 100000000 * 60 * 10 ** 18;   
    string  public name = "Deepfin Coin";
    uint8   public decimals = 18;
    string  public symbol = 'DFC';
    string  public version = 'v1.0';
    function DeepCoinToken() public{
        balances[msg.sender] = totalSupply;
    }
	 
    function burn(uint256 _value) onlyOwner isRunning public {
        require(balances[0x0].add(_value) <= 100000000 * 50 * 10 ** 18);
        transfer(0x0, _value);
    }
    function burnBalance() onlyOwner public view returns (uint256) {
        uint256 burnCap = 100000000 * 50 * 10 ** 18;
        return burnCap.sub(balances[0x0]);
    }
}
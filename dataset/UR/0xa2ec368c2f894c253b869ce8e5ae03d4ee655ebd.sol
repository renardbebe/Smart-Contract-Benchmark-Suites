 

pragma solidity ^0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
  address public owner;


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC223 {
    uint256 public totalSupply_;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function totalSupply() public view returns (uint256 _supply);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint value) public returns (bool success);
    function transfer(address to, uint value, bytes data) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}


contract ContractReceiver {
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract ERC223Token is ERC223 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public totalSupply_;

     
    function totalSupply() public view returns (uint256 _supply) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
         
        assembly {
             
            length := extcodesize(_addr)
        }
        if (length > 0) {
            return true;
        } else {
            return false;
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver reciever = ContractReceiver(_to);
        reciever.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    function addTokenToTotalSupply(uint _value) public {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender] + _value;
        totalSupply_ = totalSupply_ + _value;
        
    }
}

 
contract LIRAX is ERC223Token, Ownable {

    string public constant name = "LIRAX";
    string public constant symbol = "LRX";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));
    address public feeHoldingAddress;

    address public owner;

     
    function LIRAX() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        owner = msg.sender;
        feeHoldingAddress = owner;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

     
    function adminTransfer(address _from, address _to, uint256 _value, uint256 _fee) public payable onlyOwner returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value > _fee);

        balances[feeHoldingAddress] = balances[feeHoldingAddress].add(_fee);

        uint256 actualValue = _value.sub(_fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(actualValue);
        Transfer(_from, _to, actualValue);
        Transfer(_from, feeHoldingAddress, _fee);
        return true;
    }

    function changeFeeHoldingAddress(address newFeeHoldingAddress) public onlyOwner {
        feeHoldingAddress = newFeeHoldingAddress;
    }
}
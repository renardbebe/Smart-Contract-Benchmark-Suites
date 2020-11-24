 

pragma solidity ^0.4.21;

contract ReceivingContract {
    function onTokenReceived(address _from, uint _value, bytes _data) public;
}

contract Gate {
    ERC20Basic private TOKEN;
    address private PROXY;

     
    function Gate(ERC20Basic _token, address _proxy) public {
        TOKEN = _token;
        PROXY = _proxy;
    }

     
     
     
    function transferToProxy(uint256 _value) public {
        require(msg.sender == PROXY);

        require(TOKEN.transfer(PROXY, _value));
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(allowed[msg.sender][_spender] == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract TokenProxy is StandardToken, BurnableToken {

    ERC20Basic public TOKEN;

    mapping(address => address) private gates;


    event GateOpened(address indexed gate, address indexed user);

    event Mint(address indexed to, uint256 amount);

    function TokenProxy(ERC20Basic _token) public {
        TOKEN = _token;
    }

    function getGateAddress(address _user) external view returns (address) {
        return gates[_user];
    }

     
    function openGate() external {
        address user = msg.sender;

         
        require(gates[user] == 0);

         
        address gate = new Gate(TOKEN, this);

         
        gates[user] = gate;

        emit GateOpened(gate, user);
    }

    function transferFromGate() external {
        address user = msg.sender;

        address gate = gates[user];

         
        require(gate != 0);

        uint256 value = TOKEN.balanceOf(gate);

        Gate(gate).transferToProxy(value);

         
         
        totalSupply_ += value;
        balances[user] += value;

        emit Mint(user, value);
    }

    function withdraw(uint256 _value) external {
        withdrawTo(_value, msg.sender);
    }

    function withdrawTo(uint256 _value, address _destination) public {
        require(_value > 0 && _destination != address(0));
        burn(_value);
        TOKEN.transfer(_destination, _value);
    }
}

contract GolemNetworkTokenBatching is TokenProxy {

    string public constant name = "Golem Network Token Batching";
    string public constant symbol = "GNTB";
    uint8 public constant decimals = 18;


    event BatchTransfer(address indexed from, address indexed to, uint256 value,
        uint64 closureTime);

    function GolemNetworkTokenBatching(ERC20Basic _gntToken) TokenProxy(_gntToken) public {
    }

    function batchTransfer(bytes32[] payments, uint64 closureTime) external {
        require(block.timestamp >= closureTime);

        uint balance = balances[msg.sender];

        for (uint i = 0; i < payments.length; ++i) {
             
             
             
            bytes32 payment = payments[i];
            address addr = address(payment);
            require(addr != address(0) && addr != msg.sender);
            uint v = uint(payment) / 2**160;
            require(v <= balance);
            balances[addr] += v;
            balance -= v;
            emit BatchTransfer(msg.sender, addr, v, closureTime);
        }

        balances[msg.sender] = balance;
    }

    function transferAndCall(address to, uint256 value, bytes data) external {
       
      transfer(to, value);

       
       
      ReceivingContract(to).onTokenReceived(msg.sender, value, data);
    }
}
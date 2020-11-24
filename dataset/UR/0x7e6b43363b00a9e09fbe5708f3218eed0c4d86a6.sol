 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC223Interface {
    function transfer(address _to, uint _value) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    event ERC223Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

contract HumanStandardToken is ERC223Interface, StandardToken {
    using SafeMath for uint256;

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
       
       
      uint codeLength;

      assembly {
         
        codeLength := extcodesize(_to)
      }

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      if(codeLength>0) {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
      }
      Transfer(msg.sender, _to, _value);
      ERC223Transfer(msg.sender, _to, _value, _data);
      return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value);
        ERC223Transfer(msg.sender, _to, _value, empty);
        return true;
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

contract LunetToken is HumanStandardToken {
    using SafeMath for uint256;

    string public name = "Lunet";
    string public symbol= "LUNET";
    uint8 public decimals = 18;

    uint256 public tokenCreationCap = 1000000000000000000000000000;  
    uint256 public lunetReserve = 50000000000000000000000000;  

    event CreateLUNETS(address indexed _to, uint256 _value, uint256 _timestamp);
    event Staked(address indexed _from, uint256 _value, uint256 _timestamp);
    event Withdraw(address indexed _from, uint256 _value, uint256 _timestamp);

    struct Stake {
      uint256 amount;
      uint256 timestamp;
    }

    mapping (address => Stake) public stakes;

    function LunetToken() public {
       totalSupply = lunetReserve;
       balances[msg.sender] = lunetReserve;
       CreateLUNETS(msg.sender, lunetReserve, now);
    }

    function stake() external payable {
      require(msg.value > 0);

       
      Stake storage stake = stakes[msg.sender];

      uint256 amount = stake.amount.add(msg.value);

       
      stake.amount = amount;
      stake.timestamp = now;

       
      Staked(msg.sender, amount, now);
    }

    function withdraw() public {
       
      Stake storage stake = stakes[msg.sender];

       
      require(stake.amount > 0);

       
      uint256 amount = stake.amount;

       
      stake.amount = 0;

       
      if (!msg.sender.send(amount)) revert();

       
      Withdraw(msg.sender, amount, now);
    }

    function claim() public {
       
      uint256 reward = getReward(msg.sender);

       
      if (reward > 0) {
         
        Stake storage stake = stakes[msg.sender];
        stake.timestamp = now;

        uint256 checkedSupply = totalSupply.add(reward);
        if (tokenCreationCap < checkedSupply) revert();

         
        totalSupply = checkedSupply;

         
        balances[msg.sender] += reward;

         
        CreateLUNETS(msg.sender, reward, now);
      }

    }

    function claimAndWithdraw() external {
      claim();
      withdraw();
    }

    function getReward(address staker) public constant returns (uint256) {
       
      Stake memory stake = stakes[staker];

       
      uint256 precision = 100000;

       
      uint256 difference = now.sub(stake.timestamp).mul(precision);

       
      uint totalDays = difference.div(1 days);

       
      uint256 reward = stake.amount.mul(totalDays).div(precision);

      return reward;
    }

    function getStake(address staker) external constant returns (uint256, uint256) {
      Stake memory stake = stakes[staker];
      return (stake.amount, stake.timestamp);
    }
}
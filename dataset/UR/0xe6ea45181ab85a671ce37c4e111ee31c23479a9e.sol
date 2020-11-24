 

pragma solidity ^0.4.18;
 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  
}
contract ERC20Interface {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address owner ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool success);
    function transferFrom( address from, address to, uint value) public returns (bool success);
    function approve( address spender, uint value ) public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract StandardAuth is ERC20Interface {
    address      public  owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract StandardStop is StandardAuth {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }

}

contract StandardToken is StandardStop {
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) optionPoolMembers;
    mapping(address => uint) optionPoolMemberApproveTotal;
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolLockTotal = 300000000;
    uint [2][7] public optionPoolMembersUnlockPlans = [
        [1596211200,15],     
        [1612108800,30],     
        [1627747200,45],     
        [1643644800,60],     
        [1659283200,75],     
        [1675180800,90],     
        [1690819200,100]     
    ];
    
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol) public  {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        symbol = _tokenSymbol;
        optionPoolMembers[0x11aCaBea71b42481672514071666cDA03b3fCfb8] = true;
        optionPoolMembers[0x41217b46F813b685dB48FFafBd699f47BF6b87Bd] = true;
        optionPoolMembers[0xaE6649B718A1bC54630C1707ddb8c0Ff7e635f5A] = true;
        optionPoolMembers[0x9E64828c4e3344001908AdF1Bd546517708a649f] = true;
    }

    modifier verifyTheLock(uint _value) {
        if(optionPoolMembers[msg.sender] == true) {
            if(balances[msg.sender] - optionPoolMemberApproveTotal[msg.sender] - _value < optionPoolMembersLockTotalOf(msg.sender)) {
                revert();
            } else {
                _;
            }
        } else {
            _;
        }
    }
    
     
    function name() public view returns (string _name) {
        return name;
    }
     
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
     
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() public view returns (uint _totalSupply) {
        return totalSupply;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    function verifyOptionPoolMembers(address _add) public view returns (bool _verifyResults) {
        return optionPoolMembers[_add];
    }
    
    function optionPoolMembersLockTotalOf(address _memAdd) public view returns (uint _optionPoolMembersLockTotal) {
        if(optionPoolMembers[_memAdd] != true){
            return 0;
        }
        
        uint unlockPercent = 0;
        
        for (uint8 i = 0; i < optionPoolMembersUnlockPlans.length; i++) {
            if(now >= optionPoolMembersUnlockPlans[i][0]) {
                unlockPercent = optionPoolMembersUnlockPlans[i][1];
            } else {
                break;
            }
        }
        
        return optionPoolLockTotal * (100 - unlockPercent) / 100;
    }
    
    function transfer(address _to, uint _value) public stoppable verifyTheLock(_value) returns (bool success) {
        assert(_value > 0);
        assert(balances[msg.sender] >= _value);
        assert(msg.sender != _to);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
        assert(balances[_from] >= _value);
        assert(allowed[_from][msg.sender] >= _value);

        if(optionPoolMembers[_from] == true) {
            optionPoolMemberApproveTotal[_from] = optionPoolMemberApproveTotal[_from].sub(_value);
        }
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
        
    }

    function approve(address _spender, uint256 _value) public stoppable verifyTheLock(_value) returns (bool success) {
        assert(_value > 0);
        assert(msg.sender != _spender);
        
        if(optionPoolMembers[msg.sender] == true) {
            
            if(allowed[msg.sender][_spender] > 0){
                optionPoolMemberApproveTotal[msg.sender] = optionPoolMemberApproveTotal[msg.sender].sub(allowed[msg.sender][_spender]);
            }
            
            optionPoolMemberApproveTotal[msg.sender] = optionPoolMemberApproveTotal[msg.sender].add(_value);
        }
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

}
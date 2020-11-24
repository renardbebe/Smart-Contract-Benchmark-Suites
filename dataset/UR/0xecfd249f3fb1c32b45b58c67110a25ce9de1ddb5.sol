 

pragma solidity ^0.4.13;

contract Multiowned {

     

     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

     

     
     
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
     
    event RequirementChanged(uint newRequirement);

     

     
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }

     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

     

     
     
    function Multiowned(address[] _owners, uint _required) public {
        m_numOwners = _owners.length;
        m_chiefOwnerIndexBit = 2**1;
        for (uint i = 0; i < m_numOwners; i++) {
            m_owners[1 + i] = _owners[i];
            m_ownerIndex[uint(_owners[i])] = 1 + i;
        }
        m_required = _required;
    }
    
     
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) {
            return;
        }
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }
    
     
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (isOwner(_to) || ownerIndex == 0) {
            return;
        }

        clearPending();
        m_owners[ownerIndex] = _to;
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }
    
    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_owner)) {
            return;
        }

        if (m_numOwners >= c_maxOwners) {
            clearPending();
            reorganizeOwners();
        }
        require(m_numOwners < c_maxOwners);
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }
    
    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0 || m_required > m_numOwners - 1) {
            return;
        }

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners();  
        OwnerRemoved(_owner);
    }
    
    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) external {
        if (_newRequired > m_numOwners) {
            return;
        }
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }
    
    function isOwner(address _addr) internal view returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }
    
    function hasConfirmed(bytes32 _operation, address _owner) public view returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

         
        if (ownerIndex == 0) {
            return false;
        }

         
        uint ownerIndexBit = 2**ownerIndex;
        if (pending.ownersDone & ownerIndexBit == 0) {
            return false;
        } else {
            return true;
        }
    }
    
     

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
         
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        require(ownerIndex != 0);

        var pending = m_pending[_operation];
         
        if (pending.yetNeeded == 0) {
             
            pending.yetNeeded = c_maxOwners + m_required;
             
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
         
        uint ownerIndexBit = 2**ownerIndex;
         
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
             
            if ((pending.yetNeeded <= c_maxOwners + 1) && ((pending.ownersDone & m_chiefOwnerIndexBit != 0) || (ownerIndexBit == m_chiefOwnerIndexBit))) {
                 
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            } else {
                 
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private returns (bool) {
        uint free = 1;
        while (free < m_numOwners) {
            while (free < m_numOwners && m_owners[free] != 0) {
                free++;
            }
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) {
                m_numOwners--;
            }
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0) {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[uint(m_owners[free])] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }
    
    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i) {
            if (m_pendingIndex[i] != 0) {
                delete m_pending[m_pendingIndex[i]];
            }
        }
        delete m_pendingIndex;
    }
        
     

     
    uint public m_required;
     
    uint public m_numOwners;
    
     
    address[8] public m_owners;
    uint public m_chiefOwnerIndexBit;
    uint constant c_maxOwners = 7;
     
    mapping(uint => uint) public m_ownerIndex;
     
    mapping(bytes32 => PendingState) public m_pending;
    bytes32[] public m_pendingIndex;
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract AlphaMarketTeamBountyWallet is Multiowned {
    function AlphaMarketTeamBountyWallet(address[] _owners, address _tokenAddress) Multiowned(_owners, _owners.length - 1) public {
        token = AlphaMarketCoin(_tokenAddress);
    }

    function transferTokens(address _to, uint256 _value) external onlymanyowners(sha3(msg.data)) {
        if(_value == 0 || token.balanceOf(this) < _value || _to == 0x0) {
            return;
        }
        token.transfer(_to, _value);
    }

     
    function () external payable {
        revert();
    }

    AlphaMarketCoin public token;
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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

}

contract AlphaMarketCoin is StandardToken {

    function AlphaMarketCoin(address _controller) public {
        controller = _controller;
        earlyAccess[_controller] = true;
        totalSupply_ = 999999999 * 10 ** uint256(decimals);
        balances[_controller] = totalSupply_;
    }

    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

     
    event TransferEnabled();

    function addEarlyAccessAddress(address _address) external onlyController {
        require(_address != 0x0);
        earlyAccess[_address] = true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled || earlyAccess[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        return super.approve(_spender, _value);
    }
    
    function enableTransfering() public onlyController {
        require(!isTransferEnabled);

        isTransferEnabled = true;
        emit TransferEnabled();
    }

     
    function () public payable {
        revert();
    }

    bool public isTransferEnabled = false;
    address public controller;
    mapping(address => bool) public earlyAccess;

    uint8 public constant decimals = 18;
    string public constant name = 'AlphaMarket Coin';
    string public constant symbol = 'AMC';
}
 

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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}


 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
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


 
contract BetexToken is StandardToken, NoOwner {

    string public constant name = "Betex Token";  
    string public constant symbol = "BETEX";  
    uint8 public constant decimals = 18;  

     
    uint256 public firstUnlockTime;

     
    uint256 public secondUnlockTime; 

     
    mapping (address => bool) public blockedTillSecondUnlock;

     
    address[] public holders;

     
    mapping (address => uint256) public holderNumber;

     
    address public icoAddress;

     
    uint256 public constant TOTAL_SUPPLY = 10000000 * (10 ** uint256(decimals));
    uint256 public constant SALE_SUPPLY = 5000000 * (10 ** uint256(decimals));

     
    uint256 public constant BOUNTY_SUPPLY = 200000 * (10 ** uint256(decimals));
    uint256 public constant RESERVE_SUPPLY = 800000 * (10 ** uint256(decimals));
    uint256 public constant BROKER_RESERVE_SUPPLY = 1000000 * (10 ** uint256(decimals));
    uint256 public constant TEAM_SUPPLY = 3000000 * (10 ** uint256(decimals));

     
    address public constant BOUNTY_ADDRESS = 0x48c15e5A9343E3220cdD8127620AE286A204448a;
    address public constant RESERVE_ADDRESS = 0xC8fE659AaeF73b6e41DEe427c989150e3eDAf57D;
    address public constant BROKER_RESERVE_ADDRESS = 0x8697d46171aBCaD2dC5A4061b8C35f909a402417;
    address public constant TEAM_ADDRESS = 0x1761988F02C75E7c3432fa31d179cad6C5843F24;

     
    uint256 public constant MIN_HOLDER_TOKENS = 10 ** uint256(decimals - 1);
    
     
    function BetexToken
    (
        uint256 _firstUnlockTime, 
        uint256 _secondUnlockTime
    )
        public 
    {        
        require(_secondUnlockTime > firstUnlockTime);

        firstUnlockTime = _firstUnlockTime;
        secondUnlockTime = _secondUnlockTime;

         
        balances[BOUNTY_ADDRESS] = BOUNTY_SUPPLY;
        holders.push(BOUNTY_ADDRESS);
        emit Transfer(0x0, BOUNTY_ADDRESS, BOUNTY_SUPPLY);

         
        balances[RESERVE_ADDRESS] = RESERVE_SUPPLY;
        holders.push(RESERVE_ADDRESS);
        emit Transfer(0x0, RESERVE_ADDRESS, RESERVE_SUPPLY);

         
        balances[BROKER_RESERVE_ADDRESS] = BROKER_RESERVE_SUPPLY;
        holders.push(BROKER_RESERVE_ADDRESS);
        emit Transfer(0x0, BROKER_RESERVE_ADDRESS, BROKER_RESERVE_SUPPLY);

         
        balances[TEAM_ADDRESS] = TEAM_SUPPLY;
        holders.push(TEAM_ADDRESS);
        emit Transfer(0x0, TEAM_ADDRESS, TEAM_SUPPLY);

        totalSupply_ = TOTAL_SUPPLY.sub(SALE_SUPPLY);
    }

     
    function setICO(address _icoAddress) public onlyOwner {
        require(_icoAddress != address(0));
        require(icoAddress == address(0));
        require(totalSupply_ == TOTAL_SUPPLY.sub(SALE_SUPPLY));
        
         
        balances[_icoAddress] = SALE_SUPPLY;
        emit Transfer(0x0, _icoAddress, SALE_SUPPLY);

        icoAddress = _icoAddress;
        totalSupply_ = TOTAL_SUPPLY;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(_from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

     
    function getHoldersCount() public view returns (uint256) {
        return holders.length;
    }

     
    function enforceSecondLock(address _from, address _to) internal {
        if (now < secondUnlockTime) {  
            if (_from == TEAM_ADDRESS || _from == BROKER_RESERVE_ADDRESS) {
                require(balances[_to] == uint256(0) || blockedTillSecondUnlock[_to]);
                blockedTillSecondUnlock[_to] = true;
            }
        }
    }

     
    function preserveHolders(address _from, address _to, uint256 _value) internal {
        if (balances[_from].sub(_value) < MIN_HOLDER_TOKENS) 
            removeHolder(_from);
        if (balances[_to].add(_value) >= MIN_HOLDER_TOKENS) 
            addHolder(_to);   
    }

     
    function removeHolder(address _holder) internal {
        uint256 _number = holderNumber[_holder];

        if (_number == 0 || holders.length == 0 || _number > holders.length)
            return;

        uint256 _index = _number.sub(1);
        uint256 _lastIndex = holders.length.sub(1);
        address _lastHolder = holders[_lastIndex];

        if (_index != _lastIndex) {
            holders[_index] = _lastHolder;
            holderNumber[_lastHolder] = _number;
        }

        holderNumber[_holder] = 0;
        holders.length = _lastIndex;
    } 

     
    function addHolder(address _holder) internal {
        if (holderNumber[_holder] == 0) {
            holders.push(_holder);
            holderNumber[_holder] = holders.length;
        }
    }

     
    function transferAllowed(address _sender) internal view returns(bool) {
        if (now > secondUnlockTime || _sender == icoAddress)  
            return true;
        if (now < firstUnlockTime)  
            return false;
        if (blockedTillSecondUnlock[_sender])
            return false;
        return true;
    }

}
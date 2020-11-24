 

pragma solidity ^0.4.24;

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
 
contract MD  {
    using SafeMath for uint256;

    string public constant name = "MD Token";
    string public constant symbol = "MD";

    uint public constant decimals = 18;

     
    uint256 _totalSupply = 3500000000 * 10**decimals;

    mapping(address => uint256) balances;  
    mapping(address => mapping (address => uint256)) allowed;

    address public owner;

    modifier ownerOnly {
      require(
            msg.sender == owner,
            "Sender not authorized."
        );
        _;
    }

    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    constructor(address _owner) public{
        owner = _owner;
        balances[owner] = _totalSupply;
        emit Transfer(0x0, _owner, _totalSupply);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
            balances[_to] = _value.add(balances[_to]);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function changeOwner(address _newowner) public ownerOnly returns (bool success) {
        owner = _newowner;
        return true;
    }

     
    function kill() public ownerOnly {
        selfdestruct(owner);
    }
}


contract TokenLock {
    using SafeMath for uint256;
    address public owner;
    address public md_address;
    
    struct LockRecord {
        address userAddress;
        uint256 amount;
        uint256 releaseTime;
    }
    
    LockRecord[] lockRecords;
    mapping(uint256 => bool) lockStatus;
    
    MD md;

    event Deposit(address indexed _userAddress, uint256 _amount, uint256 _releaseTime, uint256 _index);
    event Release(address indexed _userAddress, address indexed _merchantAddress, uint256 _merchantAmount, uint256 _releaseTime, uint256 _index);
    
    modifier ownerOnly {
      require(
            msg.sender == owner,
            "Sender not authorized."
        );
        _;
    }
    
     
    constructor(address _owner, address _md_address) public{
        owner = _owner;
        md_address = _md_address;
        md = MD(md_address);
    }

    function getContractBalance() public view returns (uint256 _balance) {
        return md.balanceOf(this);
    }
    
    function deposit(address _userAddress, uint256 _amount, uint256 _days) public ownerOnly {
        require(_amount > 0);
        require(md.transferFrom(_userAddress, this, _amount));
        uint256 releaseTime = block.timestamp + _days * 1 days;
        LockRecord memory r = LockRecord(_userAddress, _amount, releaseTime);
        uint256 l = lockRecords.push(r);
        emit Deposit(_userAddress, _amount, releaseTime, l.sub(1));
    }
    
    function release(uint256 _index, address _merchantAddress, uint256 _merchantAmount) public ownerOnly {
        require(
            lockStatus[_index] == false,
            "Already released."
        );
        
        LockRecord storage r = lockRecords[_index];
        
        require(
            r.releaseTime <= block.timestamp,
            "Release time not reached"
        );
        
        require(
            _merchantAmount <= r.amount,
            "Merchant amount larger than locked amount."
        );

        
        if (_merchantAmount > 0) {
            require(md.transfer(_merchantAddress, _merchantAmount));
        }
        
        uint256 remainingAmount = r.amount.sub(_merchantAmount);
        if (remainingAmount > 0){
            require(md.transfer(r.userAddress, remainingAmount));
        }

        lockStatus[_index] = true;
        emit Release(r.userAddress, _merchantAddress, _merchantAmount, r.releaseTime, _index);
    }
    
     
    function changeOwner(address _newowner) public ownerOnly returns (bool success) {
        owner = _newowner;
        return true;
    }
    
     
    function() payable public {
        if (!owner.call.value(msg.value)()) revert();
    }

     
    function kill() public ownerOnly {
        md.transfer(owner, getContractBalance());
        selfdestruct(owner);
    }

}
 

pragma solidity ^0.4.25;
 
 
 
 
 
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
     
     
     
    return a / b;
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
   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)
    public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract FMC is StandardToken, Ownable {
    using SafeMath for uint256;
    string public constant name = "Fan Mei Chain (FMC)";
    string public constant symbol = "FMC";
    uint8 public constant decimals = 18;
     
    uint256 constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));
     
    string public website = "www.fanmeichain.com";
     
    string public icon = "/icon/fmc.png";
     
    address public frozenAddress;
     
    mapping(address=>Info) internal fellowInfo;
     
    struct Info{
        uint256[] defrozenDates;                     
        mapping(uint256=>uint256) frozenValues;      
        uint256 totalFrozenValue;                    
    }
     
    event Frozen(address user, uint256 value, uint256 defrozenDate, uint256 totalFrozenValue);
    event Defrozen(address user, uint256 value, uint256 defrozenDate, uint256 totalFrozenValue);
     
    constructor(address _frozenAddress) public {
        require(_frozenAddress != address(0) && _frozenAddress != msg.sender);
        frozenAddress = _frozenAddress;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if(_to == frozenAddress){
             
            Info storage _info = fellowInfo[msg.sender];
            if(_info.totalFrozenValue > 0){
                for(uint i=0; i< _info.defrozenDates.length; i++){
                    uint256 _date0 = _info.defrozenDates[i];
                    if(_info.frozenValues[_date0] > 0 && now >= _date0){
                         
                        uint256 _defrozenValue = _info.frozenValues[_date0];
                        require(balances[frozenAddress] >= _defrozenValue);
                        balances[frozenAddress] = balances[frozenAddress].sub(_defrozenValue);
                        balances[msg.sender] = balances[msg.sender].add(_defrozenValue);
                        _info.totalFrozenValue = _info.totalFrozenValue.sub(_defrozenValue);
                        _info.frozenValues[_date0] = 0;
                        emit Transfer(frozenAddress, msg.sender, _defrozenValue);
                        emit Defrozen(msg.sender, _defrozenValue, _date0, _info.totalFrozenValue);
                    }
                }
            }
        }
        return true;
    }
     
    function issue(address[] payees, uint256[] values, uint16[] deferDays) public onlyOwner returns(bool) {
        require(payees.length > 0 && payees.length == values.length);
        uint256 _now0 = _getNow0();
        for (uint i = 0; i<payees.length; i++) {
            require(balances[owner] >= values[i], "Issuer balance is insufficient.");
             
            if (payees[i] == address(0) || values[i] == uint256(0)) {
                continue;
            }
            balances[owner] = balances[owner].sub(values[i]);
            balances[payees[i]] = balances[payees[i]].add(values[i]);
            emit Transfer(owner, payees[i], values[i]);
            uint256 _date0 = _now0.add(deferDays[i]*24*3600);
             
            if(_date0 > _now0){
                 
                Info storage _info = fellowInfo[payees[i]];
                uint256 _fValue = _info.frozenValues[_date0];
                if(_fValue == 0){
                     
                    _info.defrozenDates.push(_date0);
                }
                 
                _info.totalFrozenValue = _info.totalFrozenValue.add(values[i]);
                _info.frozenValues[_date0] = _info.frozenValues[_date0].add(values[i]);

                balances[payees[i]] = balances[payees[i]].sub(values[i]);
                balances[frozenAddress] = balances[frozenAddress].add(values[i]);
                emit Transfer(payees[i], frozenAddress, values[i]);
                emit Frozen(payees[i], values[i], _date0, _info.totalFrozenValue);
            }
        }
        return true;
    }
     
    function airdrop(address[] payees, uint256 value, uint16 deferDays) public onlyOwner returns(bool) {
        require(payees.length > 0 && value > 0);
        uint256 _amount = value.mul(payees.length);
        require(balances[owner] > _amount);
        uint256 _now0 = _getNow0();
        uint256 _date0 = _now0.add(deferDays*24*3600);
        for (uint i = 0; i<payees.length; i++) {
            require(balances[owner] >= value, "Issuer balance is insufficient.");
             
            if (payees[i] == address(0)) {
                _amount = _amount.sub(value);
                continue;
            }
             
            balances[payees[i]] = balances[payees[i]].add(value);
            emit Transfer(owner, payees[i], value);
             
            if(_date0 > _now0){
                 
                Info storage _info = fellowInfo[payees[i]];
                uint256 _fValue = _info.frozenValues[_date0];
                if(_fValue == 0){
                     
                    _info.defrozenDates.push(_date0);
                }
                 
                _info.totalFrozenValue = _info.totalFrozenValue.add(value);
                _info.frozenValues[_date0] = _info.frozenValues[_date0].add(value);
                balances[payees[i]] = balances[payees[i]].sub(value);
                balances[frozenAddress] = balances[frozenAddress].add(value);
                emit Transfer(payees[i], frozenAddress, value);
                emit Frozen(payees[i], value, _date0, _info.totalFrozenValue);
            }
        }
        balances[owner] = balances[owner].sub(_amount);
        return true;
    }
     
    function updateFrozenAddress(address newFrozenAddress) public onlyOwner returns(bool){
         
         
         
         
        require(newFrozenAddress != address(0) && newFrozenAddress != owner && newFrozenAddress != frozenAddress);
         
        require(balances[newFrozenAddress] == 0);
         
        balances[newFrozenAddress] = balances[frozenAddress];
        balances[frozenAddress] = 0;
        emit Transfer(frozenAddress, newFrozenAddress, balances[newFrozenAddress]);
        frozenAddress = newFrozenAddress;
        return true;
    }
     
    function defrozen(address fellow) public onlyOwner returns(bool){
        require(fellow != address(0));
        Info storage _info = fellowInfo[fellow];
        require(_info.totalFrozenValue > 0);
        for(uint i = 0; i< _info.defrozenDates.length; i++){
            uint256 _date0 = _info.defrozenDates[i];
            if(_info.frozenValues[_date0] > 0 && now >= _date0){
                 
                uint256 _defrozenValue = _info.frozenValues[_date0];
                require(balances[frozenAddress] >= _defrozenValue);
                balances[frozenAddress] = balances[frozenAddress].sub(_defrozenValue);
                balances[fellow] = balances[fellow].add(_defrozenValue);
                _info.totalFrozenValue = _info.totalFrozenValue.sub(_defrozenValue);
                _info.frozenValues[_date0] = 0;
                emit Transfer(frozenAddress, fellow, _defrozenValue);
                emit Defrozen(fellow, _defrozenValue, _date0, _info.totalFrozenValue);
            }
        }
        return true;
    }
     
    function getOwnAssets() public view returns(uint256, uint256, uint256[], uint256[]){
        return getAssets(msg.sender);
    }
     
    function getAssets(address fellow) public view returns(uint256, uint256, uint256[], uint256[]){
        uint256 _value = balances[fellow];
        Info storage _info = fellowInfo[fellow];
        uint256 _totalFrozenValue = _info.totalFrozenValue;
        uint256 _size = _info.defrozenDates.length;
        uint256[] memory _values = new uint256[](_size);
        for(uint i = 0; i < _size; i++){
            _values[i] = _info.frozenValues[_info.defrozenDates[i]];
        }
        return (_value, _totalFrozenValue, _info.defrozenDates, _values);
    }
     
    function setWebInfo(string _website, string _icon) public onlyOwner returns(bool){
        website = _website;
        icon = _icon;
        return true;
    }
     
    function getNow() public view returns(uint256){
        return now;
    }
     
    function _calcDate0(uint256 _timestamp) internal pure returns(uint256){
        return _timestamp.sub(_timestamp % (60*24));
    }
     
    function _getNow0() internal view returns(uint256){
        return _calcDate0(now);
    }
}
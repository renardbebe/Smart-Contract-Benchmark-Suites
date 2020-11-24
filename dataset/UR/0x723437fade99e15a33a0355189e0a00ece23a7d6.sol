 

pragma solidity ^0.4.19;


 
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


 
contract GreatHarmon is Ownable {

    using SafeMath for uint256;

     
    function GreatHarmon() public {
        
    }

     
    uint public cooldownTime = 1 days;

     
    uint public basicIncomeLimit = 10000;

     
    uint public dailySupply = 50;

     
    function getBasicIncome() public {
        Resident storage _resident = residents[idOf[msg.sender]-1];
        require(_isReady(_resident));
        require(_isUnderLimit());
        require(!frozenAccount[msg.sender]);  

        balanceOf[msg.sender] += dailySupply;

        totalSupply = totalSupply.add(dailySupply);

        _triggerCooldown(_resident);
        GetBasicIncome(idOf[msg.sender]-1, _resident.name, dailySupply, uint32(now));
        Transfer(address(this), msg.sender, dailySupply);
    }

    function _triggerCooldown(Resident storage _resident) internal {
        _resident.readyTime = uint32(now + cooldownTime);
    }

     
    function _isReady(Resident storage _resident) internal view returns (bool) {
        return (_resident.readyTime <= now);
    }

     
    function _isUnderLimit() internal view returns (bool) {
        return (balanceOf[msg.sender] <= basicIncomeLimit);
    }

     
    event JoinGreatHarmon(uint id, string name, string identity, uint32 date);
    event GetBasicIncome(uint id, string name, uint supply, uint32 date);

     
    struct Resident {
        string name;       
        string identity;   
        uint32 prestige;   
        uint32 joinDate;   
        uint32 readyTime;  
    }

    Resident[] public residents;

     
    mapping (address => uint) public idOf;

    function getResidentNumber() external view returns(uint) {
        return residents.length;
    }

     
    function joinGreatHarmon(string _name, string _identity) public payable returns(uint) {
         
        require(idOf[msg.sender] == 0);
        if (msg.value > 0) {
            donateMap[msg.sender] += msg.value;
            Donate(msg.sender, _name, msg.value, "");
        }
        return _createResident(_name, _identity);
    }

    function _createResident(string _name, string _identity) internal returns(uint) {
        uint id = residents.push(Resident(_name, _identity, 0, uint32(now), uint32(now)));
        idOf[msg.sender] = id;
        JoinGreatHarmon(id, _name, _identity, uint32(now));
        getBasicIncome();
        return id;
    }

    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }

    function setCooldownTime(uint _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
    }

    function setBasicIncomeLimit(uint _basicIncomeLimit) external onlyOwner {
        basicIncomeLimit = _basicIncomeLimit;
    }

    function setDailySupply(uint _dailySupply) external onlyOwner {
        dailySupply = _dailySupply;
    }

    mapping (address => bool) public frozenAccount;
    
     
    event FrozenAccount(address target, bool frozen);

     
     
     
    function freezeAccount(address target, bool freeze) external onlyOwner {
        frozenAccount[target] = freeze;
        FrozenAccount(target, freeze);
    }

    mapping (address => uint) public donateMap;

    event Donate(address sender, string name, uint amount, string text);

     
    function donate(string _text) payable public {
        if (msg.value > 0) {
            donateMap[msg.sender] += msg.value;
            Resident memory _resident = residents[idOf[msg.sender]-1];
            Donate(msg.sender, _resident.name, msg.value, _text);
        }
    }

     
     
    string public name = "Great Harmon Coin";
    string public symbol = "GHC";
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 0;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) { 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
    
}
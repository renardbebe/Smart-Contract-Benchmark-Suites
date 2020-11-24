 

pragma solidity ^0.4.18;

 

contract SmartCityToken {
    using SafeMath for uint256;

    address public owner;   
    address public crowdsale;  

    string constant public standard = "ERC20";  
    string constant public name = "Smart City";  
    string constant public symbol = "CITY";  

    uint256 constant public decimals = 5;  
    uint256 public totalSupply = 252862966307692;  

    uint256 constant public amountForSale = 164360928100000;  
    uint256 constant public amountReserved = 88502038207692;  
    uint256 constant public amountLocked = 61951426745384;  

    uint256 public startTime;  
    uint256 public unlockOwnerDate;  

    mapping(address => uint256) public balances;  
    mapping(address => mapping(address => uint256)) public allowances;  

    bool public burned;  

    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Approval(address indexed _owner, address indexed spender, uint256 value);  
    event Burned(uint256 amount);  

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     
    function SmartCityToken(address _ownerAddress, uint256 _startTime) public {
        owner = _ownerAddress;  
        startTime = _startTime;  
        unlockOwnerDate = startTime + 2 years;
        balances[owner] = totalSupply;  
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns(bool success) {
        require(now >= startTime);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        if (msg.sender == owner && now < unlockOwnerDate)
            require(balances[msg.sender].sub(_value) >= amountLocked);

        balances[msg.sender] = balances[msg.sender].sub(_value);  
        balances[_to] = balances[_to].add(_value);  

         
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns(bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);

        if (now < startTime)
            require(_from == owner);

        if (_from == owner && now < unlockOwnerDate)
            require(balances[_from].sub(_value) >= amountLocked);

        uint256 _allowance = allowances[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowances[_from][msg.sender] = _allowance.sub(_value);  

         
        return true;
    }

     
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return balances[_addr];
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) public returns(bool success) {
        return _approve(_spender, _value);
    }

     
    function _approve(address _spender, uint256 _value) internal returns(bool success) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));

        allowances[msg.sender][_spender] = _value;  

        Approval(msg.sender, _spender, _value);  
        return true;
    }

     
    function burn() public {
        if (!burned && now > startTime) {
            uint256 diff = balances[owner].sub(amountReserved);  

            balances[owner] = amountReserved;
            totalSupply = totalSupply.sub(diff);  

            burned = true;
            Burned(diff);  
        }
    }

     
    function setCrowdsale(address _crowdsaleAddress) public {
        require(msg.sender == owner);
        require(crowdsale == address(0));

        crowdsale = _crowdsaleAddress;
        assert(_approve(crowdsale, amountForSale));
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


     
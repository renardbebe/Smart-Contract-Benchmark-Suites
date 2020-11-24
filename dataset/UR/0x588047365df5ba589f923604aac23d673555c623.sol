 

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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract NaviToken is StandardToken, Ownable {
    event AssignmentStopped();
    event Frosted(address indexed to, uint256 amount, uint256 defrostClass);
    event Defrosted(address indexed to, uint256 amount, uint256 defrostClass);

	using SafeMath for uint256;

     
    string public constant name      = "NaviToken";
    string public constant symbol    = "NAVI";
    uint8 public constant decimals   = 18;

    uint256 public constant MAX_NUM_NAVITOKENS    = 1000000000 * 10 ** uint256(decimals);
    uint256 public constant START_ICO_TIMESTAMP   = 1519912800;   
     

    uint256 public constant MONTH_IN_MINUTES = 43200;  
    uint256 public constant DEFROST_AFTER_MONTHS = 6;

    uint256 public constant DEFROST_FACTOR_TEAMANDADV = 30;

    enum DefrostClass {Contributor, ReserveAndTeam, Advisor}

     
    address[] icedBalancesReserveAndTeam;
    mapping (address => uint256) mapIcedBalancesReserveAndTeamFrosted;
    mapping (address => uint256) mapIcedBalancesReserveAndTeamDefrosted;

    address[] icedBalancesAdvisors;
    mapping (address => uint256) mapIcedBalancesAdvisors;

     
    bool public batchAssignStopped = false;

    modifier canAssign() {
        require(!batchAssignStopped);
        require(elapsedMonthsFromICOStart() < 2);
        _;
    }

    function NaviToken() public {
         
         
    }

     
    function batchAssignTokens(address[] _addr, uint256[] _amounts, DefrostClass[] _defrostClass) public onlyOwner canAssign {
        require(_addr.length == _amounts.length && _addr.length == _defrostClass.length);
         
        for (uint256 index = 0; index < _addr.length; index++) {
            address toAddress = _addr[index];
            uint amount = _amounts[index];
            DefrostClass defrostClass = _defrostClass[index];  

            totalSupply = totalSupply.add(amount);
            require(totalSupply <= MAX_NUM_NAVITOKENS);

            if (defrostClass == DefrostClass.Contributor) {
                 
                balances[toAddress] = balances[toAddress].add(amount);
                Transfer(address(0), toAddress, amount);
            } else if (defrostClass == DefrostClass.ReserveAndTeam) {
                 
                icedBalancesReserveAndTeam.push(toAddress);
                mapIcedBalancesReserveAndTeamFrosted[toAddress] = mapIcedBalancesReserveAndTeamFrosted[toAddress].add(amount);
                Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.Advisor) {
                 
                icedBalancesAdvisors.push(toAddress);
                mapIcedBalancesAdvisors[toAddress] = mapIcedBalancesAdvisors[toAddress].add(amount);
                Frosted(toAddress, amount, uint256(defrostClass));
            }
        }
    }

    function elapsedMonthsFromICOStart() view public returns (uint256) {
       return (now <= START_ICO_TIMESTAMP) ? 0 : (now - START_ICO_TIMESTAMP) / 60 / MONTH_IN_MINUTES;
    }

    function canDefrostReserveAndTeam() view public returns (bool) {
        return elapsedMonthsFromICOStart() > DEFROST_AFTER_MONTHS;
    }

    function defrostReserveAndTeamTokens() public {
        require(canDefrostReserveAndTeam());

        uint256 monthsIndex = elapsedMonthsFromICOStart() - DEFROST_AFTER_MONTHS;

        if (monthsIndex > DEFROST_FACTOR_TEAMANDADV){
            monthsIndex = DEFROST_FACTOR_TEAMANDADV;
        }

         
        for (uint256 index = 0; index < icedBalancesReserveAndTeam.length; index++) {

            address currentAddress = icedBalancesReserveAndTeam[index];
            uint256 amountTotal = mapIcedBalancesReserveAndTeamFrosted[currentAddress].add(mapIcedBalancesReserveAndTeamDefrosted[currentAddress]);
            uint256 targetDefrosted = monthsIndex.mul(amountTotal).div(DEFROST_FACTOR_TEAMANDADV);
            uint256 amountToRelease = targetDefrosted.sub(mapIcedBalancesReserveAndTeamDefrosted[currentAddress]);

            if (amountToRelease > 0) {
                mapIcedBalancesReserveAndTeamFrosted[currentAddress] = mapIcedBalancesReserveAndTeamFrosted[currentAddress].sub(amountToRelease);
                mapIcedBalancesReserveAndTeamDefrosted[currentAddress] = mapIcedBalancesReserveAndTeamDefrosted[currentAddress].add(amountToRelease);
                balances[currentAddress] = balances[currentAddress].add(amountToRelease);

                Transfer(address(0), currentAddress, amountToRelease);
                Defrosted(currentAddress, amountToRelease, uint256(DefrostClass.ReserveAndTeam));
            }
        }
    }

    function canDefrostAdvisors() view public returns (bool) {
        return elapsedMonthsFromICOStart() >= DEFROST_AFTER_MONTHS;
    }

    function defrostAdvisorsTokens() public {
        require(canDefrostAdvisors());
        for (uint256 index = 0; index < icedBalancesAdvisors.length; index++) {
            address currentAddress = icedBalancesAdvisors[index];
            uint256 amountToDefrost = mapIcedBalancesAdvisors[currentAddress];
            if (amountToDefrost > 0) {
                balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
                mapIcedBalancesAdvisors[currentAddress] = mapIcedBalancesAdvisors[currentAddress].sub(amountToDefrost);

                Transfer(address(0), currentAddress, amountToDefrost);
                Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.Advisor));
            }
        }
    }

    function stopBatchAssign() public onlyOwner canAssign {
        batchAssignStopped = true;
        AssignmentStopped();
    }

    function() public payable {
        revert();
    }
}
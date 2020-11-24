 

pragma solidity 0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract EtherRichLand is Ownable, StandardToken {
    string public constant name = "Ether Rich Land";  
    string public constant symbol = "ERL";  
     

    using SafeMath for uint256;

    struct Investor {
        uint256 weiDonated;
        uint256 weiIncome;
        address landlord;
        uint256 taxRate;
    }

    mapping(uint256 => Investor) Land;
    uint256 public weiCollected = 0;
    uint256 public constant landTotal = 100;
    address public constant manager1 = 0x978076A6a69A29f6f114072950A4AF9D2bB23435;
    address public constant manager2 = 0xB362D19e44CbA1625d3837149F31bEaf318f5E61;
    address public constant manager3 = 0xF62C64729717E230445C3A1Bbfc0c8fbdb9CCB72;

    
 
  constructor(
    ) public {
     
  }


  function () external payable {

    require(msg.value >= 0.001 ether);  

    playGame(msg.sender, msg.value);  
  }


  function getLandTaxRate(uint256 _value) internal pure returns (uint256) {
    require(_value > 0);
    uint256 _taxRate = 0;

    if (_value > 0 && _value <= 1 ether) {
        _taxRate = 1;
    } else if (_value > 1 ether && _value <= 10 ether) {
        _taxRate = 5;
    } else if (_value > 10 ether && _value <= 100 ether) {
        _taxRate = 10;
    } else if (_value > 100 ether && _value <= 500 ether) {
        _taxRate = 15;
    } else if (_value > 500 ether && _value <= 1000 ether) {
        _taxRate = 20;
    } else if (_value > 1000 ether) {
        _taxRate = 30;
    }
    return _taxRate;
  }


  function playGame(address _from, uint256 _value) private  
  {
    require(_from != 0x0);  
    require(_value > 0);

     
    uint256 _landId = uint256(blockhash(block.number-1))%landTotal;
    uint256 _chanceId = uint256(blockhash(block.number-1))%10;

    uint256 weiTotal;
    address landlord;
    uint256 weiToLandlord;
    uint256 weiToSender;

    if (Land[_landId].weiDonated > 0) {
         
        if (_from != Land[_landId].landlord) {
            if (_chanceId == 5) {
                 
                weiTotal = Land[_landId].weiDonated + Land[_landId].weiIncome;
                landlord = Land[_landId].landlord;
                 
                Land[_landId].weiDonated = _value;
                Land[_landId].weiIncome = 0;
                Land[_landId].landlord = _from;
                Land[_landId].taxRate = getLandTaxRate(_value);

                landlord.transfer(weiTotal);
            } else {
                 
                weiToLandlord = _value * Land[_landId].taxRate / 100;
                weiToSender = _value - weiToLandlord;
                Land[_landId].weiIncome += weiToLandlord;

                _from.transfer(weiToSender);
            }
        } else {
             
            Land[_landId].weiDonated += _value;
            Land[_landId].taxRate = getLandTaxRate(Land[_landId].weiDonated);
        }   
    } else {
         
        Land[_landId].weiDonated = _value;
        Land[_landId].weiIncome = 0;
        Land[_landId].landlord = _from;
        Land[_landId].taxRate = getLandTaxRate(_value);
    }
  }


  function sellLand() public {
    uint256 _landId;
    uint256 totalWei = 0;
     
    address _from;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == msg.sender) {
            totalWei += Land[_landId].weiDonated;
            totalWei += Land[_landId].weiIncome;
             
            Land[_landId].weiDonated = 0;
            Land[_landId].weiIncome = 0;
            Land[_landId].landlord = 0x0;
            Land[_landId].taxRate = 0;
        }
    }
    if (totalWei > 0) {
        uint256 communityFunding = totalWei * 1 / 100;
        uint256 finalWei = totalWei - communityFunding;

        weiCollected += communityFunding;
        _from = msg.sender;
        _from.transfer(finalWei);
    }
  }

  function getMyBalance() view public returns (uint256, uint256, uint256) {
    require(msg.sender != 0x0);
    uint256 _landId;
    uint256 _totalWeiDonated = 0;
    uint256 _totalWeiIncome = 0;
    uint256 _totalLand = 0;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == msg.sender) {
            _totalWeiDonated += Land[_landId].weiDonated;
            _totalWeiIncome += Land[_landId].weiIncome;
            _totalLand += 1;
        }
    }
    return (_totalLand, _totalWeiDonated, _totalWeiIncome);
  }

  function getBalanceOfAccount(address _to) view public onlyOwner() returns (uint256, uint256, uint256) {
    require(_to != 0x0);

    uint256 _landId;
    uint256 _totalWeiDonated = 0;
    uint256 _totalWeiIncome = 0;
    uint256 _totalLand = 0;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == _to) {
            _totalWeiDonated += Land[_landId].weiDonated;
            _totalWeiIncome += Land[_landId].weiIncome;
            _totalLand += 1;
        }
    }
    return (_totalLand, _totalWeiDonated, _totalWeiIncome);
  }

  function sendFunding(address _to, uint256 _value) public onlyOwner() {
    require(_to != 0x0);
    require(_to == manager1 || _to == manager2 || _to == manager3);
    require(_value > 0);
    require(weiCollected >= _value);

    weiCollected -= _value;
    _to.transfer(_value);  
  }
}
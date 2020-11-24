 

pragma solidity 0.4.18;

 
contract ERC20Basic {
  uint8 public decimals = 8;
  uint256 public totalSupply;
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  
  address daka_holder = 0x2bC44Bca631B28d4B946b6b8db770d781f21a716;
  address community_holder = 0x8E05824c064559672d42b5d81720d36E3A1955D3;
  address dev_holder = 0xBfC89c5adA79002EbA7831F29bCf58e804cA418D;
  address support_holder = 0x33bF69EB5E4315F96aE8799f463FE577bDE77e4f;
  address consultant_holder = 0x6A8800307b4CC9283C25a23ee9440b8b02295214;
  address early_contributes_holder = 0xa5A34aA597279a646154D4054F87a705Bf1007e7;
  address reserved_holder = 0xB8b93ce61251338bbAeEB971b89FF5df7bcAf95C;

  
  uint256 daka_award = 6700000 * (10 ** 8);
  uint256 community_award = 1000000 * 10 ** 8;
  uint256 dev_group_award = 700000 * 10 ** 8;
  uint256 support_group_award = 700000 * 10 ** 8;
  uint256 group_consult = 300000 * 10 ** 8;
  uint256 early_contributes = 300000 * 10 ** 8;
  uint256 reserved_amount = 300000 * 10 ** 8;
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
          uint256 date_2019_6_1 = 1559318400;
          uint256 date_2020_1_1 = 1577808000;
          uint256 date_2020_6_1 = 1590940800;
          uint256 date_2021_6_1 = 1622476800;
          uint256 date_2022_1_1 = 1640966400;
          uint256 date_2022_6_1 = 1654012800;
          uint256 date_2023_6_1 = 1685548800;
      if (_owner == daka_holder) {
          uint256 remain_amount = 0;
          if (now < date_2019_6_1) {
              remain_amount = 6700000 * 10 ** 8;
          } else if (now < date_2020_6_1) {
              remain_amount = 4700000 * 10 ** 8;
          } else if (now < date_2021_6_1) {
              remain_amount = 3000000 * 10 ** 8;
          } else if (now < date_2022_6_1) {
              remain_amount = 1700000 * 10 ** 8;
          } else if (now < date_2023_6_1) {
              remain_amount = 700000 * 10 ** 8;
          } else {
              remain_amount = 0;
          }
          return balances[_owner] - remain_amount;
      }
      if (_owner == dev_holder) {
          if (now < date_2020_1_1) {
              return 0;
          }
      }
      if (_owner == support_holder) {
          if (now < date_2020_1_1) {
              return 0;
          }
      }
      if (_owner == reserved_holder) {
          if (now < date_2022_1_1) {
              return 0;
          }
      }
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



contract VariableSupplyToken is StandardToken, Ownable {
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _amount) public {
         
        require(_amount <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Burn(burner, _amount);
    }
}

contract IDakaToken is ERC20, Ownable {
    function burn(uint256 _amount) public;
}

contract DakaToken is IDakaToken, VariableSupplyToken {
    string public name = "iDaka Token";
    string public symbol = "IDK";
    string public version = "1.0";
    function DakaToken() {
        totalSupply = daka_award + community_award + dev_group_award + support_group_award + group_consult + early_contributes + reserved_amount;
        balances[daka_holder] = daka_award;
        balances[community_holder] = community_award;
        balances[dev_holder] = dev_group_award;
        balances[support_holder] = support_group_award;
        balances[consultant_holder] = group_consult;
        balances[early_contributes_holder] = early_contributes;
        balances[reserved_holder] = reserved_amount;
    }
}
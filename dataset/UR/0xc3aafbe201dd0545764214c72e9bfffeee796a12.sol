 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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





 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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


 
contract SHIPToken is StandardToken, BurnableToken, Ownable {

     
    string  public constant name = "SHIP Token";
    string  public constant symbol = "SHIP";
    uint8   public constant decimals = 18;
    string  public constant website = "https://shipowner.io"; 
    uint256 public constant INITIAL_SUPPLY      =  1500000000 * (10 ** uint256(decimals));
    uint256 public constant CROWDSALE_ALLOWANCE =   825000000 * (10 ** uint256(decimals));
    uint256 public constant TEAM_ALLOWANCE      =   225000000 * (10 ** uint256(decimals));
    uint256 public constant RESERVE_ALLOWANCE   =   450000000 * (10 ** uint256(decimals));

     
    uint256 public crowdSaleAllowance;       
    uint256 public teamAllowance;           
    uint256 public reserveAllowance;           
    address public crowdSaleAddr;            
    address public teamAddr;                
    address public reserveAddr;                
     
    bool    public transferEnabled = true;   

     

     
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        require(_to != address(teamAddr));
        require(_to != address(crowdSaleAddr));
        _;
    }

     
    function SHIPToken(address _admin, address _reserve) public {
         
         
         
         
        require(msg.sender != _admin);
        require(msg.sender != _reserve);

        totalSupply = INITIAL_SUPPLY;
        crowdSaleAllowance = CROWDSALE_ALLOWANCE;
        teamAllowance = TEAM_ALLOWANCE;
        reserveAllowance = RESERVE_ALLOWANCE;

         
        balances[msg.sender] = totalSupply.sub(teamAllowance).sub(reserveAllowance);
        Transfer(address(0x0), msg.sender, totalSupply.sub(teamAllowance).sub(reserveAllowance));

        balances[_admin] = teamAllowance;
        Transfer(address(0x0), _admin, teamAllowance);

        balances[_reserve] = reserveAllowance;
        Transfer(address(0x0), _reserve, reserveAllowance);

        teamAddr = _admin;
        approve(teamAddr, teamAllowance);

        reserveAddr = _reserve;
        approve(reserveAddr, reserveAllowance);        
    }

     
    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(_amountForSale <= crowdSaleAllowance);

         
        uint amount = (_amountForSale == 0) ? crowdSaleAllowance : _amountForSale;

         
        approve(crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);

        crowdSaleAddr = _crowdSaleAddr;
    }

     
    function transfer(address _to, uint256 _value) public validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public validDestination(_to) returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            if (msg.sender == crowdSaleAddr)
                crowdSaleAllowance = crowdSaleAllowance.sub(_value);
            if (msg.sender == teamAddr)
                teamAllowance = teamAllowance.sub(_value);
        }
        return result;
    }

     
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }
}
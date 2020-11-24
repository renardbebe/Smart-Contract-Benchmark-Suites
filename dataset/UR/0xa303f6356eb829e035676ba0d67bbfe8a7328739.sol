 

pragma solidity ^0.4.11;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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

    mapping(address => uint256) balances;

   
    function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
    }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract StandardToken is ERC20, BasicToken {

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }

}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

contract LiTeum is StandardToken, BurnableToken, Ownable {

     
    string  public constant name = "LiTeum";
    string  public constant symbol = "LTMF";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 100000000000 * (10 ** uint256(decimals));



     
    address public adminAddr;                
    bool    public transferEnabled = false;  

     
    modifier onlyWhenTransferEnabled() {
        if (!transferEnabled) {
            require(msg.sender == adminAddr);
        }
        _;
    }

     
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        _;
    }

     
    constructor(address _admin)public  {
         
        require(msg.sender != _admin);

        totalSupply = INITIAL_SUPPLY;

         
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        adminAddr = _admin;
    }

     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

    }

     
    function disableTransfer() external onlyOwner {
        transferEnabled = false;

    }

     
    function transferToAdmin(uint256 _value) public onlyOwner onlyWhenTransferEnabled returns (bool) {
    	return super.transfer(adminAddr, _value);
    }

    function adminTransfer(address _to, uint256 _value) public onlyWhenTransferEnabled returns (bool) {

    	require (msg.sender == adminAddr);
    	return super.transfer(_to, _value);

    }

     
    function transfer(address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
      require(msg.sender==_from);
      bool result = super.transferFrom(_from, _to, _value);
        return result;
    }

     
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(_value);
        emit Transfer(msg.sender, address(0x0), _value);
    }

     
    function kill() public onlyOwner
    {
        selfdestruct(owner);
    }
}
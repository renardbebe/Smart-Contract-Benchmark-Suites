 

pragma solidity ^0.4.18;


 
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


contract InvestorToken is StandardToken, Ownable {
    using SafeMath for uint;

    string public name = "Investor Token T77";
    string public symbol = "T77";
    uint public decimals = 2;
    uint public constant INITIAL_SUPPLY = 1000000000 * 10**2;
    mapping (address => bool) public distributors;
	address[] public distributorsList;

    bool public byuoutActive;
    uint public byuoutCount;
    uint public priceForBasePart;

    function InvestorToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

	 
    function() external payable {

    }

	 
    modifier canTransfer() {
        require(distributors[msg.sender] || msg.sender == owner);
        _;
    }

	 
    function setDistributor(address distributor, bool state) external onlyOwner{
		distributorsList.push(distributor);
        distributors[distributor] = state;
    }

	 
    function setByuoutActive(bool status) public onlyOwner {
        byuoutActive = status;
    }

	 
    function setByuoutCount(uint count) public onlyOwner {
        byuoutCount = count;
    }

	 
    function setPriceForBasePart(uint newPriceForBasePart) public onlyOwner {
        priceForBasePart = newPriceForBasePart;
    }

	 
    function sendToInvestor(address investor, uint value) public canTransfer {
        require(investor != 0x0 && value > 0);
        require(value <= balances[owner]);

        balances[owner] = balances[owner].sub(value);
        balances[investor] = balances[investor].add(value);
        addTokenHolder(investor);
        Transfer(owner, investor, value);
    }

	 
    function transfer(address to, uint value) public returns (bool success) {
        require(to != 0x0 && value > 0);

        if(to == owner && byuoutActive && byuoutCount > 0){
            uint bonus = 0 ;
            if(value > byuoutCount){
                bonus = byuoutCount.mul(priceForBasePart);
            }else{
                bonus = value.mul(priceForBasePart);
                byuoutCount = byuoutCount.sub(value);
            }
            msg.sender.transfer(bonus);
        }

        addTokenHolder(to);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(to != 0x0 && value > 0);
        addTokenHolder(to);
        return super.transferFrom(from, to, value);
    }

     

    mapping(uint => address) public indexedTokenHolders;
    mapping(address => uint) public tokenHolders;
    uint public tokenHoldersCount = 0;

    function addTokenHolder(address investor) private {
        if(investor != owner && indexedTokenHolders[0] != investor && tokenHolders[investor] == 0){
            tokenHolders[investor] = tokenHoldersCount;
            indexedTokenHolders[tokenHoldersCount] = investor;
            tokenHoldersCount ++;
        }
    }
}
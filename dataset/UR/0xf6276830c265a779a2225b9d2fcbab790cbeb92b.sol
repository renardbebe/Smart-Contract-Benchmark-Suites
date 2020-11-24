 

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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 

contract XcelToken is PausableToken, BurnableToken  {

    string public constant name = "XCELTOKEN";

    string public constant symbol = "XCEL";

     
    uint8 public constant decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY = 50 * (10**9) * (10 ** uint256(decimals));

     
    uint256 public constant foundationSupply = 5 * (10**9) * (10 ** uint256(decimals));

     
    uint256 public constant teamSupply = 7.5 * (10**9) * (10 ** uint256(decimals));

     
    uint256 public publicSaleSupply = 30 * (10**9) * (10 ** uint256(decimals));

     
    uint256 public loyaltySupply = 2.5 * (10**9) * (10 ** uint256(decimals));

     
    uint256 public constant reserveFundSupply = 5 * (10**9) * (10 ** uint256(decimals));

     
    address public tokenBuyerWallet =0x0;

     
    address public loyaltyWallet = 0x0;

     
    address public teamVestingContractAddress;

    bool public isTeamVestingInitiated = false;

    bool public isFoundationSupplyAssigned = false;

    bool public isReserveSupplyAssigned = false;

     
    event TokensBought(address indexed _to, uint256 _totalAmount, bytes4 _currency, bytes32 _txHash);
    event LoyaltySupplyAllocated(address indexed _to, uint256 _totalAmount);
    event LoyaltyWalletAddressChanged(address indexed _oldAddress, address indexed _newAddress);

     
    modifier onlyTokenBuyer() {
        require(msg.sender == tokenBuyerWallet);
        _;
    }

     
    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }


    function XcelToken(address _tokenBuyerWallet)
        public
        nonZeroAddress(_tokenBuyerWallet){

        tokenBuyerWallet = _tokenBuyerWallet;
        totalSupply_ = INITIAL_SUPPLY;

         
        balances[msg.sender] = totalSupply_;
        Transfer(address(0x0), msg.sender, totalSupply_);

         
         
         
        require(approve(tokenBuyerWallet, 0));
        require(approve(tokenBuyerWallet, publicSaleSupply));

    }

     
    function burn(uint256 _value)
      public
      onlyOwner {
        super.burn(_value);
    }

     
    function initiateTeamVesting(address _teamVestingContractAddress)
    external
    onlyOwner
    nonZeroAddress(_teamVestingContractAddress) {
        require(!isTeamVestingInitiated);
        teamVestingContractAddress = _teamVestingContractAddress;

        isTeamVestingInitiated = true;
         
        require(transfer(_teamVestingContractAddress, teamSupply));


    }

     

    function setLoyaltyWallet(address _loyaltyWallet)
    external
    onlyOwner
    nonZeroAddress(_loyaltyWallet){
        require(loyaltyWallet != _loyaltyWallet);
        loyaltyWallet = _loyaltyWallet;
        LoyaltyWalletAddressChanged(loyaltyWallet, _loyaltyWallet);
    }

     
    function allocateLoyaltySpend(uint256 _totalWeiAmount)
    external
    onlyOwner
    nonZeroAddress(loyaltyWallet)
    returns(bool){
        require(_totalWeiAmount > 0 && loyaltySupply >= _totalWeiAmount);
        loyaltySupply = loyaltySupply.sub(_totalWeiAmount);
        require(transfer(loyaltyWallet, _totalWeiAmount));
        LoyaltySupplyAllocated(loyaltyWallet, _totalWeiAmount);
        return true;
    }

     
    function assignFoundationSupply(address _foundationContractAddress)
    external
    onlyOwner
    nonZeroAddress(_foundationContractAddress){
        require(!isFoundationSupplyAssigned);
        isFoundationSupplyAssigned = true;
        require(transfer(_foundationContractAddress, foundationSupply));
    }

     
    function assignReserveSupply(address _reserveContractAddress)
    external
    onlyOwner
    nonZeroAddress(_reserveContractAddress){
        require(!isReserveSupplyAssigned);
        isReserveSupplyAssigned = true;
        require(transfer(_reserveContractAddress, reserveFundSupply));
    }

 

    function buyTokens(address _to, uint256 _totalWeiAmount, bytes4 _currency, bytes32 _txHash)
    external
    onlyTokenBuyer
    nonZeroAddress(_to)
    returns(bool) {
        require(_totalWeiAmount > 0 && publicSaleSupply >= _totalWeiAmount);
        publicSaleSupply = publicSaleSupply.sub(_totalWeiAmount);
        require(transferFrom(owner,_to, _totalWeiAmount));
        TokensBought(_to, _totalWeiAmount, _currency, _txHash);
        return true;
    }

     
    function () public payable {
        revert();
    }

}
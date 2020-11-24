 

 

pragma solidity ^0.4.23;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
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
  
    function transferWholeTokens(address _to, uint256 _value) public returns (bool) {
         
        uint256 value = _value;
        value = value.mul(1 ether);
        return transfer(_to, value);
    }



    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

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
        uint _addedValue
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
        uint _subtractedValue
    )
      public
      returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract GoldenUnitToken is StandardToken {
    string public constant name = "Golden Unite Token";
    string public constant symbol = "GUT";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 100000 * 1 ether;
    address public CrowdsaleAddress;
    
    event Mint(address indexed to, uint256 amount);
    
    constructor(address _CrowdsaleAddress) public {
      
        CrowdsaleAddress = _CrowdsaleAddress;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;      
    }
  
    modifier onlyOwner() {
        require(msg.sender == CrowdsaleAddress);
        _;
    }

    function acceptTokens(address _from, uint256 _value) public onlyOwner returns (bool){
        require (balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[CrowdsaleAddress] = balances[CrowdsaleAddress].add(_value);
        emit Transfer(_from, CrowdsaleAddress, _value);
        return true;
    }
  
    function mint(uint256 _amount)  public onlyOwner returns (bool){
        totalSupply_ = totalSupply_.add(_amount);
        balances[CrowdsaleAddress] = balances[CrowdsaleAddress].add(_amount);
        emit Mint(CrowdsaleAddress, _amount);
        emit Transfer(address(0), CrowdsaleAddress, _amount);
        return true;
    }


    function() external payable {
         
        revert();
    }  
}

contract Ownable {
    address public owner;
    address candidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        candidate = newOwner;
    }

    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }

}

contract GoldenUnionCrowdsale is Ownable {
    using SafeMath for uint; 
    address myAddress = this;
    uint public  saleRate = 30;   
    uint public  purchaseRate = 30;   
    bool public purchaseTokens = false;

    event Mint(address indexed to, uint256 amount);
    event SaleRates(uint256 indexed value);
    event PurchaseRates(uint256 indexed value);
    event Withdraw(address indexed from, address indexed to, uint256 amount);

    modifier purchaseAlloved() {
         
        require(purchaseTokens);
        _;
    }


    GoldenUnitToken public token = new GoldenUnitToken(myAddress);
  

    function mintTokens(uint256 _amount) public onlyOwner returns (bool){
         
        uint256 amount = _amount;
        require (amount <= 1000000);
        amount = amount.mul(1 ether);
        token.mint(amount);
        return true;
    }


    function giveTokens(address _newInvestor, uint256 _value) public onlyOwner {
         
         
        uint256 value = _value;
        require (_newInvestor != address(0));
        require (value >= 1);
        value = value.mul(1 ether);
        token.transfer(_newInvestor, value);
    }  
    
    function takeTokens(address _Investor, uint256 _value) public onlyOwner {
         
         
        uint256 value = _value;
        require (_Investor != address(0));
        require (value >= 1);
        value = value.mul(1 ether);
        token.acceptTokens(_Investor, value);    
    }  

 
 
    function setSaleRate(uint256 newRate) public onlyOwner {
        saleRate = newRate;
        emit SaleRates(newRate);
    }
  
    function setPurchaseRate(uint256 newRate) public onlyOwner {
        purchaseRate = newRate;
        emit PurchaseRates(newRate);
    }  
   
    function startPurchaseTokens() public onlyOwner {
        purchaseTokens = true;
    }

    function stopPurchaseTokens() public onlyOwner {
        purchaseTokens = false;
    }
  
    function purchase (uint256 _valueTokens) public purchaseAlloved {
         
        address profitOwner = msg.sender;
        require(profitOwner != address(0));
        require(_valueTokens > 0);
        uint256 valueTokens = _valueTokens;
        valueTokens = valueTokens.mul(1 ether);
         
        require (token.balanceOf(profitOwner) >= valueTokens);
         
        require (purchaseRate>0);
        uint256 valueEther = valueTokens.div(purchaseRate);
         
        require (myAddress.balance >= valueEther);
         
        if (token.acceptTokens(msg.sender, valueTokens)){
         
            profitOwner.transfer(valueEther);
        }
    }
  
    function withdrawProfit (address _to, uint256 _value) public onlyOwner {
         
        require (myAddress.balance >= _value);
        require(_to != address(0));
        _to.transfer(_value);
        emit Withdraw(msg.sender, _to, _value);
    }
 
    function saleTokens() internal {
        require (msg.value >= 1 ether);   
        uint tokens = saleRate.mul(msg.value);
        token.transfer(msg.sender, tokens);
    }
 
    function() external payable {
        saleTokens();
    }    
}
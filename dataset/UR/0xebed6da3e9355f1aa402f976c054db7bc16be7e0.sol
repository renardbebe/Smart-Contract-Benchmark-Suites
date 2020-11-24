 

pragma solidity 0.4.23;

 
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


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract IgfContract is Ownable
{

using SafeMath for uint256;
     
    mapping(address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => uint256) internal totalAllowed;

     
    uint256 internal totSupply;

     
    function totalSupply() view public returns(uint256)
    {
        return totSupply;
    }
    
    function getTotalAllowed(address _owner) view public returns(uint256)
    {
        return totalAllowed[_owner];
    }

    function setTotalAllowed(address _owner, uint256 _newValue) internal
    {
        totalAllowed[_owner]=_newValue;
    }


    function setTotalSupply(uint256 _newValue) internal
    {
        totSupply=_newValue;
    }


     

    function balanceOf(address _owner) view public returns(uint256)
    {
        return balances[_owner];
    }

    function setBalanceOf(address _investor, uint256 _newValue) internal
    {
        require(_investor!=0x0000000000000000000000000000000000000000);
        balances[_investor]=_newValue;
    }


     

    function allowance(address _owner, address _spender) view public returns(uint256)
    {
        require(msg.sender==_owner || msg.sender == _spender || msg.sender==getOwner());
        return allowed[_owner][_spender];
    }

    function setAllowance(address _owner, address _spender, uint256 _newValue) internal
    {
        require(_spender!=0x0000000000000000000000000000000000000000);
        uint256 newTotal = getTotalAllowed(_owner).sub(allowance(_owner, _spender)).add(_newValue);
        require(newTotal <= balanceOf(_owner));
        allowed[_owner][_spender]=_newValue;
        setTotalAllowed(_owner,newTotal);
    }



 
   constructor(uint256 _rate, uint256 _minPurchase,uint256 _cap) public
    {
        require(_minPurchase>0);
        require(_rate > 0);
        require(_cap > 0);
        rate=_rate;
        minPurchase=_minPurchase;
        cap = _cap;
    }

    bytes32 public constant name = "IGFToken";

    bytes3 public constant symbol = "IGF";

    uint8 public constant decimals = 8;

    uint256 public cap;

    bool internal mintingFinished;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);

    event MintFinished();
    
    event Burn(address indexed _owner, uint256 _value);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function getName() view public returns(bytes32)
    {
        return name;
    }

    function getSymbol() view public returns(bytes3)
    {
        return symbol;
    }

    function getTokenDecimals() view public returns(uint256)
    {
        return decimals;
    }
    
    function getMintingFinished() view public returns(bool)
    {
        return mintingFinished;
    }

    function getTokenCap() view public returns(uint256)
    {
        return cap;
    }

    function setTokenCap(uint256 _newCap) external onlyOwner
    {
        cap=_newCap;
    }


     

  function burn(address _owner,uint256 _value) external  {
    require(_value <= balanceOf(_owner));
     
     

    setBalanceOf(_owner, balanceOf(_owner).sub(_value));
    setTotalSupply(totalSupply().sub(_value));
    emit Burn(_owner, _value);
  }

    

    function updateTokenInvestorBalance(address _investor, uint256 _newValue) onlyOwner external
    {
        addTokens(_investor,_newValue);
    }

     

    function transfer(address _to, uint256 _value) external{
        require(msg.sender!=_to);
        require(_value <= balanceOf(msg.sender));

         
        setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));

        emit Transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external {
        require(_value <= balanceOf(_from));
        require(_value <= allowance(_from,_to));
        setBalanceOf(_from, balanceOf(_from).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));
        setAllowance(_from,_to,allowance(_from,_to).sub(_value));
        emit Transfer(_from, _to, _value);
    }

     
    function approve(address _owner,address _spender, uint256 _value) external {
        require(msg.sender ==_owner);
        setAllowance(msg.sender,_spender, _value);
        emit Approval(msg.sender, _spender, _value);
    }


     
    function increaseApproval(address _owner, address _spender, uint _addedValue) external{
        require(msg.sender==_owner);
        setAllowance(_owner,_spender,allowance(_owner,_spender).add(_addedValue));
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

     
    function decreaseApproval(address _owner,address _spender, uint _subtractedValue) external{
        require(msg.sender==_owner);

        uint oldValue = allowance(_owner,_spender);
        if (_subtractedValue > oldValue) {
            setAllowance(_owner,_spender, 0);
        } else {
            setAllowance(_owner,_spender, oldValue.sub(_subtractedValue));
        }
        emit Approval(_owner, _spender, allowance(_owner,_spender));
    }

     


    function mint(address _to, uint256 _amount) canMint internal{
        require(totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }
    
    function addTokens(address _to, uint256 _amount) canMint internal{
        require( totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        emit Transfer(address(0), _to, _amount);
    }    

     
    function finishMinting() canMint onlyOwner external{
        mintingFinished = true;
        emit MintFinished();
    }

     
    
         
    uint256 internal minPurchase;

     
    uint256 internal rate;

     
    uint256 internal weiRaised;
    
     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    event InvestmentsWithdrawn(uint indexed amount, uint indexed timestamp);

    function () external payable {
    }

    function getTokenRate() view public returns(uint256)
    {
        return rate;
    }

    function getMinimumPurchase() view public returns(uint256)
    {
        return minPurchase;
    }

    function setTokenRate(uint256 _newRate) external onlyOwner
    {
        rate = _newRate;
    }
    
    function setMinPurchase(uint256 _newMin) external onlyOwner
    {
        minPurchase = _newMin;
    }

    function getWeiRaised() view external returns(uint256)
    {
        return weiRaised;
    }

     
    function buyTokens() external payable{
        require(msg.value > 0);
        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);
        require(validPurchase(tokens));

         
        weiRaised = weiRaised.add(weiAmount);
        mint(msg.sender, tokens);
        emit TokenPurchase(msg.sender, weiAmount, tokens);
    }

     
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.div(getTokenRate());
    }

     
    function withdrawInvestments() external onlyOwner{
        uint  amount = address(this).balance;
        getOwner().transfer(amount * 1 wei);
        emit InvestmentsWithdrawn(amount, block.timestamp);
    }
    
    function getCurrentInvestments() view external onlyOwner returns(uint256)
    {
        return address(this).balance;
    }

    function getOwner() view internal returns(address)
    {
        return owner;
    }

     
    function validPurchase(uint256 tokensAmount) internal view returns (bool) {
        bool nonZeroPurchase = tokensAmount != 0;
        bool acceptableAmount = tokensAmount >= getMinimumPurchase();
        return nonZeroPurchase && acceptableAmount;
    }
    
     
    uint256 internal dividendsPaid;

    event DividendsPayment(uint256 amount, address beneficiary);

    function getTotalDividendsPaid() view external onlyOwner returns (uint256)
    {
        return dividendsPaid;
    }

    function getBalance() view public onlyOwner returns (uint256)
    {
        return address(this).balance;
    }

    function payDividends(address beneficiary,uint256 amount) external onlyOwner returns(bool)
    {
        require(amount > 0);
        validBeneficiary(beneficiary);
        beneficiary.transfer(amount);
        dividendsPaid.add(amount);
        emit DividendsPayment(amount, beneficiary);
        return true;
    }

    function depositDividends() payable external onlyOwner
    {
       address(this).transfer(msg.value);
    }
    
    function validBeneficiary(address beneficiary) view internal
    {
        require(balanceOf(beneficiary)>0);
    }
    
    
     
    
    function getInvestorBalance(address _address) view external returns(uint256)
    {
        return balanceOf(_address);
    }
}
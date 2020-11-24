 

pragma solidity ^0.4.24;

 
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

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract EcroContract is Ownable
{

using SafeMath for uint256;
     
    mapping(address => uint256) internal balances;

    mapping (address => mapping(uint256=>uint256)) masterNodes;
    
    mapping (address => uint256[]) masterNodesDates;

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

    function getMasterNodesDates(address _owner) view public returns(uint256[])
    {
        return masterNodesDates[_owner];
    }

    function getMasterNodes(address _owner, uint256 _date)  view public returns(uint256)
    {
        return masterNodes[_owner][_date];
    }

    function addMasterNodes(address _owner,uint256 _date,uint256 _amount) internal
    {
        masterNodesDates[_owner].push(_date);
        masterNodes[_owner][_date]=_amount;
    }

    function removeMasterNodes(address _owner,uint256 _date) internal
    {
        masterNodes[_owner][_date]=0;
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



 
    function EcroContract(uint256 _rate, uint256 _minPurchase,uint256 _tokenReturnRate,uint256 _cap,uint256 _nodePrice) public
    {
        require(_minPurchase>0);
        require(_rate > 0);
        require(_cap > 0);
        require(_nodePrice>0);
        require(_tokenReturnRate>0);
        rate=_rate;
        minPurchase=_minPurchase;
        tokenReturnRate=_tokenReturnRate;
        cap = _cap;
        nodePrice = _nodePrice;
    }

    bytes32 internal constant name = "ECRO Coin";

    bytes3 internal constant symbol = "ECR";

    uint8 internal constant decimals = 8;

    uint256 internal cap;

    uint256 internal nodePrice;

    bool internal mintingFinished;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    event Burn(address indexed burner, uint256 value);

    event TokenUnfrozen(address indexed owner, uint256 value);

    event TokenFrozen(address indexed owner, uint256 value);
  
    event MasterNodeBought(address indexed owner, uint256 amount);
    
    event MasterNodeReturned(address indexed owner, uint256 amount);
    
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

    function getNodePrice() view public returns(uint256)
    {
        return nodePrice;
    }

    function setNodePrice(uint256 _newPrice) external onlyOwner
    {
        require(_newPrice>0);
        nodePrice=_newPrice;
    }

     

  function burn(address _owner,uint256 _value) internal  {
    require(_value <= balanceOf(_owner));
     
     

    setBalanceOf(_owner, balanceOf(_owner).sub(_value));
    setTotalSupply(totalSupply().sub(_value));
    emit Burn(_owner, _value);
    emit Transfer(_owner, address(0), _value);
  }

    function freezeTokens(address _who, uint256 _value) internal
    {
        require(_value <= balanceOf(_who));
        setBalanceOf(_who, balanceOf(_who).sub(_value));
        emit TokenFrozen(_who, _value);
        emit Transfer(_who, address(0), _value);
  }
    
    function unfreezeTokens(address _who, uint256 _value) internal
    {
        setBalanceOf(_who, balanceOf(_who).add(_value));
        emit TokenUnfrozen(_who, _value);
        emit Transfer(address(0),_who, _value);
    }

    function buyMasterNodes(uint256 _date,uint256 _amount) external
    {
        freezeTokens(msg.sender,_amount*getNodePrice());
        addMasterNodes(msg.sender, _date, getMasterNodes(msg.sender,_date).add(_amount));
        MasterNodeBought(msg.sender,_amount);
    }  
    
    function returnMasterNodes(address _who, uint256 _date) onlyOwner external
    {
        uint256 amount = getMasterNodes(_who,_date);
        removeMasterNodes(_who, _date);
        unfreezeTokens(_who,amount*getNodePrice());
        MasterNodeReturned(_who,amount);
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

        Transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external {
        require(_value <= balanceOf(_from));
        require(_value <= allowance(_from,_to));
        setBalanceOf(_from, balanceOf(_from).sub(_value));
        setBalanceOf(_to, balanceOf(_to).add(_value));
        setAllowance(_from,_to,allowance(_from,_to).sub(_value));
        Transfer(_from, _to, _value);
    }

     
    function approve(address _owner,address _spender, uint256 _value) external {
        require(msg.sender ==_owner);
        setAllowance(msg.sender,_spender, _value);
        Approval(msg.sender, _spender, _value);
    }


     
    function increaseApproval(address _owner, address _spender, uint _addedValue) external{
        require(msg.sender==_owner);
        setAllowance(_owner,_spender,allowance(_owner,_spender).add(_addedValue));
        Approval(_owner, _spender, allowance(_owner,_spender));
    }

     
    function decreaseApproval(address _owner,address _spender, uint _subtractedValue) external{
        require(msg.sender==_owner);

        uint oldValue = allowance(_owner,_spender);
        if (_subtractedValue > oldValue) {
            setAllowance(_owner,_spender, 0);
        } else {
            setAllowance(_owner,_spender, oldValue.sub(_subtractedValue));
        }
        Approval(_owner, _spender, allowance(_owner,_spender));
    }

     


    function mint(address _to, uint256 _amount) canMint internal{
        require(totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
    }
    
    function addTokens(address _to, uint256 _amount) canMint internal{
        require( totalSupply().add(_amount) <= getTokenCap());
        setTotalSupply(totalSupply().add(_amount));
        setBalanceOf(_to, balanceOf(_to).add(_amount));
        Transfer(address(0), _to, _amount);
    }    

     
    function finishMinting() canMint onlyOwner external{
        mintingFinished = true;
        MintFinished();
    }

     
    
         
    uint256 internal minPurchase;

     
    uint256 internal rate;

     
    uint256 internal weiRaised;
    
    uint256 internal tokenReturnRate;

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    event InvestmentsWithdrawn(uint indexed amount, uint indexed timestamp);

    function () external payable {
    }

    function getTokenRate() view public returns(uint256)
    {
        return rate;
    }

    function getTokenReturnRate() view public returns(uint256)
    {
        return tokenReturnRate;
    }


    function getMinimumPurchase() view public returns(uint256)
    {
        return minPurchase;
    }

    function setTokenRate(uint256 _newRate) external onlyOwner
    {
        rate = _newRate;
    }
    
    function setTokenReturnRate(uint256 _newRate) external onlyOwner
    {
        tokenReturnRate = _newRate;
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
        TokenPurchase(msg.sender, weiAmount, tokens);
    }

     
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.div(getTokenRate());
    }

     
    function withdrawInvestments() external onlyOwner{
        uint  amount = this.balance;
        getOwner().transfer(amount * 1 wei);
        InvestmentsWithdrawn(amount, block.timestamp);
    }
    
    function returnTokens(uint256 _amount) external
    {
        require(balanceOf(msg.sender) >= _amount);
        burn(msg.sender,_amount);
         
        msg.sender.transfer(getTokenRate().mul(_amount).div(100).mul(tokenReturnRate));
    }

    function getCurrentInvestments() view external onlyOwner returns(uint256)
    {
        return this.balance;
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
    
}
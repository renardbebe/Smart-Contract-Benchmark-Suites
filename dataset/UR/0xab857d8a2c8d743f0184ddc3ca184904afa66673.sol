 

pragma solidity ^0.4.18;

 
library SafeMath {
 
  function Mul(uint a, uint b) internal pure returns (uint) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function Div(uint a, uint b) internal pure returns (uint) {
     
    uint256 c = a / b;
     
    return c;
  }

  function Sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  } 

  function Add(uint a, uint b) internal pure returns (uint) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  } 
}

 
contract ERC223ReceivingContract { 
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract Ownable {

   
  address public owner;
   
  address oldOwner;

   
  function Ownable() public {
    owner = msg.sender;
    oldOwner = msg.sender;
  }

   
  modifier onlyOwner() {
    require (msg.sender == owner || msg.sender == oldOwner);
      _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require (newOwner != address(0));
    owner = newOwner;
  }

}

 
contract ERC20 is Ownable {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public view returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract CTV is ERC20 {

    using SafeMath for uint256;
     
    string public constant name = "Coin TV";
     
    string public constant symbol = "CTV";
     
    bool public locked;
     
    uint8 public constant decimals = 18;
     
    uint256 constant MAXCAP = 29999990e18;
     
    uint public constant MAX_REFERRAL_TOKENS = 2999999e18;
     
    uint256 constant SOFTCAP = 70 ether;
     
     
     
     
     
     
    uint256 public refundStatus = 0;
     
    address public ethCollector;
     
    uint256 public totalWeiReceived;
     
    uint256 public tokensSuppliedFromReferral = 0;

     
    mapping(address => mapping(address => uint256)) allowed;
     
    mapping(address => address) public referredBy;
     
    mapping(address => uint256) balances;

     
    struct Investor {
         
        uint weiReceived;
         
        uint tokensPurchased;
         
        bool refunded;
         
        uint investorID;
    }

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    bool public saleRunning;
     
    mapping(address => Investor) public investors;
     
    mapping (uint256 => address) public investorList;
     
    uint256 public countTotalInvestors;
     
    uint256 countInvestorsRefunded;

     
    event StateChanged(bool);

    function CTV() public{
        totalSupply = 0;
        startTime = 0;
        endTime = 0;
        saleRunning = false;
        locked = true;
        setEthCollector(0xAf3BBf663769De9eEb6C2b235262Cf704eD4EA4b);
        mintAlreadyBoughtTokens(0x19566f85835e52e78edcfba440aea5e28783050b,66650000000000000000);
        mintAlreadyBoughtTokens(0xcb969c937e724f1d36ea2fb576148d8286399806,666500000000000000000);
        mintAlreadyBoughtTokens(0x43feda65c918642faf6186c8575fdbb582f4ecd5,2932600000000000000000);
        mintAlreadyBoughtTokens(0x0c94e8579ab97dc2dd805bed3fa72af9cbe8e37c,1466300000000000000000);
        mintAlreadyBoughtTokens(0xaddc8429aa246fedc40005ae4c7f340d94cbb05b,733150000000000000000);
        
        mintAlreadyBoughtTokens(0x99ea6d3bd3f4dd4447d0083d906d64cbeadba33a,733150000000000000000);
        mintAlreadyBoughtTokens(0x99f9493b162ac63d2c61514739a701731ac72398,3665750000000000000000);
        mintAlreadyBoughtTokens(0xa7e919d4d655d86382f76eb5e8151e99ecb4a0da,3470694090746885970870);
        mintAlreadyBoughtTokens(0x1aa18bf38d97a1a68a0119d2287041909b4e6680,1626260000000000000000);
        mintAlreadyBoughtTokens(0x90702a5432f97d01770365d52c312f96dc108e90,1466300000000000000000);
        
        mintAlreadyBoughtTokens(0x562ebcdfe25cfb1985f94836cdc23d3a1d32d8b5,733150000000000000000);
        mintAlreadyBoughtTokens(0x437b405657f4ec00a34ce8b212e52b8a78a14b31,2932600000000000000000);
        mintAlreadyBoughtTokens(0x23c36686b733acdd5266e429b5b132d3da607394,733150000000000000000);
        mintAlreadyBoughtTokens(0xaf933e90e7cf328edeece1f043faed2c5856745e,733150000000000000000);
        mintAlreadyBoughtTokens(0x1d3c7bb8a95ad08740fe2726dd183aa85ffc42f8,1466300000000000000000);
        
        mintAlreadyBoughtTokens(0xd01362b2d59276f8d5d353d180a8f30e2282a23e,733150000000000000);
    }
     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier onlyUnlocked() { 
        require (!locked); 
        _; 
    }

    modifier validTimeframe(){
        require(saleRunning && now >=startTime && now < endTime);
        _;
    }
    
    function setEthCollector(address _ethCollector) public onlyOwner{
        require(_ethCollector != address(0));
        ethCollector = _ethCollector;
    }
    
    function startSale() public onlyOwner{
        require(startTime == 0);
        startTime = now;
        endTime = startTime.Add(7 weeks);
        saleRunning = true;
    }

     
    function unlockTransfer() external onlyOwner{
        locked = false;
    }

     
    function isContract(address _address) private view returns(bool _isContract){
        assert(_address != address(0) );
        uint length;
         
        assembly{
            length := extcodesize(_address)
        }
        if(length > 0){
            return true;
        }
        else{
            return false;
        }
    }

     
    function balanceOf(address _owner) public view returns (uint256 _value){
        return balances[_owner];
    }

     
    function transfer(address _to, uint _value) onlyUnlocked onlyPayloadSize(2 * 32) public returns(bool _success) {
        require( _to != address(0) );
        bytes memory _empty;
        if((balances[msg.sender] > _value) && _value > 0 && _to != address(0)){
            balances[msg.sender] = balances[msg.sender].Sub(_value);
            balances[_to] = balances[_to].Add(_value);
            if(isContract(_to)){
                ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
                receiver.tokenFallback(msg.sender, _value, _empty);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

     
    function transfer(address _to, uint _value, bytes _data) onlyUnlocked onlyPayloadSize(3 * 32) public returns(bool _success) {
        if((balances[msg.sender] > _value) && _value > 0 && _to != address(0)){
            balances[msg.sender] = balances[msg.sender].Sub(_value);
            balances[_to] = balances[_to].Add(_value);
            if(isContract(_to)){
                ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
                receiver.tokenFallback(msg.sender, _value, _data);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3*32) public onlyUnlocked returns (bool){
        bytes memory _empty;
        if((_value > 0)
           && (_to != address(0))
       && (_from != address(0))
       && (allowed[_from][msg.sender] > _value )){
           balances[_from] = balances[_from].Sub(_value);
           balances[_to] = balances[_to].Add(_value);
           allowed[_from][msg.sender] = allowed[_from][msg.sender].Sub(_value);
           if(isContract(_to)){
               ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
               receiver.tokenFallback(msg.sender, _value, _empty);
           }
           Transfer(_from, _to, _value);
           return true;
       }
       else{
           return false;
       }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool){
        if( (_value > 0) && (_spender != address(0)) && (balances[msg.sender] >= _value)){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        else{
            return false;
        }
    }

     
    function getPrice() public view returns(uint256) {
        uint256 price;
        if(totalSupply <= 1e6*1e18)
            price = 13330;
        else if(totalSupply <= 5e6*1e18)
            price = 12500;
        else if(totalSupply <= 9e6*1e18)
            price = 11760;
        else if(totalSupply <= 13e6*1e18)
            price = 11110;
        else if(totalSupply <= 17e6*1e18)
            price = 10520;
        else if(totalSupply <= 21e6*1e18)
            price = 10000;
        else{
             
             
            price = 0;
        }
        return price;
    }
    
    function mintAndTransfer(address beneficiary, uint256 numberOfTokensWithoutDecimal, bytes comment) public onlyOwner {
        uint256 tokensToBeTransferred = numberOfTokensWithoutDecimal*1e18;
        require(totalSupply.Add(tokensToBeTransferred) <= MAXCAP);
        totalSupply = totalSupply.Add(tokensToBeTransferred);
        Transfer(0x0, beneficiary ,tokensToBeTransferred);
    }
    
    function mintAlreadyBoughtTokens(address beneficiary, uint256 tokensBought)internal{
         
        Investor storage investorStruct = investors[beneficiary];
         
        if(investorStruct.investorID == 0){
            countTotalInvestors++;
            investorStruct.investorID = countTotalInvestors;
            investorList[countTotalInvestors] = beneficiary;
        }
        investorStruct.weiReceived = investorStruct.weiReceived + tokensBought/13330;
        investorStruct.tokensPurchased = investorStruct.tokensPurchased + tokensBought;
        balances[beneficiary] = balances[beneficiary] + tokensBought;
        totalWeiReceived = totalWeiReceived + tokensBought/13330;
        totalSupply = totalSupply + tokensBought;
        
        Transfer(0x0, beneficiary ,tokensBought);
    }

     
    function pauseSale() public onlyOwner{
        assert(saleRunning && startTime > 0 && now <= endTime);
        saleRunning = false;
    }

     
    function resumeSale() public onlyOwner{
        assert(!saleRunning && startTime > 0 && now <= endTime);
        saleRunning = true;
    }

    function buyTokens(address beneficiary) internal validTimeframe {
        uint256 tokensBought = msg.value.Mul(getPrice());
        balances[beneficiary] = balances[beneficiary].Add(tokensBought);
        Transfer(0x0, beneficiary ,tokensBought);
        totalSupply = totalSupply.Add(tokensBought);

         
        Investor storage investorStruct = investors[beneficiary];
         
        if(investorStruct.investorID == 0){
            countTotalInvestors++;
            investorStruct.investorID = countTotalInvestors;
            investorList[countTotalInvestors] = beneficiary;
        }
        investorStruct.weiReceived = investorStruct.weiReceived.Add(msg.value);
        investorStruct.tokensPurchased = investorStruct.tokensPurchased.Add(tokensBought);
    
        
         
        if(referredBy[msg.sender] != address(0) && tokensSuppliedFromReferral.Add(tokensBought/10) < MAX_REFERRAL_TOKENS){
             
            balances[referredBy[msg.sender]] = balances[referredBy[msg.sender]].Add(tokensBought/10);
            tokensSuppliedFromReferral = tokensSuppliedFromReferral.Add(tokensBought/10);
            totalSupply = totalSupply.Add(tokensBought/10);
            Transfer(0x0, referredBy[msg.sender] ,tokensBought);
        }
         
        if(referredBy[referredBy[msg.sender]] != address(0) && tokensSuppliedFromReferral.Add(tokensBought/100) < MAX_REFERRAL_TOKENS){
            tokensSuppliedFromReferral = tokensSuppliedFromReferral.Add(tokensBought/100);
             
            balances[referredBy[referredBy[msg.sender]]] = balances[referredBy[referredBy[msg.sender]]].Add(tokensBought/100);
            totalSupply = totalSupply.Add(tokensBought/100);
            Transfer(0x0, referredBy[referredBy[msg.sender]] ,tokensBought);
        }
        
        assert(totalSupply <= MAXCAP);
        totalWeiReceived = totalWeiReceived.Add(msg.value);
        ethCollector.transfer(msg.value);
    }

     
    function registerReferral (address referredByAddress) public {
        require(msg.sender != referredByAddress && referredByAddress != address(0));
        referredBy[msg.sender] = referredByAddress;
    }
    
     
    function referralRegistration(address heWasReferred, address I_referred_this_person) public onlyOwner {
        require(heWasReferred != address(0) && I_referred_this_person != address(0));
        referredBy[heWasReferred] = I_referred_this_person;
    }

     
    function finalize() public onlyOwner {
         
        assert(saleRunning);
        if(MAXCAP.Sub(totalSupply) <= 1 ether || now > endTime){
             
            saleRunning = false;
        }

         
         
         
         
         
         

         
        if (totalWeiReceived < SOFTCAP)
            refundStatus = 2;
        else
            refundStatus = 1;

         
        saleRunning = false;
         
        locked = false;
         
        StateChanged(true);
    }

     
    function refund() public onlyOwner {
        assert(refundStatus == 2 || refundStatus == 3);
        uint batchSize = countInvestorsRefunded.Add(30) < countTotalInvestors ? countInvestorsRefunded.Add(30): countTotalInvestors;
        for(uint i=countInvestorsRefunded.Add(1); i <= batchSize; i++){
            address investorAddress = investorList[i];
            Investor storage investorStruct = investors[investorAddress];
             
            if(investorStruct.tokensPurchased > 0 && investorStruct.tokensPurchased <= balances[investorAddress]){
                 
                investorAddress.transfer(investorStruct.weiReceived);
                 
                totalWeiReceived = totalWeiReceived.Sub(investorStruct.weiReceived);
                 
                totalSupply = totalSupply.Sub(investorStruct.tokensPurchased);
                 
                balances[investorAddress] = balances[investorAddress].Sub(investorStruct.tokensPurchased);
                 
                investorStruct.weiReceived = 0;
                investorStruct.tokensPurchased = 0;
                investorStruct.refunded = true;
            }
        }
         
        countInvestorsRefunded = batchSize;
        if(countInvestorsRefunded == countTotalInvestors){
            refundStatus = 4;
        }
        StateChanged(true);
    }
    
    function extendSale(uint56 numberOfDays) public onlyOwner{
        saleRunning = true;
        endTime = now.Add(numberOfDays*86400);
        StateChanged(true);
    }

     
    function prepareForRefund() public payable {}

    function () public payable {
        buyTokens(msg.sender);
    }

     
    function drain() public onlyOwner {
        owner.transfer(this.balance);
    }
}
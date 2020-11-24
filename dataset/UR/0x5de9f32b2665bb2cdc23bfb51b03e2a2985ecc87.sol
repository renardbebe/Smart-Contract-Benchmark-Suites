 

pragma solidity 0.4.21;

 

 

 
library BytesDeserializer {

   
  function slice32(bytes b, uint offset) public pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function sliceAddress(bytes b, uint offset) public pure returns (address) {
    bytes32 out;

    for (uint i = 0; i < 20; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
    }
    return address(uint(out));
  }

   
  function slice16(bytes b, uint offset) public pure returns (bytes16) {
    bytes16 out;

    for (uint i = 0; i < 16; i++) {
      out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function slice4(bytes b, uint offset) public pure returns (bytes4) {
    bytes4 out;

    for (uint i = 0; i < 4; i++) {
      out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function slice2(bytes b, uint offset) public pure returns (bytes2) {
    bytes2 out;

    for (uint i = 0; i < 2; i++) {
      out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

}

 

 


 
contract KYCPayloadDeserializer {

  using BytesDeserializer for bytes;

   
  function getKYCPayload(bytes dataframe) public pure returns(address whitelistedAddress, uint128 customerId, uint32 minEth, uint32 maxEth) {
    address _whitelistedAddress = dataframe.sliceAddress(0);
    uint128 _customerId = uint128(dataframe.slice16(20));
    uint32 _minETH = uint32(dataframe.slice4(36));
    uint32 _maxETH = uint32(dataframe.slice4(40));
    return (_whitelistedAddress, _customerId, _minETH, _maxETH);
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 

pragma solidity 0.4.21;




 
contract ReleasableToken is StandardToken, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {
    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }
    _;
  }

   
  function setReleaseAgent() onlyOwner inReleaseState(false) public {

     
    releaseAgent = owner;
  }

   
  function setTransferAgent(address addr, bool state) onlyReleaseAgent inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 

 

contract MintableToken is ReleasableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 

pragma solidity 0.4.21;



 
contract AMLToken is MintableToken {

   
  event ReclaimedAllAndBurned(address claimedBy, address fromWhom, uint amount);

     
  event ReclaimAndBurned(address claimedBy, address fromWhom, uint amount);

   
   
   
   
  function reclaimAllAndBurn(address fromWhom) public onlyReleaseAgent inReleaseState(false) {
    uint amount = balanceOf(fromWhom);    
    balances[fromWhom] = 0;
    totalSupply = totalSupply.sub(amount);
    
    ReclaimedAllAndBurned(msg.sender, fromWhom, amount);
  }

   
   
   
   
  function reclaimAndBurn(address fromWhom, uint256 amount) public onlyReleaseAgent inReleaseState(false) {       
    balances[fromWhom] = balances[fromWhom].sub(amount);
    totalSupply = totalSupply.sub(amount);
    
    ReclaimAndBurned(msg.sender, fromWhom, amount);
  }
}

 

 


contract PickToken is AMLToken {
  string public name = "AX1 Mining token";
  string public symbol = "AX1";
  uint8 public decimals = 5;
}

 

contract Stoppable is Ownable {
  bool public halted;

  event SaleStopped(address owner, uint256 datetime);

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  function hasHalted() internal view returns (bool isHalted) {
  	return halted;
  }

    
  function stopICO() external onlyOwner {
    halted = true;
    SaleStopped(msg.sender, now);
  }
}

 

 
contract Crowdsale is Stoppable {
  using SafeMath for uint256;

   
  PickToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;
  address public contractAddr;
  
   
  uint256 public rate;

   
  uint256 public weiRaised;
  uint256 public presaleWeiRaised;

   
  uint256 public tokensSent;

   
  mapping(uint128 => uint256) public balancePerID;
  mapping(address => uint256) public balanceOf;
  mapping(address => uint256) public presaleBalanceOf;
  mapping(address => uint256) public tokenBalanceOf;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 datetime);

   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, PickToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = _token;
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    transferOwnership(_wallet);
  }

    
  function buyTokens(uint128 buyer) internal stopInEmergency {
    require(buyer != 0);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = tokensToRecieve(weiAmount);

     
    require(validPurchase(tokens));

     
    finalizeSale(weiAmount, tokens, buyer);
    produceTokens(msg.sender, weiAmount, tokens);
  }

   
  function produceTokens(address buyer, uint256 weiAmount, uint256 tokens) internal {
    token.mint(buyer, tokens);
    TokenPurchase(msg.sender, buyer, weiAmount, tokens, now);
  }

   
   
  function finalizeSale(uint256 _weiAmount, uint256 _tokens, uint128 _buyer) internal {
     
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_weiAmount);
    tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(_tokens);
    balancePerID[_buyer] = balancePerID[_buyer].add(_weiAmount);

     
    weiRaised = weiRaised.add(_weiAmount);
    tokensSent = tokensSent.add(_tokens);
  }
  
   
   
  function tokensToRecieve(uint256 _wei) internal view returns (uint256 tokens) {
    return _wei.div(rate);
  }

   
   
  function successfulWithdraw() external onlyOwner stopInEmergency {
    require(hasEnded());

    owner.transfer(weiRaised);
  }

   
   
   
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public softCap;
  uint256 public hardCap;
  uint256 public withdrawn;
  bool public canWithdraw;
  address public beneficiary;

  event BeneficiaryWithdrawal(address admin, uint256 amount, uint256 datetime);

   
  function CappedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, uint256 _softCap, uint256 _hardCap, PickToken _token) 
    Crowdsale(_startTime, _endTime, _rate, _wallet, _token)
      public {

    require(_hardCap > 0 && _softCap > 0 && _softCap < _hardCap);

    softCap = _softCap;
    hardCap = _hardCap;
    withdrawn = 0;
    canWithdraw = false;
    beneficiary = _beneficiary;
  }

   
   
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool withinCap = tokensSent.add(_tokens) <= hardCap;
    return super.validPurchase(_tokens) && withinCap;
  }
  
   
   
  function hasEnded() public view returns (bool) {
    bool capReached = tokensSent >= hardCap;
    return super.hasEnded() || capReached;
  }

   
   
   
  function successfulWithdraw() external onlyOwner stopInEmergency {
    require(hasEnded());
     
    require(canWithdraw);
    require(tokensSent > softCap);

    uint256 withdrawalAmount = weiRaised.sub(withdrawn);

    withdrawn = withdrawn.add(withdrawalAmount);

    beneficiary.transfer(withdrawalAmount);

    BeneficiaryWithdrawal(msg.sender, withdrawalAmount, now);
  }

}

 

 

library SaleStagesLib {
	using SafeMath for uint256;

	 
	struct Stage{
        uint256 deadline;
        uint256 tokenPrice;
        uint256 tokensSold;
        uint256 minimumBuy;
        uint256 cap;
	}

	 
	 
	struct StageStorage {
 		mapping(uint8 => Stage) stages;
 		uint8 stageCount;
	}

	 
	function init(StageStorage storage self) public {
		self.stageCount = 0;
	}

	 
	function createStage(
		StageStorage storage self, 
		uint8 _stage, 
		uint256 _deadline, 
		uint256 _price,
		uint256 _minimum,
		uint256 _cap
	) internal {
         
        uint8 prevStage = _stage - 1;
        require(self.stages[prevStage].deadline < _deadline);
		
        self.stages[_stage].deadline = _deadline;
		self.stages[_stage].tokenPrice = _price;
		self.stages[_stage].tokensSold = 0;
		self.stages[_stage].minimumBuy = _minimum;
		self.stages[_stage].cap = _cap;
		self.stageCount = self.stageCount + 1;
	}

    
    function getStage(StageStorage storage self) public view returns (uint8 stage) {
        uint8 thisStage = self.stageCount + 1;

        for (uint8 i = 0; i < thisStage; i++) {
            if(now <= self.stages[i].deadline){
                return i;
            }
        }

        return thisStage;
    }

     
     
    function checkMinimum(StageStorage storage self, uint8 _stage, uint256 _tokens) internal view returns (bool isValid) {
    	if(_tokens < self.stages[_stage].minimumBuy){
    		return false;
    	} else {
    		return true;
    	}
    }

     
     
    function changeDeadline(StageStorage storage self, uint8 _stage, uint256 _deadline) internal {
        require(self.stages[_stage].deadline > now);
        self.stages[_stage].deadline = _deadline;
    }

     
    function checkCap(StageStorage storage self, uint8 _stage, uint256 _tokens) internal view returns (bool isValid) {
    	uint256 totalTokens = self.stages[_stage].tokensSold.add(_tokens);

    	if(totalTokens > self.stages[_stage].cap){
    		return false;
    	} else {
    		return true;
    	}
    }

     
    function refundParticipant(StageStorage storage self, uint256 stage1, uint256 stage2, uint256 stage3, uint256 stage4) internal {
        self.stages[1].tokensSold = self.stages[1].tokensSold.sub(stage1);
        self.stages[2].tokensSold = self.stages[2].tokensSold.sub(stage2);
        self.stages[3].tokensSold = self.stages[3].tokensSold.sub(stage3);
        self.stages[4].tokensSold = self.stages[4].tokensSold.sub(stage4);
    }
    
	 
     
    function changePrice(StageStorage storage self, uint8 _stage, uint256 _tokenPrice) internal {
        require(self.stages[_stage].deadline > now);

        self.stages[_stage].tokenPrice = _tokenPrice;
    }
}

 

 
contract PickCrowdsale is CappedCrowdsale {

  using SaleStagesLib for SaleStagesLib.StageStorage;
  using SafeMath for uint256;

  SaleStagesLib.StageStorage public stages;

  bool preallocated = false;
  bool stagesSet = false;
  address private founders;
  address private bounty;
  address private buyer;
  uint256 public burntBounty;
  uint256 public burntFounder;

  event ParticipantWithdrawal(address participant, uint256 amount, uint256 datetime);
  event StagePriceChanged(address admin, uint8 stage, uint256 price);
  event ExtendedStart(uint256 oldStart, uint256 newStart);

  modifier onlyOnce(bool _check) {
    if(_check) {
      revert();
    }
    _;
  }

  function PickCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, address _buyer, address _founders, address _bounty, uint256 _softCap, uint256 _hardCap, PickToken _token)
  	CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _beneficiary, _softCap, _hardCap, _token)
     public { 
    stages.init();
    stages.createStage(0, _startTime, 0, 0, 0);
    founders = _founders;
    bounty = _bounty;
    buyer = _buyer;
  }

  function setPreallocations() external onlyOwner onlyOnce(preallocated) {
    preallocate(buyer, 1250000, 10000000000);
    preallocate(founders, 1777777, 0);
    preallocate(bounty, 444445, 0);
    preallocated = true;
  }

  function setStages() external onlyOwner onlyOnce(stagesSet) {
    stages.createStage(1, startTime.add(1 weeks), 10000000000, 10000000, 175000000000);   
    stages.createStage(2, startTime.add(2 weeks), 11000000000, 5000000, 300000000000);  
    stages.createStage(3, startTime.add(4 weeks), 12000000000, 2500000, 575000000000);   
    stages.createStage(4, endTime, 15000000000, 1000000, 2000000000000);                
    stagesSet = true;
  }

   
   
  function createStage(uint8 _stage, uint256 _deadline, uint256 _price, uint256 _minimum, uint256 _cap ) internal onlyOwner {
    stages.createStage(_stage, _deadline, _price, _minimum, _cap);
  }

   
   
  function changePrice(uint8 _stage, uint256 _price) public onlyOwner {
    stages.changePrice(_stage, _price);
    StagePriceChanged(msg.sender, _stage, _price);
  }

   
   
  function getStage() public view returns (uint8 stage) {
    return stages.getStage();
  }

  function getStageDeadline(uint8 _stage) public view returns (uint256 deadline) { 
    return stages.stages[_stage].deadline;
  }

  function getStageTokensSold(uint8 _stage) public view returns (uint256 sold) { 
    return stages.stages[_stage].tokensSold;
  }

  function getStageCap(uint8 _stage) public view returns (uint256 cap) { 
    return stages.stages[_stage].cap;
  }

  function getStageMinimum(uint8 _stage) public view returns (uint256 min) { 
    return stages.stages[_stage].minimumBuy;
  }

  function getStagePrice(uint8 _stage) public view returns (uint256 price) { 
    return stages.stages[_stage].tokenPrice;
  }

   
  function extendStart(uint256 _newStart) external onlyOwner {
    require(_newStart > startTime);
    require(_newStart > now); 
    require(now < startTime);

    uint256 difference = _newStart - startTime;
    uint256 oldStart = startTime;
    startTime = _newStart;
    endTime = endTime + difference;

     
    for (uint8 i = 0; i < 4; i++) {
       
      uint256 temp = stages.stages[i].deadline;
      temp = temp + difference;

      stages.changeDeadline(i, temp);
    }

    ExtendedStart(oldStart, _newStart);
  }

   
   
  function tokensToRecieve(uint256 _wei) internal view returns (uint256 tokens) {
    uint8 stage = getStage();
    uint256 price = getStagePrice(stage);

    return _wei.div(price);
  }

   
   
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool isValid = false;
    uint8 stage = getStage();

    if(stages.checkMinimum(stage, _tokens) && stages.checkCap(stage, _tokens)){
      isValid = true;
    }

    return super.validPurchase(_tokens) && isValid;
  }

   
  function finalizeSale(uint256 _weiAmount, uint256 _tokens, uint128 _buyer) internal {
     
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_weiAmount);
    tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(_tokens);
    balancePerID[_buyer] = balancePerID[_buyer].add(_weiAmount);

     
    weiRaised = weiRaised.add(_weiAmount);
    tokensSent = tokensSent.add(_tokens);

    uint8 stage = getStage();
    stages.stages[stage].tokensSold = stages.stages[stage].tokensSold.add(_tokens);
  }

   
  function preallocate(address receiver, uint tokens, uint weiPrice) internal {
    uint decimals = token.decimals();
    uint tokenAmount = tokens * 10 ** decimals;
    uint weiAmount = weiPrice * tokens; 

    presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    tokensSent = tokensSent.add(tokenAmount);
    tokenBalanceOf[receiver] = tokenBalanceOf[receiver].add(tokenAmount);

    presaleBalanceOf[receiver] = presaleBalanceOf[receiver].add(weiAmount);

    produceTokens(receiver, weiAmount, tokenAmount);
  }

   
   
  function unsuccessfulWithdrawal() external {
      require(balanceOf[msg.sender] > 0);
      require(hasEnded() && tokensSent < softCap || hasHalted());
      uint256 withdrawalAmount;

      withdrawalAmount = balanceOf[msg.sender];
      balanceOf[msg.sender] = 0; 

      msg.sender.transfer(withdrawalAmount);
      assert(balanceOf[msg.sender] == 0);

      ParticipantWithdrawal(msg.sender, withdrawalAmount, now);
  }

   
   
  function burnFoundersTokens(uint256 _bounty, uint256 _founders) internal {
      require(_founders < 177777700000);
      require(_bounty < 44444500000);

       
      burntFounder = _founders;
      burntBounty = _bounty;

      token.reclaimAndBurn(founders, burntFounder);
      token.reclaimAndBurn(bounty, burntBounty);
  }
}

 

 



 
contract KYCCrowdsale is KYCPayloadDeserializer, PickCrowdsale {

   
  address public signerAddress;
  mapping(address => uint256) public refundable;
  mapping(address => bool) public refunded;
  mapping(address => bool) public blacklist;

   
  event SignerChanged(address signer);
  event TokensReclaimed(address user, uint256 amount, uint256 datetime);
  event AddedToBlacklist(address user, uint256 datetime);
  event RemovedFromBlacklist(address user, uint256 datetime);
  event RefundCollected(address user, uint256 datetime);
  event TokensReleased(address agent, uint256 datetime, uint256 bounty, uint256 founders);

   
  function KYCCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, address _buyer, address _founders, address _bounty, uint256 _softCap, uint256 _hardCap, PickToken _token) public
  PickCrowdsale(_startTime, _endTime, _rate, _wallet, _beneficiary, _buyer, _founders, _bounty, _softCap, _hardCap, _token)
  {}

   
  function setTokenAgent() external onlyOwner {
     
     
    token.setReleaseAgent();
  }

  
  function refundParticipant(address participant, uint256 _stage1, uint256 _stage2, uint256 _stage3, uint256 _stage4) external onlyOwner {
    require(balanceOf[participant] > 0);

    uint256 balance = balanceOf[participant];
    uint256 tokens = tokenBalanceOf[participant];

    balanceOf[participant] = 0;
    tokenBalanceOf[participant] = 0;

     
    refundable[participant] = balance;

     
    weiRaised = weiRaised.sub(balance);
    tokensSent = tokensSent.sub(tokens);

     
    token.reclaimAllAndBurn(participant);

     
    blacklist[participant] = true;
    AddedToBlacklist(participant, now);

    stages.refundParticipant(_stage1, _stage2, _stage3, _stage4);

    TokensReclaimed(participant, tokens, now);
  }

   
   
   
  function releaseTokens(uint256 _bounty, uint256 _founders) onlyOwner external {
       
      require(_bounty > 0 || tokensSent == hardCap);
      require(_founders > 0 || tokensSent == hardCap);

      burnFoundersTokens(_bounty, _founders);

      token.releaseTokenTransfer();

      canWithdraw = true;

      TokensReleased(msg.sender, now, _bounty, _founders);
  }
  
   
   
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool onBlackList;

    if(blacklist[msg.sender] == true){
      onBlackList = true;
    } else {
      onBlackList = false;
    }
    return super.validPurchase(_tokens) && !onBlackList;
  }

   
  function collectRefund() external {
    require(refundable[msg.sender] > 0);
    require(refunded[msg.sender] == false);

    uint256 theirwei = refundable[msg.sender];
    refundable[msg.sender] = 0;
    refunded[msg.sender] == true;

    msg.sender.transfer(theirwei);

    RefundCollected(msg.sender, now);
  }

   
  function buyWithKYCData(bytes dataframe, uint8 v, bytes32 r, bytes32 s) public payable {

      bytes32 hash = sha256(dataframe);

      address whitelistedAddress;
      uint128 customerId;
      uint32 minETH;
      uint32 maxETH;
      
      (whitelistedAddress, customerId, minETH, maxETH) = getKYCPayload(dataframe);

       
      require(ecrecover(hash, v, r, s) == signerAddress);

       
      require(whitelistedAddress == msg.sender);

       
      uint256 weiAmount = msg.value;
      uint256 max = maxETH;
      uint256 min = minETH;

      require(weiAmount < (max * 1 ether));
      require(weiAmount > (min * 1 ether));

      buyTokens(customerId);
  }  

   
   
  function setSignerAddress(address _signerAddress) external onlyOwner {
     
    require(_signerAddress != 0);
    signerAddress = _signerAddress;
    SignerChanged(signerAddress);
  }

  function removeFromBlacklist(address _blacklisted) external onlyOwner {
    require(blacklist[_blacklisted] == true);
    blacklist[_blacklisted] = false;
    RemovedFromBlacklist(_blacklisted, now);
  }

}
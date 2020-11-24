 

pragma solidity ^0.4.13;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function getOwner() returns(address){
    return owner;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

     
    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

 

contract ValidationUtil {
    function requireNotEmptyAddress(address value) internal{
        require(isAddressValid(value));
    }

    function isAddressValid(address value) internal constant returns (bool result){
        return value != 0;
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
   
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
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

 
contract BurnableToken is StandardToken, Ownable, ValidationUtil {
    using SafeMath for uint;

    address public tokenOwnerBurner;

     
    event Burned(address burner, uint burnedAmount);

    function setOwnerBurner(address _tokenOwnerBurner) public onlyOwner invalidOwnerBurner{
         
        requireNotEmptyAddress(_tokenOwnerBurner);

        tokenOwnerBurner = _tokenOwnerBurner;
    }

     
    function burnOwnerTokens(uint burnAmount) public onlyTokenOwnerBurner validOwnerBurner{
        burnTokens(tokenOwnerBurner, burnAmount);
    }

     
    function burnTokens(address _address, uint burnAmount) public onlyTokenOwnerBurner validOwnerBurner{
        balances[_address] = balances[_address].sub(burnAmount);

         
        Burned(_address, burnAmount);
    }

     
    function burnAllOwnerTokens() public onlyTokenOwnerBurner validOwnerBurner{
        uint burnAmount = balances[tokenOwnerBurner];
        burnTokens(tokenOwnerBurner, burnAmount);
    }

     
    modifier onlyTokenOwnerBurner() {
        require(msg.sender == tokenOwnerBurner);

        _;
    }

    modifier validOwnerBurner() {
         
        requireNotEmptyAddress(tokenOwnerBurner);

        _;
    }

    modifier invalidOwnerBurner() {
         
        require(!isAddressValid(tokenOwnerBurner));

        _;
    }
}

 

contract CrowdsaleToken is StandardToken, Ownable {

     
    string public name;

    string public symbol;

    uint public decimals;

    address public mintAgent;

     
    event UpdatedTokenInformation(string newName, string newSymbol);

     
    event TokenMinted(uint amount, address toAddress);

     
    function CrowdsaleToken(string _name, string _symbol, uint _decimals) {
        owner = msg.sender;

        name = _name;
        symbol = _symbol;

        decimals = _decimals;
    }

     
    function mintToAddress(uint amount, address toAddress) onlyMintAgent{
         
        balances[toAddress] = amount;

         
        TokenMinted(amount, toAddress);
    }

     
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name;
        symbol = _symbol;

         
        UpdatedTokenInformation(name, symbol);
    }

     
    function setMintAgent(address _address) onlyOwner {
        mintAgent =  _address;
    }

    modifier onlyMintAgent(){
        require(msg.sender == mintAgent);

        _;
    }
}

 
contract BurnableCrowdsaleToken is BurnableToken, CrowdsaleToken {

    function BurnableCrowdsaleToken(string _name, string _symbol, uint _decimals) CrowdsaleToken(_name, _symbol, _decimals) BurnableToken(){

    }
}

 

 

contract AllocatedCappedCrowdsale is Haltable, ValidationUtil {
    using SafeMath for uint;

     
    uint public advisorsTokenAmount = 8040817;
    uint public supportTokenAmount = 3446064;
    uint public marketingTokenAmount = 3446064;
    uint public teamTokenAmount = 45947521;

    uint public teamTokensIssueDate;

     
    BurnableCrowdsaleToken public token;

     
    address public destinationMultisigWallet;

     
    uint public firstStageStartsAt;
     
    uint public firstStageEndsAt;

     
    uint public secondStageStartsAt;
     
    uint public secondStageEndsAt;

     
    uint public softCapFundingGoalInCents = 392000000;

     
    uint public hardCapFundingGoalInCents = 985000000;

     
    uint public weiRaised;

     
    uint public firstStageRaisedInWei;

     
    uint public secondStageRaisedInWei;

     
    uint public investorCount;

     
    uint public weiRefunded;

     
    uint public tokensSold;

     
    bool public isFirstStageFinalized;

     
    bool public isSecondStageFinalized;

     
    bool public isSuccessOver;

     
    bool public isRefundingEnabled;

     
    uint public currentEtherRateInCents;

     
    uint public oneTokenInCents = 7;

     
    bool public isFirstStageTokensMinted;

     
    bool public isSecondStageTokensMinted;

     
    uint public firstStageTotalSupply = 112000000;

     
    uint public firstStageTokensSold;

     
    uint public secondStageTotalSupply = 229737610;

     
    uint public secondStageTokensSold;

     
    uint public secondStageReserve = 60880466;

     
    uint public secondStageTokensForSale;

     
    mapping (address => uint) public tokenAmountOf;

     
    mapping (address => uint) public investedAmountOf;

     
    address public advisorsAccount;
    address public marketingAccount;
    address public supportAccount;
    address public teamAccount;

     
    enum State{PreFunding, FirstStageFunding, FirstStageEnd, SecondStageFunding, SecondStageEnd, Success, Failure, Refunding}

     
    event Invested(address indexed investor, uint weiAmount, uint tokenAmount, uint centAmount, uint txId);

     
    event ExchangeRateChanged(uint oldExchangeRate, uint newExchangeRate);

     
    event FirstStageStartsAtChanged(uint newFirstStageStartsAt);
    event FirstStageEndsAtChanged(uint newFirstStageEndsAt);

     
    event SecondStageStartsAtChanged(uint newSecondStageStartsAt);
    event SecondStageEndsAtChanged(uint newSecondStageEndsAt);

     
    event SoftCapChanged(uint newGoal);

     
    event HardCapChanged(uint newGoal);

     
    function AllocatedCappedCrowdsale(uint _currentEtherRateInCents, address _token, address _destinationMultisigWallet, uint _firstStageStartsAt, uint _firstStageEndsAt, uint _secondStageStartsAt, uint _secondStageEndsAt, address _advisorsAccount, address _marketingAccount, address _supportAccount, address _teamAccount, uint _teamTokensIssueDate) {
        requireNotEmptyAddress(_destinationMultisigWallet);
         
        require(_firstStageStartsAt != 0);
        require(_firstStageEndsAt != 0);

        require(_firstStageStartsAt < _firstStageEndsAt);

        require(_secondStageStartsAt != 0);
        require(_secondStageEndsAt != 0);

        require(_secondStageStartsAt < _secondStageEndsAt);
        require(_teamTokensIssueDate != 0);

         
        token = BurnableCrowdsaleToken(_token);

        destinationMultisigWallet = _destinationMultisigWallet;

        firstStageStartsAt = _firstStageStartsAt;
        firstStageEndsAt = _firstStageEndsAt;
        secondStageStartsAt = _secondStageStartsAt;
        secondStageEndsAt = _secondStageEndsAt;

         
        advisorsAccount = _advisorsAccount;
        marketingAccount = _marketingAccount;
        supportAccount = _supportAccount;
        teamAccount = _teamAccount;

        teamTokensIssueDate = _teamTokensIssueDate;

        currentEtherRateInCents = _currentEtherRateInCents;

        secondStageTokensForSale = secondStageTotalSupply.sub(secondStageReserve);
    }

     
    function mintTokensForFirstStage() public onlyOwner {
         
        require(!isFirstStageTokensMinted);

        uint tokenMultiplier = 10 ** token.decimals();

        token.mintToAddress(firstStageTotalSupply.mul(tokenMultiplier), address(this));

        isFirstStageTokensMinted = true;
    }

     
    function mintTokensForSecondStage() private {
         
        require(!isSecondStageTokensMinted);

        require(isFirstStageTokensMinted);

        uint tokenMultiplier = 10 ** token.decimals();

        token.mintToAddress(secondStageTotalSupply.mul(tokenMultiplier), address(this));

        isSecondStageTokensMinted = true;
    }

     
    function getOneTokenInWei() external constant returns(uint){
        return oneTokenInCents.mul(10 ** 18).div(currentEtherRateInCents);
    }

     
    function getWeiInCents(uint value) public constant returns(uint){
        return currentEtherRateInCents.mul(value).div(10 ** 18);
    }

     
    function assignTokens(address receiver, uint tokenAmount) private {
         
        if (!token.transfer(receiver, tokenAmount)) revert();
    }

     
    function() payable {
        buy();
    }

     
    function internalAssignTokens(address receiver, uint tokenAmount, uint weiAmount, uint centAmount, uint txId) internal {
         
        assignTokens(receiver, tokenAmount);

         
        Invested(receiver, weiAmount, tokenAmount, centAmount, txId);

         
    }

     
    function internalInvest(address receiver, uint weiAmount, uint txId) stopInEmergency inFirstOrSecondFundingState notHardCapReached internal {
        State currentState = getState();

        uint tokenMultiplier = 10 ** token.decimals();

        uint amountInCents = getWeiInCents(weiAmount);

         
        uint bonusPercentage = 0;
        uint bonusStateMultiplier = 1;

         
        if (currentState == State.FirstStageFunding){
             
            require(amountInCents >= 2500000);

             
            if (amountInCents >= 2500000 && amountInCents < 5000000){
                bonusPercentage = 50;
             
            }else if(amountInCents >= 5000000 && amountInCents < 10000000){
                bonusPercentage = 75;
             
            }else if(amountInCents >= 10000000){
                bonusPercentage = 100;
            }else{
                revert();
            }

         
        } else if(currentState == State.SecondStageFunding){
             
            bonusStateMultiplier = 10;

             
            uint tokensSoldPercentage = secondStageTokensSold.mul(100).div(secondStageTokensForSale.mul(tokenMultiplier));

             
            require(amountInCents >= 700);

             
            if (tokensSoldPercentage >= 0 && tokensSoldPercentage < 10){
                bonusPercentage = 200;
             
            }else if (tokensSoldPercentage >= 10 && tokensSoldPercentage < 20){
                bonusPercentage = 175;
             
            }else if (tokensSoldPercentage >= 20 && tokensSoldPercentage < 30){
                bonusPercentage = 150;
             
            }else if (tokensSoldPercentage >= 30 && tokensSoldPercentage < 40){
                bonusPercentage = 125;
             
            }else if (tokensSoldPercentage >= 40 && tokensSoldPercentage < 50){
                bonusPercentage = 100;
             
            }else if (tokensSoldPercentage >= 50 && tokensSoldPercentage < 60){
                bonusPercentage = 80;
             
            }else if (tokensSoldPercentage >= 60 && tokensSoldPercentage < 70){
                bonusPercentage = 60;
             
            }else if (tokensSoldPercentage >= 70 && tokensSoldPercentage < 80){
                bonusPercentage = 40;
             
            }else if (tokensSoldPercentage >= 80 && tokensSoldPercentage < 90){
                bonusPercentage = 20;
             
            }else if (tokensSoldPercentage >= 90){
                bonusPercentage = 0;
            }else{
                revert();
            }
        } else revert();

         
        uint resultValue = amountInCents.mul(tokenMultiplier).div(oneTokenInCents);

         
        uint tokenAmount = resultValue.mul(bonusStateMultiplier.mul(100).add(bonusPercentage)).div(bonusStateMultiplier.mul(100));

         
        uint tokensLeft = getTokensLeftForSale(currentState);
        if (tokenAmount > tokensLeft){
            tokenAmount = tokensLeft;
        }

         
        require(tokenAmount != 0);

         
        if (investedAmountOf[receiver] == 0) {
            investorCount++;
        }

         
        internalAssignTokens(receiver, tokenAmount, weiAmount, amountInCents, txId);

         
        updateStat(currentState, receiver, tokenAmount, weiAmount);

         
         
         
        if (txId == 0){
            internalDeposit(destinationMultisigWallet, weiAmount);
        }

         
    }

     
    function internalDeposit(address receiver, uint weiAmount) internal{
         
    }

     
    function internalRefund(address receiver, uint weiAmount) internal{
         
    }

     
    function internalEnableRefunds() internal{
         
    }

     
    function internalPreallocate(State currentState, address receiver, uint tokenAmount, uint weiAmount) internal {
         
        require(getTokensLeftForSale(currentState) >= tokenAmount);

         
        internalAssignTokens(receiver, tokenAmount, weiAmount, getWeiInCents(weiAmount), 0);

         
        updateStat(currentState, receiver, tokenAmount, weiAmount);

         
    }

     
    function internalSuccessOver() internal {
         
    }

     
    function internalSetDestinationMultisigWallet(address destinationAddress) internal{
    }

     
    function updateStat(State currentState, address receiver, uint tokenAmount, uint weiAmount) private{
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

         
        if (currentState == State.FirstStageFunding){
             
            firstStageRaisedInWei = firstStageRaisedInWei.add(weiAmount);
            firstStageTokensSold = firstStageTokensSold.add(tokenAmount);
        }

         
        if (currentState == State.SecondStageFunding){
             
            secondStageRaisedInWei = secondStageRaisedInWei.add(weiAmount);
            secondStageTokensSold = secondStageTokensSold.add(tokenAmount);
        }

        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
    }

     
    function setDestinationMultisigWallet(address destinationAddress) public onlyOwner canSetDestinationMultisigWallet{
        destinationMultisigWallet = destinationAddress;

        internalSetDestinationMultisigWallet(destinationAddress);
    }

     
    function changeCurrentEtherRateInCents(uint value) public onlyOwner {
         
        require(value > 0);

        currentEtherRateInCents = value;

        ExchangeRateChanged(currentEtherRateInCents, value);
    }

     

     
    function preallocateFirstStage(address receiver, uint tokenAmount, uint weiAmount) public onlyOwner isFirstStageFundingOrEnd {
        internalPreallocate(State.FirstStageFunding, receiver, tokenAmount, weiAmount);
    }

     
    function preallocateSecondStage(address receiver, uint tokenAmount, uint weiAmount) public onlyOwner isSecondStageFundingOrEnd {
        internalPreallocate(State.SecondStageFunding, receiver, tokenAmount, weiAmount);
    }

     
    function issueTeamTokens() public onlyOwner inState(State.Success) {
        require(block.timestamp >= teamTokensIssueDate);

        uint teamTokenTransferAmount = teamTokenAmount.mul(10 ** token.decimals());

        if (!token.transfer(teamAccount, teamTokenTransferAmount)) revert();
    }

     
    function enableRefunds() public onlyOwner canEnableRefunds{
        isRefundingEnabled = true;

         
        token.burnAllOwnerTokens();

        internalEnableRefunds();
    }

     
    function buy() public payable {
        internalInvest(msg.sender, msg.value, 0);
    }

     
    function externalBuy(address buyerAddress, uint weiAmount, uint txId) external onlyOwner {
        require(txId != 0);

        internalInvest(buyerAddress, weiAmount, txId);
    }

     
    function refund() public inState(State.Refunding) {
         
        uint weiValue = investedAmountOf[msg.sender];

        require(weiValue != 0);

         
         
         
        uint saleContractTokenCount = tokenAmountOf[msg.sender];
        uint tokenContractTokenCount = token.balanceOf(msg.sender);

        require(saleContractTokenCount <= tokenContractTokenCount);

        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);

         
        internalRefund(msg.sender, weiValue);
    }

     
    function finalizeFirstStage() public onlyOwner isNotSuccessOver {
        require(!isFirstStageFinalized);

         
         
         
         

        token.burnAllOwnerTokens();

         
         
        mintTokensForSecondStage();

        isFirstStageFinalized = true;
    }

     
    function finalizeSecondStage() public onlyOwner isNotSuccessOver {
        require(isFirstStageFinalized && !isSecondStageFinalized);

         
         
         
         

         
        if (isSoftCapGoalReached()){
            uint tokenMultiplier = 10 ** token.decimals();

            uint remainingTokens = secondStageTokensForSale.mul(tokenMultiplier).sub(secondStageTokensSold);

             
            if (remainingTokens > 0){
                token.burnOwnerTokens(remainingTokens);
            }

             
            uint advisorsTokenTransferAmount = advisorsTokenAmount.mul(tokenMultiplier);
            uint marketingTokenTransferAmount = marketingTokenAmount.mul(tokenMultiplier);
            uint supportTokenTransferAmount = supportTokenAmount.mul(tokenMultiplier);

             
             

            if (!token.transfer(advisorsAccount, advisorsTokenTransferAmount)) revert();
            if (!token.transfer(marketingAccount, marketingTokenTransferAmount)) revert();
            if (!token.transfer(supportAccount, supportTokenTransferAmount)) revert();

             
            isSuccessOver = true;

             
            internalSuccessOver();
        }else{
             
            token.burnAllOwnerTokens();
        }

        isSecondStageFinalized = true;
    }

     
    function setFirstStageStartsAt(uint time) public onlyOwner {
        firstStageStartsAt = time;

         
        FirstStageStartsAtChanged(firstStageStartsAt);
    }

    function setFirstStageEndsAt(uint time) public onlyOwner {
        firstStageEndsAt = time;

         
        FirstStageEndsAtChanged(firstStageEndsAt);
    }

    function setSecondStageStartsAt(uint time) public onlyOwner {
        secondStageStartsAt = time;

         
        SecondStageStartsAtChanged(secondStageStartsAt);
    }

    function setSecondStageEndsAt(uint time) public onlyOwner {
        secondStageEndsAt = time;

         
        SecondStageEndsAtChanged(secondStageEndsAt);
    }

     
    function setSoftCapInCents(uint value) public onlyOwner {
        require(value > 0);

        softCapFundingGoalInCents = value;

         
        SoftCapChanged(softCapFundingGoalInCents);
    }

    function setHardCapInCents(uint value) public onlyOwner {
        require(value > 0);

        hardCapFundingGoalInCents = value;

         
        HardCapChanged(hardCapFundingGoalInCents);
    }

     
    function isSoftCapGoalReached() public constant returns (bool) {
         
        return getWeiInCents(weiRaised) >= softCapFundingGoalInCents;
    }

     
    function isHardCapGoalReached() public constant returns (bool) {
         
        return getWeiInCents(weiRaised) >= hardCapFundingGoalInCents;
    }

     
    function getTokensLeftForSale(State forState) public constant returns (uint) {
         
        uint tokenBalance = token.balanceOf(address(this));
        uint tokensReserve = 0;
        if (forState == State.SecondStageFunding) tokensReserve = secondStageReserve.mul(10 ** token.decimals());

        if (tokenBalance <= tokensReserve){
            return 0;
        }

        return tokenBalance.sub(tokensReserve);
    }

     
    function getState() public constant returns (State) {
         
        if (isSuccessOver) return State.Success;

         
        if (isRefundingEnabled) return State.Refunding;

         
        if (block.timestamp < firstStageStartsAt) return State.PreFunding;

         
        if (!isFirstStageFinalized){
             
            bool isFirstStageTime = block.timestamp >= firstStageStartsAt && block.timestamp <= firstStageEndsAt;

             
            if (isFirstStageTime) return State.FirstStageFunding;
             
            else return State.FirstStageEnd;

        } else {

             
            if(block.timestamp < secondStageStartsAt)return State.FirstStageEnd;

             
            bool isSecondStageTime = block.timestamp >= secondStageStartsAt && block.timestamp <= secondStageEndsAt;

             
            if (isSecondStageFinalized){

                 
                if (isSoftCapGoalReached())return State.Success;
                 
                else return State.Failure;

            }else{

                 
                if (isSecondStageTime)return State.SecondStageFunding;
                 
                else return State.SecondStageEnd;

            }
        }
    }

    

     
    modifier inState(State state) {
        require(getState() == state);

        _;
    }

     
    modifier inFirstOrSecondFundingState() {
        State curState = getState();
        require(curState == State.FirstStageFunding || curState == State.SecondStageFunding);

        _;
    }

     
    modifier notHardCapReached(){
        require(!isHardCapGoalReached());

        _;
    }

     
    modifier isFirstStageFundingOrEnd() {
        State curState = getState();
        require(curState == State.FirstStageFunding || curState == State.FirstStageEnd);

        _;
    }

     
    modifier isNotSuccessOver() {
        require(!isSuccessOver);

        _;
    }

     
    modifier isSecondStageFundingOrEnd() {
        State curState = getState();
        require(curState == State.SecondStageFunding || curState == State.SecondStageEnd);

        _;
    }

     
    modifier canEnableRefunds(){
        require(!isRefundingEnabled && getState() != State.Success);

        _;
    }

     
    modifier canSetDestinationMultisigWallet(){
        require(getState() != State.Success);

        _;
    }
}

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
contract FundsVault is Ownable, ValidationUtil {
    using SafeMath for uint;
    using Math for uint;

    enum State {Active, Refunding, Closed}

    mapping (address => uint256) public deposited;

    address public wallet;

    State public state;

    event Closed();

    event RefundsEnabled();

    event Refunded(address indexed beneficiary, uint256 weiAmount);

     
    function FundsVault(address _wallet) {
        requireNotEmptyAddress(_wallet);

        wallet = _wallet;

        state = State.Active;
    }

     
    function deposit(address investor) public payable onlyOwner inState(State.Active) {
        deposited[investor] = deposited[investor].add(msg.value);
    }

     
    function close() public onlyOwner inState(State.Active) {
        state = State.Closed;

        Closed();

        wallet.transfer(this.balance);
    }

     
    function setWallet(address newWalletAddress) public onlyOwner inState(State.Active) {
        wallet = newWalletAddress;
    }

     
    function enableRefunds() public onlyOwner inState(State.Active) {
        state = State.Refunding;

        RefundsEnabled();
    }

     
    function refund(address investor, uint weiAmount) public onlyOwner inState(State.Refunding){
        uint256 depositedValue = weiAmount.min256(deposited[investor]);
        deposited[investor] = 0;
        investor.transfer(depositedValue);

        Refunded(investor, depositedValue);
    }

     
    modifier inState(State _state) {
        require(state == _state);

        _;
    }

}

 
contract RefundableAllocatedCappedCrowdsale is AllocatedCappedCrowdsale {

     
    FundsVault public fundsVault;

     
    mapping (address => bool) public refundedInvestors;

    function RefundableAllocatedCappedCrowdsale(uint _currentEtherRateInCents, address _token, address _destinationMultisigWallet, uint _firstStageStartsAt, uint _firstStageEndsAt, uint _secondStageStartsAt, uint _secondStageEndsAt, address _advisorsAccount, address _marketingAccount, address _supportAccount, address _teamAccount, uint _teamTokensIssueDate) AllocatedCappedCrowdsale(_currentEtherRateInCents, _token, _destinationMultisigWallet, _firstStageStartsAt, _firstStageEndsAt, _secondStageStartsAt, _secondStageEndsAt, _advisorsAccount, _marketingAccount, _supportAccount, _teamAccount, _teamTokensIssueDate) {
         
         
         
        fundsVault = new FundsVault(_destinationMultisigWallet);

    }

     
    function internalSetDestinationMultisigWallet(address destinationAddress) internal{
        fundsVault.setWallet(destinationAddress);

        super.internalSetDestinationMultisigWallet(destinationAddress);
    }

     
    function internalSuccessOver() internal {
         
        fundsVault.close();

        super.internalSuccessOver();
    }

     
    function internalDeposit(address receiver, uint weiAmount) internal{
         
        fundsVault.deposit.value(weiAmount)(msg.sender);
    }

     
    function internalEnableRefunds() internal{
        super.internalEnableRefunds();

        fundsVault.enableRefunds();
    }

     
    function internalRefund(address receiver, uint weiAmount) internal{
         
         

        if (refundedInvestors[receiver]) revert();

        fundsVault.refund(receiver, weiAmount);

        refundedInvestors[receiver] = true;
    }

}
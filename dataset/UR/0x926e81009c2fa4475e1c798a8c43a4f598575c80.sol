 

pragma solidity ^0.4.16;

contract SafeMath {
     function safeMul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}

 
 
contract Token is SafeMath {
      
      
     function totalSupply() constant returns (uint256 supply) {}

      
      
     function balanceOf(address _owner) constant returns (uint256 balance) {}

      
      
      
     function transfer(address _to, uint256 _value) returns(bool) {}

      
      
      
      
      
     function transferFrom(address _from, address _to, uint256 _value)returns(bool){}

      
      
      
      
     function approve(address _spender, uint256 _value) returns (bool success) {}

      
      
      
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

      
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StdToken is Token {
      
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public totalSupply = 0;

      
     function transfer(address _to, uint256 _value) returns(bool){
          require(balances[msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[msg.sender] = safeSub(balances[msg.sender],_value);
          balances[_to] = safeAdd(balances[_to],_value);

          Transfer(msg.sender, _to, _value);
          return true;
     }

     function transferFrom(address _from, address _to, uint256 _value) returns(bool){
          require(balances[_from] >= _value);
          require(allowed[_from][msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[_to] = safeAdd(balances[_to],_value);
          balances[_from] = safeSub(balances[_from],_value);
          allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

          Transfer(_from, _to, _value);
          return true;
     }

     function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
     }

     modifier onlyPayloadSize(uint _size) {
          require(msg.data.length >= _size + 4);
          _;
     }
}

contract MNTP is StdToken {
 
     string public constant name = "Goldmint MNT Prelaunch Token";
     string public constant symbol = "MNTP";
     uint public constant decimals = 18;

     address public creator = 0x0;
     address public icoContractAddress = 0x0;
     bool public lockTransfers = false;

      
     uint public constant TOTAL_TOKEN_SUPPLY = 10000000 * (1 ether / 1 wei);

 
     modifier onlyCreator() { 
          require(msg.sender == creator); 
          _; 
     }

     modifier byCreatorOrIcoContract() { 
          require((msg.sender == creator) || (msg.sender == icoContractAddress)); 
          _; 
     }

     function setCreator(address _creator) onlyCreator {
          creator = _creator;
     }

 
     function setIcoContractAddress(address _icoContractAddress) onlyCreator {
          icoContractAddress = _icoContractAddress;
     }

 
      
     function MNTP() {
          creator = msg.sender;

           
          assert(TOTAL_TOKEN_SUPPLY == (10000000 * (1 ether / 1 wei)));
     }

      
     function transfer(address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transfer(_to,_value);
     }

      
     function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transferFrom(_from,_to,_value);
     }

     function issueTokens(address _who, uint _tokens) byCreatorOrIcoContract {
          require((totalSupply + _tokens) <= TOTAL_TOKEN_SUPPLY);

          balances[_who] = safeAdd(balances[_who],_tokens);
          totalSupply = safeAdd(totalSupply,_tokens);
     }

     function burnTokens(address _who, uint _tokens) byCreatorOrIcoContract {
          balances[_who] = safeSub(balances[_who], _tokens);
          totalSupply = safeSub(totalSupply, _tokens);
     }

     function lockTransfer(bool _lock) byCreatorOrIcoContract {
          lockTransfers = _lock;
     }

      
     function() {
          revert();
     }
}

 
 
contract GoldmintUnsold is SafeMath {
     address public creator;
     address public teamAccountAddress;
     address public icoContractAddress;
     uint64 public icoIsFinishedDate;

     MNTP public mntToken;

     function GoldmintUnsold(address _teamAccountAddress,address _mntTokenAddress){
          creator = msg.sender;
          teamAccountAddress = _teamAccountAddress;

          mntToken = MNTP(_mntTokenAddress);          
     }

     modifier onlyCreator() { 
          require(msg.sender==creator); 
          _; 
     }

     modifier onlyIcoContract() { 
          require(msg.sender==icoContractAddress); 
          _; 
     }

 
     function setIcoContractAddress(address _icoContractAddress) onlyCreator {
          icoContractAddress = _icoContractAddress;
     }

      
     function finishIco() public onlyIcoContract {
          icoIsFinishedDate = uint64(now);
     }

      
     function withdrawTokens() public {
           
          uint64 oneYearPassed = icoIsFinishedDate + 365 days;  
          require(uint(now) >= oneYearPassed);

           
          uint total = mntToken.balanceOf(this);
          mntToken.transfer(teamAccountAddress,total);
     }

      
     function() payable {
          revert();
     }
}

contract FoundersVesting is SafeMath {
     address public teamAccountAddress;
     uint64 public lastWithdrawTime;

     uint public withdrawsCount = 0;
     uint public amountToSend = 0;

     MNTP public mntToken;

     function FoundersVesting(address _teamAccountAddress,address _mntTokenAddress){
          teamAccountAddress = _teamAccountAddress;
          lastWithdrawTime = uint64(now);

          mntToken = MNTP(_mntTokenAddress);          
     }

      
     function withdrawTokens() public {
           
          uint64 oneMonth = lastWithdrawTime + 30 days;  
          require(uint(now) >= oneMonth);

           
          if(withdrawsCount==0){
               amountToSend = mntToken.balanceOf(this) / 10;
          }

          require(amountToSend!=0);

           
          uint currentBalance = mntToken.balanceOf(this);
          if(currentBalance<amountToSend){
             amountToSend = currentBalance;  
          }
          mntToken.transfer(teamAccountAddress,amountToSend);

           
          withdrawsCount++;
          lastWithdrawTime = uint64(now);
     }

      
     function() payable {
          require(false);
     }
}

contract Goldmint is SafeMath {
     address public creator = 0x0;
     address public tokenManager = 0x0;
     address public multisigAddress = 0x0;
     address public otherCurrenciesChecker = 0x0;

     uint64 public icoStartedTime = 0;

     MNTP public mntToken; 
     GoldmintUnsold public unsoldContract;

     struct TokenBuyer {
          uint weiSent;
          uint tokensGot;
     }
     mapping(address => TokenBuyer) buyers;

      
     uint constant STD_PRICE_USD_PER_1000_TOKENS = 7000;
      
     uint constant ETH_PRICE_IN_USD = 300;
      
      

      
     uint public constant SINGLE_BLOCK_LEN = 100;

 
      
     uint public constant BONUS_REWARD = 1000000 * (1 ether/ 1 wei);
      
     uint public constant FOUNDERS_REWARD = 2000000 * (1 ether / 1 wei);
      
      

      
      
     uint public constant ICO_TOKEN_SUPPLY_LIMIT = 150 * (1 ether / 1 wei); 

      
     uint public constant ICO_TOKEN_SOFT_CAP = 150000 * (1 ether / 1 wei);
     
      
     uint public icoTokensSold = 0;
      
     uint public icoTokensUnsold = 0;

      
     uint public issuedExternallyTokens = 0;

     bool public foundersRewardsMinted = false;
     bool public restTokensMoved = false;

      
     address public foundersRewardsAccount = 0x0;

     enum State{
          Init,

          ICORunning,
          ICOPaused,
         
          ICOFinished,

          Refunding
     }
     State public currentState = State.Init;

 
     modifier onlyCreator() { 
          require(msg.sender==creator); 
          _; 
     }
     modifier onlyTokenManager() { 
          require(msg.sender==tokenManager); 
          _; 
     }
     modifier onlyOtherCurrenciesChecker() { 
          require(msg.sender==otherCurrenciesChecker); 
          _; 
     }
     modifier onlyInState(State state){ 
          require(state==currentState); 
          _; 
     }

 
     event LogStateSwitch(State newState);
     event LogBuy(address indexed owner, uint value);
     event LogBurn(address indexed owner, uint value);
     
 
      
     function Goldmint(
          address _multisigAddress,
          address _tokenManager,
          address _otherCurrenciesChecker,

          address _mntTokenAddress,
          address _unsoldContractAddress,
          address _foundersVestingAddress)
     {
          creator = msg.sender;

          multisigAddress = _multisigAddress;
          tokenManager = _tokenManager;
          otherCurrenciesChecker = _otherCurrenciesChecker; 

          mntToken = MNTP(_mntTokenAddress);
          unsoldContract = GoldmintUnsold(_unsoldContractAddress);

           
          foundersRewardsAccount = _foundersVestingAddress;
     }

      
      
     function startICO() internal onlyCreator {
          mintFoundersRewards(foundersRewardsAccount);

          mntToken.lockTransfer(true);

          if(icoStartedTime==0){
               icoStartedTime = uint64(now);
          }
     }

     function pauseICO() internal onlyCreator {
     }

     function startRefunding() internal onlyCreator {
           
          require(icoTokensSold<ICO_TOKEN_SOFT_CAP);

           
          assert(mntToken.lockTransfers());
     }

      
      
     function finishICO() internal {
          mntToken.lockTransfer(false);

          if(!restTokensMoved){
               restTokensMoved = true;

                
               icoTokensUnsold = safeSub(ICO_TOKEN_SUPPLY_LIMIT,icoTokensSold);
               if(icoTokensUnsold>0){
                    mntToken.issueTokens(unsoldContract,icoTokensUnsold);
                    unsoldContract.finishIco();
               }
          }

           
          if(this.balance>0){
               multisigAddress.transfer(this.balance);
          }
     }

     function mintFoundersRewards(address _whereToMint) internal onlyCreator {
          if(!foundersRewardsMinted){
               foundersRewardsMinted = true;
               mntToken.issueTokens(_whereToMint,FOUNDERS_REWARD);
          }
     }

 
     function setTokenManager(address _new) public onlyTokenManager {
          tokenManager = _new;
     }

     function setOtherCurrenciesChecker(address _new) public onlyCreator {
          otherCurrenciesChecker = _new;
     }

     function getTokensIcoSold() constant public returns (uint){
          return icoTokensSold;
     }

     function getTotalIcoTokens() constant public returns (uint){
          return ICO_TOKEN_SUPPLY_LIMIT;
     }

     function getMntTokenBalance(address _of) constant public returns (uint){
          return mntToken.balanceOf(_of);
     }

     function getCurrentPrice()constant public returns (uint){
          return getMntTokensPerEth(icoTokensSold);
     }

     function getBlockLength()constant public returns (uint){
          return SINGLE_BLOCK_LEN;
     }

 
     function isIcoFinished() public returns(bool){
          if(icoStartedTime==0){return false;}          

           
          uint64 oneMonth = icoStartedTime + 30 days;  
          if(uint(now) > oneMonth){return true;}

           
          if(icoTokensSold>=ICO_TOKEN_SUPPLY_LIMIT){
               return true;
          }

          return false;
     }

     function setState(State _nextState) public {
           
           
          bool icoShouldBeFinished = isIcoFinished();
          bool allow = (msg.sender==creator) || (icoShouldBeFinished && (State.ICOFinished==_nextState));
          require(allow);

          bool canSwitchState
               =  (currentState == State.Init && _nextState == State.ICORunning)
               || (currentState == State.ICORunning && _nextState == State.ICOPaused)
               || (currentState == State.ICOPaused && _nextState == State.ICORunning)
               || (currentState == State.ICORunning && _nextState == State.ICOFinished)
               || (currentState == State.ICORunning && _nextState == State.Refunding);

          require(canSwitchState);

          currentState = _nextState;
          LogStateSwitch(_nextState);

          if(currentState==State.ICORunning){
               startICO();
          }else if(currentState==State.ICOFinished){
               finishICO();
          }else if(currentState==State.ICOPaused){
               pauseICO();
          }else if(currentState==State.Refunding){
               startRefunding();
          }
     }

     function getMntTokensPerEth(uint tokensSold) public constant returns (uint){
           
          uint priceIndex = (tokensSold / (1 ether/ 1 wei)) / SINGLE_BLOCK_LEN;
          assert(priceIndex>=0 && (priceIndex<=9));
          
          uint8[10] memory discountPercents = [20,15,10,8,6,4,2,0,0,0];

           
           
          uint pricePer1000tokensUsd = 
               ((STD_PRICE_USD_PER_1000_TOKENS * 100) * (1 ether / 1 wei)) / (100 + discountPercents[priceIndex]);

           
           
          uint mntPerEth = (ETH_PRICE_IN_USD * 1000 * (1 ether / 1 wei) * (1 ether / 1 wei)) / pricePer1000tokensUsd;
          return mntPerEth;
     }

     function buyTokens(address _buyer) public payable onlyInState(State.ICORunning) {
          require(msg.value!=0);

           
           
           
           
           
          uint newTokens = (msg.value * getMntTokensPerEth(icoTokensSold)) / (1 ether / 1 wei);

          issueTokensInternal(_buyer,newTokens);

           
           
          TokenBuyer memory b = buyers[msg.sender];
          b.weiSent = safeAdd(b.weiSent, msg.value);
          b.tokensGot = safeAdd(b.tokensGot, newTokens);
          buyers[msg.sender] = b;
     }

      
     function issueTokensFromOtherCurrency(address _to, uint _wei_count) onlyInState(State.ICORunning) public onlyOtherCurrenciesChecker {
          require(_wei_count!=0);

          uint newTokens = (_wei_count * getMntTokensPerEth(icoTokensSold)) / (1 ether / 1 wei);
          issueTokensInternal(_to,newTokens);
     }

      
      
     function issueTokensExternal(address _to, uint _tokens) public onlyInState(State.ICOFinished) onlyTokenManager {
           
          require((issuedExternallyTokens + _tokens)<=BONUS_REWARD);

          mntToken.issueTokens(_to,_tokens);

          issuedExternallyTokens = issuedExternallyTokens + _tokens;
     }

     function issueTokensInternal(address _to, uint _tokens) internal {
          require((icoTokensSold + _tokens)<=ICO_TOKEN_SUPPLY_LIMIT);

          mntToken.issueTokens(_to,_tokens);

          icoTokensSold+=_tokens;

          LogBuy(_to,_tokens);
     }

     function burnTokens(address _from, uint _tokens) public onlyInState(State.ICOFinished) onlyTokenManager {
          mntToken.burnTokens(_from,_tokens);

          LogBurn(_from,_tokens);
     }

      
     function getMyRefund() public onlyInState(State.Refunding) {
          address sender = msg.sender;

          require(0!=buyers[sender].weiSent);
          require(0!=buyers[sender].tokensGot);

           
          sender.transfer(buyers[sender].weiSent);

           
          mntToken.burnTokens(sender,buyers[sender].tokensGot);
     }

      
     function() payable {
           
          buyTokens(msg.sender);
     }
}
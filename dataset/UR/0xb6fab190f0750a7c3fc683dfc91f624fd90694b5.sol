 

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

 
 
contract StdToken is SafeMath {
 
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public totalSupply = 0;

 
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 
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

     function balanceOf(address _owner) constant returns (uint256) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) returns (bool) {
           
           
           
           
          require((_value == 0) || (allowed[msg.sender][_spender] == 0));

          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256) {
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

      
     uint public constant TOTAL_TOKEN_SUPPLY = 10000000 * 1 ether;

 
     modifier onlyCreator() { 
          require(msg.sender == creator); 
          _; 
     }

     modifier byIcoContract() { 
          require(msg.sender == icoContractAddress); 
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

          assert(TOTAL_TOKEN_SUPPLY == 10000000 * 1 ether);
     }

      
     function transfer(address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transfer(_to,_value);
     }

      
     function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transferFrom(_from,_to,_value);
     }

     function issueTokens(address _who, uint _tokens) byIcoContract {
          require((totalSupply + _tokens) <= TOTAL_TOKEN_SUPPLY);

          balances[_who] = safeAdd(balances[_who],_tokens);
          totalSupply = safeAdd(totalSupply,_tokens);

          Transfer(0x0, _who, _tokens);
     }

      
     function burnTokens(address _who, uint _tokens) byIcoContract {
          balances[_who] = safeSub(balances[_who], _tokens);
          totalSupply = safeSub(totalSupply, _tokens);
     }

     function lockTransfer(bool _lock) byIcoContract {
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
          revert();
     }
}

 
contract Goldmint is SafeMath {
 
      
      
      
      
     address[] public multisigs = [
          0x27ce565b1047c6258164062983bb8bc2917f11d2,
          0xfb3afc815894e91fe1ab6e6ef36f8565fbb904f6,
          0x7e2a7a10509177db2a7ea41e728743c4eb42f528,
          0x27ce565b1047c6258164062983bb8bc2917f11d2,
          0xfb3afc815894e91fe1ab6e6ef36f8565fbb904f6,
          0x7e2a7a10509177db2a7ea41e728743c4eb42f528,
          0x27ce565b1047c6258164062983bb8bc2917f11d2,
          0xfb3afc815894e91fe1ab6e6ef36f8565fbb904f6,
          0x7e2a7a10509177db2a7ea41e728743c4eb42f528,
          0xF4Ce80097bf1E584822dBcA84f91D5d7d9df0846
     ];

      
     mapping(address => uint) ethInvestedBy;
      
     uint constant STD_PRICE_USD_PER_1000_TOKENS = 7000;
      
      
      
     uint constant ETH_PRICE_IN_USD = 300;
      
      

     uint constant SINGLE_BLOCK_LEN = 100;

      
     uint public constant BONUS_REWARD = 1000000 * 1 ether;
      
     uint public constant FOUNDERS_REWARD = 2000000 * 1 ether;
      
      

     uint public constant ICO_TOKEN_SUPPLY_LIMIT = 150 * 1 ether;

      
     uint public constant ICO_TOKEN_SOFT_CAP = 150000 * 1 ether;

 
     address public creator = 0x0;
     address public tokenManager = 0x0;
     address public otherCurrenciesChecker = 0x0;

     uint64 public icoStartedTime = 0;

     MNTP public mntToken; 

     GoldmintUnsold public unsoldContract;

      
     uint public icoTokensSold = 0;
      
     uint public icoTokensUnsold = 0;
      
     uint public issuedExternallyTokens = 0;
      
     address public foundersRewardsAccount = 0x0;

     enum State{
          Init,

          ICORunning,
          ICOPaused,

           
           
          ICOFinished,

           
           
           
           
           
           
           
           
           
          Refunding,

           
           
           
           
           
          Migrating
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
          address _tokenManager,
          address _otherCurrenciesChecker,

          address _mntTokenAddress,
          address _unsoldContractAddress,
          address _foundersVestingAddress)
     {
          creator = msg.sender;

          tokenManager = _tokenManager;
          otherCurrenciesChecker = _otherCurrenciesChecker; 

          mntToken = MNTP(_mntTokenAddress);
          unsoldContract = GoldmintUnsold(_unsoldContractAddress);

           
          foundersRewardsAccount = _foundersVestingAddress;

          assert(multisigs.length==10);
     }

     function startICO() public onlyCreator onlyInState(State.Init) {
          setState(State.ICORunning);
          icoStartedTime = uint64(now);
          mntToken.lockTransfer(true);
          mntToken.issueTokens(foundersRewardsAccount, FOUNDERS_REWARD);
     }

     function pauseICO() public onlyCreator onlyInState(State.ICORunning) {
          setState(State.ICOPaused);
     }

     function resumeICO() public onlyCreator onlyInState(State.ICOPaused) {
          setState(State.ICORunning);
     }

     function startRefunding() public onlyCreator onlyInState(State.ICORunning) {
           
          require(icoTokensSold < ICO_TOKEN_SOFT_CAP);
          setState(State.Refunding);

           
          assert(mntToken.lockTransfers());
     }

     function startMigration() public onlyCreator onlyInState(State.ICOFinished) {
           
          setState(State.Migrating);

           
          mntToken.lockTransfer(true);
     }

      
      
     function finishICO() public onlyInState(State.ICORunning) {
          require(msg.sender == creator || isIcoFinished());
          setState(State.ICOFinished);

           
          mntToken.lockTransfer(false);

           
          icoTokensUnsold = safeSub(ICO_TOKEN_SUPPLY_LIMIT,icoTokensSold);
          if(icoTokensUnsold>0){
               mntToken.issueTokens(unsoldContract,icoTokensUnsold);
               unsoldContract.finishIco();
          }

           
           
          uint sendThisAmount = (this.balance / 10);

           
          for(uint i=0; i<9; ++i){
               address ms = multisigs[i];

               if(this.balance>=sendThisAmount){
                    ms.transfer(sendThisAmount);
               }
          }

           
          if(0!=this.balance){
               address lastMs = multisigs[9];
               lastMs.transfer(this.balance);
          }
     }

     function setState(State _s) internal {
          currentState = _s;
          LogStateSwitch(_s);
     }

 
     function setTokenManager(address _new) public onlyTokenManager {
          tokenManager = _new;
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

     function getBlockLength()constant public returns (uint){          
          return SINGLE_BLOCK_LEN;      
     }

     function getCurrentPrice()constant public returns (uint){
          return getMntTokensPerEth(icoTokensSold);
     }

 
     function isIcoFinished() constant public returns(bool) {
          return (icoStartedTime > 0)
            && (now > (icoStartedTime + 30 days) || (icoTokensSold >= ICO_TOKEN_SUPPLY_LIMIT));
     }

     function getMntTokensPerEth(uint _tokensSold) public constant returns (uint){
           
          uint priceIndex = (_tokensSold / 1 ether) / SINGLE_BLOCK_LEN;
          assert(priceIndex>=0 && (priceIndex<=9));
          
          uint8[10] memory discountPercents = [20,15,10,8,6,4,2,0,0,0];

           
           
          uint pricePer1000tokensUsd = 
               ((STD_PRICE_USD_PER_1000_TOKENS * 100) * 1 ether) / (100 + discountPercents[priceIndex]);

           
           
          uint mntPerEth = (ETH_PRICE_IN_USD * 1000 * 1 ether * 1 ether) / pricePer1000tokensUsd;
          return mntPerEth;
     }

     function buyTokens(address _buyer) public payable onlyInState(State.ICORunning) {
          require(msg.value!=0);

           
           
           
           
           
          uint newTokens = (msg.value * getMntTokensPerEth(icoTokensSold)) / 1 ether;

          issueTokensInternal(_buyer,newTokens);

           
          ethInvestedBy[msg.sender] = safeAdd(ethInvestedBy[msg.sender], msg.value);
     }

      
     function issueTokensFromOtherCurrency(address _to, uint _weiCount) onlyInState(State.ICORunning) public onlyOtherCurrenciesChecker {
          require(_weiCount!=0);

          uint newTokens = (_weiCount * getMntTokensPerEth(icoTokensSold)) / 1 ether;
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

      
     function getMyRefund() public onlyInState(State.Refunding) {
          address sender = msg.sender;
          uint ethValue = ethInvestedBy[sender];

          require(ethValue > 0);

           
          sender.transfer(ethValue);
          ethInvestedBy[sender] = 0;

           
          mntToken.burnTokens(sender, mntToken.balanceOf(sender));
     }

      
     function() payable {
           
          buyTokens(msg.sender);
     }
}
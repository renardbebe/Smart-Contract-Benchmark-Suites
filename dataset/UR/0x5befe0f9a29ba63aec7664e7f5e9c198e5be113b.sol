 

pragma solidity ^0.4.18;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
 
contract Ownable {
  address public owner;


   


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
     
    owner = newOwner;
  }

}

contract DSTToken is ERC20, Ownable, SafeMath {

     
    string public constant name = "Decentralize Silver Token";
    string public constant symbol = "DST";
    uint256 public constant decimals = 18;  

    uint256 public tokensPerEther = 1500;

     
    address public DSTMultisig;

     
    address dstWalletLMNO;

    bool public startStop = false;

    mapping (address => uint256) public walletA;
    mapping (address => uint256) public walletB; 
    mapping (address => uint256) public walletC;
    mapping (address => uint256) public walletF;
    mapping (address => uint256) public walletG;
    mapping (address => uint256) public walletH;

    mapping (address => uint256) public releasedA;
    mapping (address => uint256) public releasedB; 
    mapping (address => uint256) public releasedC;
    mapping (address => uint256) public releasedF;
    mapping (address => uint256) public releasedG; 
    mapping (address => uint256) public releasedH;

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

    struct WalletConfig{
        uint256 start;
        uint256 cliff;
        uint256 duration;
    }

    mapping (uint => address) public walletAddresses;
    mapping (uint => WalletConfig) public allWalletConfig;

     
     
    function setDSTWalletLMNO(address _dstWalletLMNO) onlyOwner external{
        require(_dstWalletLMNO != address(0));
        dstWalletLMNO = _dstWalletLMNO;
    }

     
     
    function setDSTMultiSig(address _dstMultisig) onlyOwner external{
        require(_dstMultisig != address(0));
        DSTMultisig = _dstMultisig;
    }

    function startStopICO(bool status) onlyOwner external{
        startStop = status;
    }

    function addWalletAddressAndTokens(uint _id, address _walletAddress, uint256 _tokens) onlyOwner external{
        require(_walletAddress != address(0));
        walletAddresses[_id] = _walletAddress;
        balances[_walletAddress] = safeAdd(balances[_walletAddress],_tokens);  
    }

     
     
     
     

    function addWalletConfig(uint256 _id, uint256 _start, uint256 _cliff, uint256 _duration) onlyOwner external{
        uint256 start = safeAdd(_start,now);
        uint256 cliff = safeAdd(start,_cliff);
        allWalletConfig[_id] = WalletConfig(
            start,
            cliff,
            _duration
        );
    }

    function assignToken(address _investor,uint256 _tokens) external {
         
        require(_investor != address(0) && _tokens > 0);
         
        require(_tokens <= balances[msg.sender]);
        
         
        balances[msg.sender] = safeSub(balances[msg.sender],_tokens);
         
        totalSupply = safeAdd(totalSupply, _tokens);

         
        if(msg.sender == walletAddresses[0]){
            walletA[_investor] = safeAdd(walletA[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[1]){
            walletB[_investor] = safeAdd(walletB[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[2]){
            walletC[_investor] = safeAdd(walletC[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[5]){
            walletF[_investor] = safeAdd(walletF[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[6]){
            walletG[_investor] = safeAdd(walletG[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[7]){
            walletH[_investor] = safeAdd(walletH[_investor],_tokens);
        }
        else{
            revert();
        }
    }

    function assignTokenIJK(address _userAddress,uint256 _tokens) external {
        require(msg.sender == walletAddresses[8] || msg.sender == walletAddresses[9] || msg.sender == walletAddresses[10]);
         
        require(_userAddress != address(0) && _tokens > 0);
         
        assignTokensWallet(msg.sender,_userAddress, _tokens);
    }

    function withdrawToken() public {
         
        uint256 currentBalance = 0;
        if(walletA[msg.sender] > 0){
            uint256 unreleasedA = getReleasableAmount(0,msg.sender);
            walletA[msg.sender] = safeSub(walletA[msg.sender], unreleasedA);
            currentBalance = safeAdd(currentBalance, unreleasedA);
            releasedA[msg.sender] = safeAdd(releasedA[msg.sender], unreleasedA);
        }
        if(walletB[msg.sender] > 0){
            uint256 unreleasedB = getReleasableAmount(1,msg.sender);
            walletB[msg.sender] = safeSub(walletB[msg.sender], unreleasedB);
            currentBalance = safeAdd(currentBalance, unreleasedB);
            releasedB[msg.sender] = safeAdd(releasedB[msg.sender], unreleasedB);
        }
        if(walletC[msg.sender] > 0){
            uint256 unreleasedC = getReleasableAmount(2,msg.sender);
            walletC[msg.sender] = safeSub(walletC[msg.sender], unreleasedC);
            currentBalance = safeAdd(currentBalance, unreleasedC);
            releasedC[msg.sender] = safeAdd(releasedC[msg.sender], unreleasedC);
        }
        require(currentBalance > 0);
         
        balances[msg.sender] = safeAdd(balances[msg.sender], currentBalance);
    }

    function withdrawBonusToken() public {
         
        uint256 currentBalance = 0;
        if(walletF[msg.sender] > 0){
            uint256 unreleasedF = getReleasableBonusAmount(5,msg.sender);
            walletF[msg.sender] = safeSub(walletF[msg.sender], unreleasedF);
            currentBalance = safeAdd(currentBalance, unreleasedF);
            releasedF[msg.sender] = safeAdd(releasedF[msg.sender], unreleasedF);
        }
        if(walletG[msg.sender] > 0){
            uint256 unreleasedG = getReleasableBonusAmount(6,msg.sender);
            walletG[msg.sender] = safeSub(walletG[msg.sender], unreleasedG);
            currentBalance = safeAdd(currentBalance, unreleasedG);
            releasedG[msg.sender] = safeAdd(releasedG[msg.sender], unreleasedG);
        }
        if(walletH[msg.sender] > 0){
            uint256 unreleasedH = getReleasableBonusAmount(7,msg.sender);
            walletH[msg.sender] = safeSub(walletH[msg.sender], unreleasedH);
            currentBalance = safeAdd(currentBalance, unreleasedH);
            releasedH[msg.sender] = safeAdd(releasedH[msg.sender], unreleasedH);
        }
        require(currentBalance > 0);
         
        balances[msg.sender] = safeAdd(balances[msg.sender], currentBalance);
    }

    function getReleasableAmount(uint256 _walletId,address _beneficiary) public view returns (uint256){
        uint256 totalBalance;

        if(_walletId == 0){
            totalBalance = safeAdd(walletA[_beneficiary], releasedA[_beneficiary]);    
            return safeSub(getData(_walletId,totalBalance), releasedA[_beneficiary]);
        }
        else if(_walletId == 1){
            totalBalance = safeAdd(walletB[_beneficiary], releasedB[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedB[_beneficiary]);
        }
        else if(_walletId == 2){
            totalBalance = safeAdd(walletC[_beneficiary], releasedC[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedC[_beneficiary]);
        }
        else{
            revert();
        }
    }

    function getReleasableBonusAmount(uint256 _walletId,address _beneficiary) public view returns (uint256){
        uint256 totalBalance;

        if(_walletId == 5){
            totalBalance = safeAdd(walletF[_beneficiary], releasedF[_beneficiary]);    
            return safeSub(getData(_walletId,totalBalance), releasedF[_beneficiary]);
        }
        else if(_walletId == 6){
            totalBalance = safeAdd(walletG[_beneficiary], releasedG[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedG[_beneficiary]);
        }
        else if(_walletId == 7){
            totalBalance = safeAdd(walletH[_beneficiary], releasedH[_beneficiary]);
            return safeSub(getData(_walletId,totalBalance), releasedH[_beneficiary]);
        }
        else{
            revert();
        }
    }

    function getData(uint256 _walletId,uint256 _totalBalance) public view returns (uint256) {
        uint256 availableBalanceIn = safeDiv(safeMul(_totalBalance, safeSub(allWalletConfig[_walletId].cliff, allWalletConfig[_walletId].start)), allWalletConfig[_walletId].duration);
        return safeMul(availableBalanceIn, safeDiv(getVestedAmount(_walletId,_totalBalance), availableBalanceIn));
    }

    function getVestedAmount(uint256 _walletId,uint256 _totalBalance) public view returns (uint256) {
        uint256 cliff = allWalletConfig[_walletId].cliff;
        uint256 start = allWalletConfig[_walletId].start;
        uint256 duration = allWalletConfig[_walletId].duration;

        if (now < cliff) {
            return 0;
        } else if (now >= safeAdd(start,duration)) {
            return _totalBalance;
        } else {
            return safeDiv(safeMul(_totalBalance,safeSub(now,start)),duration);
        }
    }

     
    function() payable external {
         
        require(startStop);
         
        require(msg.value >= 1 ether);

         
        uint256 createdTokens = safeMul(msg.value, tokensPerEther);

         
        assignTokensWallet(walletAddresses[3],msg.sender, createdTokens);
    }

     
     
     
     
    function cashInvestment(address cashInvestor, uint256 assignedTokens) onlyOwner external {
         
         
        require(cashInvestor != address(0) && assignedTokens > 0);

         
        assignTokensWallet(walletAddresses[4],cashInvestor, assignedTokens);
    }

     
     
     
     
     

     
     

     
     
     

     
     
    function assignTokensWallet(address walletAddress,address investor, uint256 tokens) internal {
         
        require(tokens <= balances[walletAddress]);
         
        totalSupply = safeAdd(totalSupply, tokens);

         
        balances[walletAddress] = safeSub(balances[walletAddress],tokens);
         
        balances[investor] = safeAdd(balances[investor], tokens);

         
        Transfer(0, investor, tokens);
    }

    function finalizeCrowdSale() external{
         
        require(DSTMultisig != address(0));
         
        require(DSTMultisig.send(address(this).balance));
    }

     
     
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool ok) {
         
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
         
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
         
        require(_from != 0 && _to != 0 && _value > 0);
         
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool ok) {
         
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function debitWalletLMNO(address _walletAddress,uint256 token) external onlyDSTWalletLMNO returns (bool){
         
        require(dstWalletLMNO != address(0));
         
        require(balances[_walletAddress] >= token && token > 0);
         
        totalSupply = safeAdd(totalSupply, token);
         
        balances[_walletAddress] = safeSub(balances[_walletAddress],token);
        return true;
    }

     
     
     
     
     
    function creditWalletUserLMNO(address claimAddress,uint256 token) external onlyDSTWalletLMNO returns (bool){
         
        require(dstWalletLMNO != address(0));
         
        require(claimAddress != address(0) && token > 0);
         
        balances[claimAddress] = safeAdd(balances[claimAddress], token);
         
        return true;
    }

     
     
    modifier onlyDSTWalletLMNO() {
        require(msg.sender == dstWalletLMNO);
        _;
    }
}
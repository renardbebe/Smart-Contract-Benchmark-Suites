 

pragma solidity ^0.4.0;

contract CrypteloERC20{
  function transfer(address to, uint amount);
}

contract CrypteloPreSale {
    using SafeMath for uint256;
    mapping (address => bool) private owners;
    mapping (address => uint) private WhiteListed; 
     
     
     
    
    mapping (address => uint256) private vestedTokens;
    mapping (address => uint256) private dateInvested;
    mapping (address => uint256) private firstDeadline;

    uint private firstGminimumWeiAmount =  100000000000000000;  
    uint private secondGminimumWeiAmount = 40000000000000000000;  
    uint public weiHardCap = 3625000000000000000000;  
    uint public weiRaised = 0;
    uint private weiLeft = weiHardCap;
    uint private CRLTotal = 9062500000000000;
    uint private CRLToSell = CRLTotal.div(2);
    uint private totalVesting = 0;
    uint private totalCRLDistributed = 0;
    uint private CRLLeft = CRLTotal;
    uint public CRLperEther = 1250000000000;  
    uint public CRLperMicroEther = CRLperEther.div(1000000);
    
    
    address public CrypteloERC20Address = 0x7123027d76a5135e66b3a365efaba2b55de18a62;
    address private forwardFundsWallet = 0xd6c56d07665D44159246517Bb4B2aC9bBeb040cf;
    
    
    uint firstTimeOffset = 1 years;

     
    event eRefund(address _addr, uint _weiAmount, string where);
    event eTokensToSend(address _addr, uint _CRLTokens);
    event eSendTokens(address _addr, uint _amount);

    
    
    function CrypteloPreSale(){
        owners[msg.sender] = true;
    }

    function () payable {
        uint amountEthWei = msg.value;
        address sender = msg.sender;
        uint totalAmountWei;
        uint tokensToSend = 0;
        uint limit = 0;

        if ( WhiteListed[sender] == 0 || amountEthWei > weiLeft){
            refund(sender, amountEthWei);
            eRefund(sender, amountEthWei, "L 58");
        }else{
            if(WhiteListed[sender] == 1){  
                limit = firstGminimumWeiAmount;
            }else{
                limit = secondGminimumWeiAmount;
            }
            if(amountEthWei >= limit){
                uint amountMicroEther = amountEthWei.div(1000000000000);
                tokensToSend = amountMicroEther.mul(CRLperMicroEther);
                eTokensToSend(sender, tokensToSend);
                if (totalCRLDistributed.add(tokensToSend) <= CRLToSell){
                    sendTokens(sender, tokensToSend);
                    totalCRLDistributed = totalCRLDistributed.add(tokensToSend);
                    vestTokens(sender, tokensToSend);  
                    forwardFunds(amountEthWei);
                    weiRaised = weiRaised.add(amountEthWei);
                    assert(weiLeft >= amountEthWei);
                    weiLeft = weiLeft.sub(amountEthWei);
                }else{
                    refund(sender, amountEthWei);
                    eRefund(sender, amountEthWei, "L 84");
                }
                
            }else{
                refund(sender, amountEthWei);
                eRefund(sender, amountEthWei, "L 75");
            }
        }
    }
    
    
    function forwardFunds(uint _amountEthWei) private{
        forwardFundsWallet.send(_amountEthWei);   
    }
    
    function getTotalVesting() public returns (uint _totalvesting){
        return totalVesting;
    }
    
    function getTotalDistributed() public returns (uint _totalvesting){
        return totalCRLDistributed;
    }
    
    function vestTokens(address _addr, uint _amountCRL) private returns (bool _success){
        totalVesting = totalVesting.add(_amountCRL);
        vestedTokens[_addr] = _amountCRL;  
        dateInvested[_addr] = now;
        firstDeadline[_addr] = now.add(firstTimeOffset);
    }
    function sendTokens(address _to, uint _amountCRL) private returns (address _addr, uint _amount){
         
       CrypteloERC20 _crypteloerc20;
        _crypteloerc20 = CrypteloERC20(CrypteloERC20Address);
        _crypteloerc20.transfer(_to, _amountCRL);
        eSendTokens(_to, _amountCRL);
    }
    
    function checkMyTokens() public returns (uint256 _CRLtokens) {
        return vestedTokens[msg.sender];
    }
    
    function checkMyVestingPeriod() public returns (uint256 _first){
        return (firstDeadline[msg.sender]);
    }
    
    function claimTokens(address _addr){  
        uint amount = 0;

        if (dateInvested[_addr] > 0 && vestedTokens[_addr] > 0 && now > firstDeadline[_addr]){
            amount = amount.add(vestedTokens[_addr]);  
            vestedTokens[_addr] = 0;
            if (amount > 0){
                 
                sendTokens(msg.sender, amount); 
                totalVesting = totalVesting.sub(amount);
            }
        }
    }
     
    function refund(address _sender, uint _amountWei) private{
         
        _sender.send(_amountWei);
    }
    function addWhiteList(address _addr, uint group){
        if (owners[msg.sender] && group <= 2){
            WhiteListed[_addr] = group; 
        }
    }
    
    function removeWhiteList(address _addr){
        if (owners[msg.sender]){
            WhiteListed[_addr] = 0; 
        }
    }
    
    function isWhiteList(address _addr) public returns (uint _group){
        return WhiteListed[_addr];
    }
    
    function withdrawDistributionCRL(){
        if (owners[msg.sender]){
            uint amount = CRLTotal.sub(totalCRLDistributed).sub(totalCRLDistributed);
            sendTokens(msg.sender, amount);
        }
    }
    
    function withdrawAllEther(){
        if (owners[msg.sender]){
            msg.sender.send(this.balance);
        }
    }
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
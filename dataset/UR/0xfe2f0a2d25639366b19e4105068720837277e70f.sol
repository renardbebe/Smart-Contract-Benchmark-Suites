 

pragma solidity ^0.4.2;
contract token { 
    function transfer(address, uint256){  }
    function balanceOf(address) constant returns (uint256) { }
}

 
 
contract FairAuction {
     
    address public beneficiary;
    uint public amountRaised; uint public startTime; uint public deadline; uint public memberCount; uint public crowdsaleCap;
    uint256 public tokenSupply;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    mapping (uint => address) accountIndex;
    bool public finalized;

     
    event TokenAllocation(address recipient, uint amount);
    event Finalized(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount);
    event FundClaim(address claimant, uint amount);

     
    function FairAuction(
        address fundedAddress,
        uint epochStartTime,
        uint durationInMinutes,
        uint256 capOnCrowdsale,
        token contractAddressOfRewardToken
    ) {
        beneficiary = fundedAddress;
        startTime = epochStartTime;
        deadline = startTime + (durationInMinutes * 1 minutes);
        tokenReward = token(contractAddressOfRewardToken);
        crowdsaleCap = capOnCrowdsale * 1 ether;
        finalized = false;
    }

     
    function () payable {
         
        if (now < startTime) throw;
        if (now >= deadline) throw;

        uint amount = msg.value;

         
        if (amountRaised + amount > crowdsaleCap) throw;

        uint256 existingBalance = balanceOf[msg.sender];

         
        if (existingBalance == 0) {
            accountIndex[memberCount] = msg.sender;
            memberCount += 1;
        } 
        
         
        balanceOf[msg.sender] = existingBalance + amount;
        amountRaised += amount;

         
        FundTransfer(msg.sender, amount);
    }

     
    function finalize() {
         
        if (amountRaised == 0) throw;

         
        if (now < deadline) {
             
            if (amountRaised < crowdsaleCap) throw;
        }

         
        tokenSupply = tokenReward.balanceOf(this);

         
        finalized = true;
         
        Finalized(beneficiary, amountRaised);
    }

     
    function individualClaim() {
         
        if (!finalized) throw;

         
        tokenReward.transfer(msg.sender, (balanceOf[msg.sender] * tokenSupply / amountRaised));
         
        TokenAllocation(msg.sender, (balanceOf[msg.sender] * tokenSupply / amountRaised));
         
        balanceOf[msg.sender] = 0;
    }

     
    function beneficiarySend() {
         
        if (!finalized) throw;

         
        if (beneficiary.send(amountRaised)) {
             
            FundClaim(beneficiary, amountRaised);
        }
    }

     
    function automaticWithdrawLoop(uint startIndex, uint endIndex) {
         
        if (!finalized) throw;
        
         
        for (uint i=startIndex; i<=endIndex && i<memberCount; i++) {
             
            if (accountIndex[i] == 0)
                continue;
             
            tokenReward.transfer(accountIndex[i], (balanceOf[accountIndex[i]] * tokenSupply / amountRaised));
             
            TokenAllocation(accountIndex[i], (balanceOf[accountIndex[i]] * tokenSupply / amountRaised));
             
            balanceOf[accountIndex[i]] = 0;
        }
    }
}
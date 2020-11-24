 
      event NRTTransfer(string pool, address sendAddress, uint256 value);


       
       
      event TokensBurned(uint256 amount);

     
      event PoolAddressAdded(string pool, address sendAddress);

       
       
      event LuckPoolUpdated(uint256 luckPoolBal);

       
       
      event BurnTokenBalUpdated(uint256 burnTokenBal);




       
      modifier OnlyAllowed() {
        require(msg.sender == timeAlly || msg.sender == timeSwappers,"Only TimeAlly and Timeswapper is authorised");
        _;
      }

           
      modifier OnlyOwner() {
        require(msg.sender == Owner,"Only Owner is authorised");
        _;
      }



       

      function burnTokens() internal returns (bool){
        if(burnTokenBal == 0){
          return true;
        }
        else{
          uint MaxAmount = ((token.totalSupply()).mul(2)).div(100);    
          if(MaxAmount >= burnTokenBal ){
            token.burn(burnTokenBal);
            burnTokenBal = 0;
          }
          else{
            burnTokenBal = burnTokenBal.sub(MaxAmount);
            token.burn(MaxAmount);
          }
          return true;
        }
      }


       

      function UpdateAddresses (address[9] calldata pool) external OnlyOwner  returns(bool){

        if((pool[0] != address(0)) && (newTalentsAndPartnerships == address(0))){
          newTalentsAndPartnerships = pool[0];
          emit PoolAddressAdded( "NewTalentsAndPartnerships", newTalentsAndPartnerships);
        }
        if((pool[1] != address(0)) && (platformMaintenance == address(0))){
          platformMaintenance = pool[1];
          emit PoolAddressAdded( "PlatformMaintenance", platformMaintenance);
        }
        if((pool[2] != address(0)) && (marketingAndRNR == address(0))){
          marketingAndRNR = pool[2];
          emit PoolAddressAdded( "MarketingAndRNR", marketingAndRNR);
        }
        if((pool[3] != address(0)) && (kmPards == address(0))){
          kmPards = pool[3];
          emit PoolAddressAdded( "KmPards", kmPards);
        }
        if((pool[4] != address(0)) && (contingencyFunds == address(0))){
          contingencyFunds = pool[4];
          emit PoolAddressAdded( "ContingencyFunds", contingencyFunds);
        }
        if((pool[5] != address(0)) && (researchAndDevelopment == address(0))){
          researchAndDevelopment = pool[5];
          emit PoolAddressAdded( "ResearchAndDevelopment", researchAndDevelopment);
        }
        if((pool[6] != address(0)) && (powerToken == address(0))){
          powerToken = pool[6];
          emit PoolAddressAdded( "PowerToken", powerToken);
        }
        if((pool[7] != address(0)) && (timeSwappers == address(0))){
          timeSwappers = pool[7];
          emit PoolAddressAdded( "TimeSwapper", timeSwappers);
        }
        if((pool[8] != address(0)) && (timeAlly == address(0))){
          timeAlly = pool[8];
          emit PoolAddressAdded( "TimeAlly", timeAlly);
        }

        return true;
      }


       
      function UpdateLuckpool(uint256 amount) external OnlyAllowed returns(bool){
              luckPoolBal = luckPoolBal.add(amount);
        emit LuckPoolUpdated(luckPoolBal);
        return true;
      }

       
      function UpdateBurnBal(uint256 amount) external OnlyAllowed returns(bool){
             burnTokenBal = burnTokenBal.add(amount);
        emit BurnTokenBalUpdated(burnTokenBal);
        return true;
      }

       

      function MonthlyNRTRelease() external returns (bool) {
        require(now.sub(lastNRTRelease)> 2629744,"NRT release happens once every month");
        uint256 NRTBal = monthlyNRTAmount.add(luckPoolBal);         

         
        newTalentsAndPartnershipsBal = (NRTBal.mul(5)).div(100);
        platformMaintenanceBal = (NRTBal.mul(10)).div(100);
        marketingAndRNRBal = (NRTBal.mul(10)).div(100);
        kmPardsBal = (NRTBal.mul(10)).div(100);
        contingencyFundsBal = (NRTBal.mul(10)).div(100);
        researchAndDevelopmentBal = (NRTBal.mul(5)).div(100);

        powerTokenNRT = (NRTBal.mul(10)).div(100);
        timeAllyNRT = (NRTBal.mul(15)).div(100);
        timeSwappersNRT = (NRTBal.mul(25)).div(100);

         
        token.mint(newTalentsAndPartnerships,newTalentsAndPartnershipsBal);
        emit NRTTransfer("newTalentsAndPartnerships", newTalentsAndPartnerships, newTalentsAndPartnershipsBal);

        token.mint(platformMaintenance,platformMaintenanceBal);
        emit NRTTransfer("platformMaintenance", platformMaintenance, platformMaintenanceBal);

        token.mint(marketingAndRNR,marketingAndRNRBal);
        emit NRTTransfer("marketingAndRNR", marketingAndRNR, marketingAndRNRBal);

        token.mint(kmPards,kmPardsBal);
        emit NRTTransfer("kmPards", kmPards, kmPardsBal);

        token.mint(contingencyFunds,contingencyFundsBal);
        emit NRTTransfer("contingencyFunds", contingencyFunds, contingencyFundsBal);

        token.mint(researchAndDevelopment,researchAndDevelopmentBal);
        emit NRTTransfer("researchAndDevelopment", researchAndDevelopment, researchAndDevelopmentBal);

        token.mint(powerToken,powerTokenNRT);
        emit NRTTransfer("powerToken", powerToken, powerTokenNRT);

        token.mint(timeAlly,timeAllyNRT);
        TimeAlly timeAllyContract = TimeAlly(timeAlly);
        timeAllyContract.increaseMonth(timeAllyNRT);
        emit NRTTransfer("stakingContract", timeAlly, timeAllyNRT);

        token.mint(timeSwappers,timeSwappersNRT);
        emit NRTTransfer("timeSwappers", timeSwappers, timeSwappersNRT);

         
        emit NRTDistributed(NRTBal);
        luckPoolBal = 0;
        lastNRTRelease = lastNRTRelease.add(2629744);  
        burnTokens();                                  
        emit TokensBurned(burnTokenBal);


        if(monthCount == 11){
          monthCount = 0;
          annualNRTAmount = (annualNRTAmount.mul(90)).div(100);
          monthlyNRTAmount = annualNRTAmount.div(12);
        }
        else{
          monthCount = monthCount.add(1);
        }
        return true;
      }


     

    constructor(address eraswaptoken) public{
      token = Eraswap(eraswaptoken);
      lastNRTRelease = now;
      annualNRTAmount = 819000000000000000000000000;
      monthlyNRTAmount = annualNRTAmount.div(uint256(12));
      monthCount = 0;
      Owner = msg.sender;
    }

}

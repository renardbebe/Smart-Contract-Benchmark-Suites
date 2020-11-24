 

pragma solidity ^0.4.20;

contract EtherPaint {
    
    
   uint256 constant scaleFactor = 0x10000000000000000;  

    
    
    
   int constant crr_n = 1;  
   int constant crr_d = 2;  

    
    
   int constant price_coeff = -0x296ABF784A358468C;

    
   mapping(address => uint256[16]) public tokenBalance;

   uint256[128][128] public colorPerCoordinate;
   uint256[16] public colorPerCanvas;

   event colorUpdate(uint8 posx, uint8 posy, uint8 colorid);
   event priceUpdate(uint8 colorid);
   event tokenUpdate(uint8 colorid, address who);
   event dividendUpdate();

   event pushuint(uint256 s);
      
    
    
   mapping(address => int256[16]) public payouts;

    
   uint256[16] public totalSupply;

   uint256 public allTotalSupply;

    
    
   int256[16] totalPayouts;

    
    
   uint256[16] earningsPerToken;
   
    
   uint256[16] public contractBalance;

   address public owner;

   uint256 public ownerFee;



   function EtherPaint() public {
       owner = msg.sender;
       colorPerCanvas[0] = 128*128;
      pushuint(1 finney);
   }

    
   function balanceOf(address _owner, uint8 colorid) public constant returns (uint256 balance) {
      if (colorid >= 16){
         revert();
      }
      return tokenBalance[_owner][colorid];
   }

    
    
   function withdraw(uint8 colorid) public {
      if (colorid >= 16){
         revert();
      }
       
      var balance = dividends(msg.sender, colorid);
      
       
      payouts[msg.sender][colorid] += (int256) (balance * scaleFactor);
      
       
      totalPayouts[colorid] += (int256) (balance * scaleFactor);
      
       
      contractBalance[colorid] = sub(contractBalance[colorid], div(mul(balance, 95),100));
      msg.sender.transfer(balance);
   }

   function withdrawOwnerFee() public{
      if (msg.sender == owner){
         owner.transfer(ownerFee);
         ownerFee = 0;
      }
   }

    
    
    
   function sellMyTokens(uint8 colorid) public {
      if (colorid >= 16){
         revert();
      }
      var balance = balanceOf(msg.sender, colorid);
      sell(balance, colorid);
      priceUpdate(colorid);
      dividendUpdate();
      tokenUpdate(colorid, msg.sender);
   }
   
    function sellMyTokensAmount(uint8 colorid, uint256 amount) public {
      if (colorid >= 16){
         revert();
      }
      var balance = balanceOf(msg.sender, colorid);
      if (amount <= balance){
        sell(amount, colorid);
        priceUpdate(colorid);
        dividendUpdate();
        tokenUpdate(colorid, msg.sender);
      }
   }

    
    
    function getMeOutOfHere() public {
      for (uint8 i=0; i<16; i++){
         sellMyTokens(i);
         withdraw(i);
      }

   }

    
    
   function fund(uint8 colorid, uint8 posx, uint8 posy) payable public {
       
      if (colorid >= 16){
         revert();
      }
      if ((msg.value > 0.000001 ether) && (posx >= 0) && (posx <= 127) && (posy >= 0) && (posy <= 127)) {
         contractBalance[colorid] = add(contractBalance[colorid], div(mul(msg.value, 95),100));
         buy(colorid);
         colorPerCanvas[colorPerCoordinate[posx][posy]] = sub(colorPerCanvas[colorPerCoordinate[posx][posy]], 1);
         colorPerCoordinate[posx][posy] = colorid;
         colorPerCanvas[colorid] = add(colorPerCanvas[colorid],1);
         colorUpdate(posx, posy, colorid);
         priceUpdate(colorid);
         dividendUpdate();
         tokenUpdate(colorid, msg.sender);

      } else {
         revert();
      }
    }

    
   function buyPrice(uint8 colorid) public constant returns (uint) {
      if (colorid >= 16){
         revert();
      }
      return getTokensForEther(1 finney, colorid);
   }

    
   function sellPrice(uint8 colorid) public constant returns (uint) {
         if (colorid >= 16){
            revert();
         }
        var eth = getEtherForTokens(1 finney, colorid);
        var fee = div(eth, 10);
        return eth - fee;
    }

    
    
    
   function dividends(address _owner, uint8 colorid) public constant returns (uint256 amount) {
      if (colorid >= 16){
         revert();
      }
      return (uint256) ((int256)(earningsPerToken[colorid] * tokenBalance[_owner][colorid]) - payouts[_owner][colorid]) / scaleFactor;
   }

    
    
    
    
       
      
      
       
       
      
       
       
      
       
       
       
    

    
   function balance(uint8 colorid) internal constant returns (uint256 amount) {

       
      return contractBalance[colorid] - msg.value;
   }

   function buy(uint8 colorid) internal {

       

      if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
         revert();
                  
       
       
      
       
      var fee = mul(div(msg.value, 20), 4);
      
       
       
      
       
      var numTokens = getTokensForEther(msg.value - fee, colorid);
      
       
      uint256 buyerFee = 0;
      
       
       
      if (totalSupply[colorid] > 0) {
          
          
          

         for (uint8 c=0; c<16; c++){
            if (totalSupply[c] > 0){
               var theExtraFee = mul(div(mul(div(fee,4), scaleFactor), allTotalSupply), totalSupply[c]) + mul(div(div(fee,4), 128*128),mul(colorPerCanvas[c], scaleFactor));
                

               if (c==colorid){
                  
                buyerFee = (div(fee,4) + div(theExtraFee,scaleFactor))*scaleFactor - (div(fee, 4) + div(theExtraFee,scaleFactor)) * (scaleFactor - (reserve(colorid) + msg.value - fee) * numTokens * scaleFactor / (totalSupply[colorid] + numTokens) / (msg.value - fee))
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
             




               }
               else{

                   
                  earningsPerToken[c] = add(earningsPerToken[c], div(theExtraFee, totalSupply[c]));


               }
            }
         }
         


         



         ownerFee = add(ownerFee, div(fee,4));
            
          
          


          
          

         
          
          

         earningsPerToken[colorid] = earningsPerToken[colorid] +  buyerFee / (totalSupply[colorid]);

             
         
      }

         totalSupply[colorid] = add(totalSupply[colorid], numTokens);

         allTotalSupply = add(allTotalSupply, numTokens);

       


      

       
      tokenBalance[msg.sender][colorid] = add(tokenBalance[msg.sender][colorid], numTokens);

       
       
       

      
       
      payouts[msg.sender][colorid] +=  (int256) ((earningsPerToken[colorid] * numTokens) - buyerFee);
      
       
      totalPayouts[colorid]    +=  (int256) ((earningsPerToken[colorid] * numTokens) - buyerFee);
      
   }

    
    
    
   function sell(uint256 amount, uint8 colorid) internal {
        
      var numEthersBeforeFee = getEtherForTokens(amount, colorid);
      
       
      var fee = mul(div(numEthersBeforeFee, 20), 4);
      
       
      var numEthers = numEthersBeforeFee - fee;
      
       
      totalSupply[colorid] = sub(totalSupply[colorid], amount);
      allTotalSupply = sub(allTotalSupply, amount);
      
         
      tokenBalance[msg.sender][colorid] = sub(tokenBalance[msg.sender][colorid], amount);

         
       
      var payoutDiff = (int256) (earningsPerToken[colorid] * amount + (numEthers * scaleFactor));
      
         
       
       
      payouts[msg.sender][colorid] -= payoutDiff;     
      
       
      totalPayouts[colorid] -= payoutDiff;
      
       
       
      if (totalSupply[colorid] > 0) {
          

         for (uint8 c=0; c<16; c++){
            if (totalSupply[c] > 0){
               var theExtraFee = mul(div(mul(div(fee,4), scaleFactor), allTotalSupply), totalSupply[c]) + mul(div(div(fee,4), 128*128),mul(colorPerCanvas[c], scaleFactor));
            
               earningsPerToken[c] = add(earningsPerToken[c], div(theExtraFee,totalSupply[c]));
            }
         }

         ownerFee = add(ownerFee, div(fee,4));

         var etherFee = div(fee,4) * scaleFactor;
         
          
          
         var rewardPerShare = etherFee / totalSupply[colorid];
         
          
         earningsPerToken[colorid] = add(earningsPerToken[colorid], rewardPerShare);

         
      }
   }

    
   function reserve(uint8 colorid) internal constant returns (uint256 amount) {
      return sub(balance(colorid),
          ((uint256) ((int256) (earningsPerToken[colorid] * totalSupply[colorid]) - totalPayouts[colorid]) / scaleFactor));
   }

    
    
   function getTokensForEther(uint256 ethervalue, uint8 colorid) public constant returns (uint256 tokens) {
      if (colorid >= 16){
         revert();
      }
      return sub(fixedExp(fixedLog(reserve(colorid) + ethervalue)*crr_n/crr_d + price_coeff), totalSupply[colorid]);
   }



    
   function getEtherForTokens(uint256 tokens, uint8 colorid) public constant returns (uint256 ethervalue) {
      if (colorid >= 16){
         revert();
      }
       
      var reserveAmount = reserve(colorid);

       
      if (tokens == totalSupply[colorid])
         return reserveAmount;

       
       
       
       
      return sub(reserveAmount, fixedExp((fixedLog(totalSupply[colorid] - tokens) - price_coeff) * crr_d/crr_n));
   }

 
    
   int256  constant one        = 0x10000000000000000;
   uint256 constant sqrt2      = 0x16a09e667f3bcc908;
   uint256 constant sqrtdot5   = 0x0b504f333f9de6484;
   int256  constant ln2        = 0x0b17217f7d1cf79ac;
   int256  constant ln2_64dot5 = 0x2cb53f09f05cc627c8;
   int256  constant c1         = 0x1ffffffffff9dac9b;
   int256  constant c3         = 0x0aaaaaaac16877908;
   int256  constant c5         = 0x0666664e5e9fa0c99;
   int256  constant c7         = 0x049254026a7630acf;
   int256  constant c9         = 0x038bd75ed37753d68;
   int256  constant c11        = 0x03284a0c14610924f;

    
    
    
   function fixedLog(uint256 a) internal pure returns (int256 log) {
      int32 scale = 0;
      while (a > sqrt2) {
         a /= 2;
         scale++;
      }
      while (a <= sqrtdot5) {
         a *= 2;
         scale--;
      }
      int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
      var z = (s*s) / one;
      return scale * ln2 +
         (s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
            /one))/one))/one))/one))/one);
   }

   int256 constant c2 =  0x02aaaaaaaaa015db0;
   int256 constant c4 = -0x000b60b60808399d1;
   int256 constant c6 =  0x0000455956bccdd06;
   int256 constant c8 = -0x000001b893ad04b3a;
   
    
    
    
   function fixedExp(int256 a) internal pure returns (uint256 exp) {
      int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
      a -= scale*ln2;
      int256 z = (a*a) / one;
      int256 R = ((int256)(2) * one) +
         (z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
      exp = (uint256) (((R + a) * one) / (R - a));
      if (scale >= 0)
         exp <<= scale;
      else
         exp >>= -scale;
      return exp;
   }
   
    
    

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

    
    
   function () payable public {
       
      revert();
       
       
       
       
       
       

       
   }
   
}
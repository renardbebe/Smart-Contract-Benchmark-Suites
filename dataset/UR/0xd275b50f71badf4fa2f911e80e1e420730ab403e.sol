 

pragma solidity ^0.4.18;

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




contract DragonPricing is Ownable {
    
   
    
    DragonCrowdsaleCore dragoncrowdsalecore;
    uint public firstroundprice  = .000000000083333333 ether;
    uint public secondroundprice = .000000000100000000 ether;
    uint public thirdroundprice  = .000000000116686114 ether;
    
    uint public price;
    
    
    function DragonPricing() {
        
        
        price = firstroundprice;
        
        
    }
    
    
    
    
    function crowdsalepricing( address tokenholder, uint amount, uint crowdsaleCounter )  returns ( uint , uint ) {
        
        uint award;
        uint donation = 0;
        return ( DragonAward ( amount, crowdsaleCounter ) ,donation );
        
    }
    
    
    function precrowdsalepricing( address tokenholder, uint amount )   returns ( uint, uint )  {
        
       
        uint award;
        uint donation;
        require ( presalePackage( amount ) == true );
        ( award, donation ) = DragonAwardPresale ( amount );
        
        return ( award, donation );
        
    }
    
    
    function presalePackage ( uint amount ) internal returns ( bool )  {
        
        if( amount != .3333333 ether && amount != 3.3333333 ether && amount != 33.3333333 ether  ) return false;
        return true;
   }
    
    
    function DragonAwardPresale ( uint amount ) internal returns ( uint , uint ){
        
        if ( amount ==   .3333333 ether ) return   (   10800000000 ,   800000000 );
        if ( amount ==  3.3333333 ether ) return   (  108800000000 ,  8800000000 );
        if ( amount == 33.3333333 ether ) return   ( 1088800000000 , 88800000000 );
    
    }
    
    
    
    function DragonAward ( uint amount, uint crowdsaleCounter ) internal returns ( uint  ){
        
       
         
        if ( crowdsaleCounter > 1000000000000000 &&  crowdsaleCounter < 2500000000000000 ) price = secondroundprice;
        if ( crowdsaleCounter >= 2500000000000000 ) price = thirdroundprice;
          
        return ( amount / price );
          
    
    }
    
  
    
    function setFirstRoundPricing ( uint _pricing ) onlyOwner {
        
        firstroundprice = _pricing;
        
    }
    
    function setSecondRoundPricing ( uint _pricing ) onlyOwner {
        
        secondroundprice = _pricing;
        
    }
    
    function setThirdRoundPricing ( uint _pricing ) onlyOwner {
        
        thirdroundprice = _pricing;
        
    }
    
    
}

contract Dragon {
    function transfer(address receiver, uint amount)returns(bool ok);
    function balanceOf( address _address )returns(uint256);
}





contract DragonCrowdsaleCore is Ownable, DragonPricing {
    
    using SafeMath for uint;
    
    
    address public beneficiary;
    address public charity;
    address public advisor;
    address public front;
    bool public advisorset;
    
    uint public tokensSold;
    uint public etherRaised;
    uint public presold;
    uint public presoldMax;
    
    uint public crowdsaleCounter;
    
   
    uint public advisorTotal;
    uint public advisorCut;
    
    Dragon public tokenReward;
    
   
    
    mapping ( address => bool ) public alreadyParticipated;
    
    
    
  
    
    modifier onlyFront() {
       require (msg.sender == front );
        _;
    }


    
    
    
    function DragonCrowdsaleCore(){
        
        tokenReward = Dragon( 0x814f67fa286f7572b041d041b1d99b432c9155ee );  
        owner = msg.sender;
        beneficiary = msg.sender;
        charity = msg.sender;
        advisor = msg.sender;
       
        advisorset = false;
       
        presold = 0;
        presoldMax = 3500000000000000;
        crowdsaleCounter = 0;
        
        advisorCut = 0;
        advisorTotal = 1667 ether;
        
        
    }
    
   
     
    function precrowdsale ( address tokenholder ) onlyFront payable {
        
        
        require ( presold < presoldMax );
        uint award;   
        uint donation;  
        require ( alreadyParticipated[ tokenholder ]  != true ) ;  
        alreadyParticipated[ tokenholder ] = true;
        
        DragonPricing pricingstructure = new DragonPricing();
        ( award, donation ) = pricingstructure.precrowdsalepricing( tokenholder , msg.value ); 
        
        tokenReward.transfer ( charity , donation );  
        presold = presold.add( award );  
        presold = presold.add( donation );  
        
        tokensSold = tokensSold.add(donation);   
        tokenReward.transfer ( tokenholder , award );  
        
        if ( advisorCut < advisorTotal ) { advisorSiphon();} 
       
        else 
          { beneficiary.transfer ( msg.value ); }  
          
       
        etherRaised = etherRaised.add( msg.value );  
        tokensSold = tokensSold.add(award);  
        
    }
    
     
    function crowdsale ( address tokenholder  ) onlyFront payable {
        
        
        uint award;   
        uint donation;  
        DragonPricing pricingstructure = new DragonPricing();
        ( award , donation ) = pricingstructure.crowdsalepricing( tokenholder, msg.value, crowdsaleCounter ); 
         crowdsaleCounter += award;
        
        tokenReward.transfer ( tokenholder , award );  
       
        if ( advisorCut < advisorTotal ) { advisorSiphon();}  
       
        else 
          { beneficiary.transfer ( msg.value ); }  
        
        etherRaised = etherRaised.add( msg.value );   
        tokensSold = tokensSold.add(award);  
       
        
        
    }
    
    
     
    function advisorSiphon() internal {
        
         uint share = msg.value/10;
         uint foradvisor = share;
             
           if ( (advisorCut + share) > advisorTotal ) foradvisor = advisorTotal.sub( advisorCut ); 
             
           advisor.transfer ( foradvisor );   
            
           advisorCut = advisorCut.add( foradvisor );
           beneficiary.transfer( share * 9 );  
           if ( foradvisor != share ) beneficiary.transfer( share.sub(foradvisor) );  
        
        
        
    }
    
   

    
     
    function transferBeneficiary ( address _newbeneficiary ) onlyOwner {
        
        require ( _newbeneficiary != 0x00 );
        beneficiary = _newbeneficiary;
        
    }
    
     
    function transferCharity ( address _charity ) onlyOwner {
        
        require ( _charity != 0x00 );
        charity = _charity;
        
    }
    
     
    function setFront ( address _front ) onlyOwner {
        
        require ( _front != 0x00 );
        front = _front;
        
    }
     
    function setAdvisor ( address _advisor ) onlyOwner {
        
        require ( _advisor != 0x00 );
        require ( advisorset == false );
        advisorset = true;
        advisor = _advisor;
        
    }
    
   
        
     
    function withdrawCrowdsaleDragons() onlyOwner{
        
        uint256 balance = tokenReward.balanceOf( address( this ) );
        tokenReward.transfer( beneficiary, balance );
        
        
    }
    
     
    function manualSend ( address tokenholder, uint packagenumber ) onlyOwner {
        
          require ( tokenholder != 0x00 );
          if ( packagenumber != 1 &&  packagenumber != 2 &&  packagenumber != 3 ) revert();
        
          uint award;
          uint donation;
          
          if ( packagenumber == 1 )  { award =   10800000000; donation =   800000000; }
          if ( packagenumber == 2 )  { award =  108800000000; donation =  8800000000; }
          if ( packagenumber == 3 )  { award = 1088800000000; donation = 88800000000; }
          
          
          tokenReward.transfer ( tokenholder , award ); 
          tokenReward.transfer ( charity , donation ); 
          
          presold = presold.add( award );  
          presold = presold.add( donation );  
          tokensSold = tokensSold.add(award);  
          tokensSold = tokensSold.add(donation);  
        
    }
   
   
    
    
    
}
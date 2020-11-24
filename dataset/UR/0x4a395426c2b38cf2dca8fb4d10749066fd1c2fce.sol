 

pragma solidity ^0.4.25;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
contract FomoBet  {
    using SafeMath for uint;
     
    struct bet {
        address maker;
        address taker;
        uint256 round;
        bool longOrShort; 
        bool validated;
        uint256 betEnd;  
        uint256 betSize;  
        
        }
    struct offer {
        address maker;
        uint256 amount;
        bool longOrShort; 
        uint256 betEndInDays;  
        uint256 betSize;  
        uint256 takerSize;  
        }   
    FoMo3Dlong constant FoMo3Dlong_ = FoMo3Dlong(0xF3ECc585010952b7809d0720a69514761ba1866D);    
    mapping(uint256 => bet) public placedBets;
    uint256 public nextBetInLine;
    mapping(uint256 => offer) public OpenOffers;
    uint256 public nextBetOffer;
    mapping(address => uint256) public playerVault;
     
    function vaultToWallet() public {
        
        address sender = msg.sender;
        require(playerVault[sender] > 0);
        uint256 value = playerVault[sender];
        playerVault[sender] = 0;
        sender.transfer(value);
        
    }
    function () external payable{
        address sender= msg.sender;
        playerVault[sender] = playerVault[sender].add(msg.value);
    }
    function setupOffer(uint256 amountOffers, bool longOrShort, uint256 endingInDays, uint256 makerGive, uint256 takerGive) public payable{
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= amountOffers.mul(makerGive));
        offer memory current;
        current.maker = sender;
        current.amount = amountOffers;
        current.longOrShort = longOrShort;
        current.betEndInDays = endingInDays;
        current.betSize = makerGive;
        current.takerSize = takerGive;
        OpenOffers[nextBetOffer] = current;
        nextBetOffer++;
    }
    function addToExistingOffer(uint256 offerNumber, uint256 amountOffers) public payable{
        address sender = msg.sender;
        uint256 value = msg.value;
        require(sender == OpenOffers[offerNumber].maker);
        require(value >= OpenOffers[offerNumber].betSize.mul(amountOffers));
        OpenOffers[offerNumber].amount = OpenOffers[offerNumber].amount.add(amountOffers);
    }
    function removeFromExistingOffer(uint256 offerNumber, uint256 amountOffers) public {
        address sender = msg.sender;
        
        require(sender == OpenOffers[offerNumber].maker);
        require(amountOffers <= OpenOffers[offerNumber].amount);
        OpenOffers[offerNumber].amount = OpenOffers[offerNumber].amount.sub(amountOffers);
        playerVault[sender] = playerVault[sender].add(amountOffers.mul(OpenOffers[offerNumber].betSize));
    }
    function takeOffer(uint256 offerNumber, uint256 amountOffers) public payable{
         
        address sender = msg.sender;
        uint256 value = msg.value;
        uint256 timer = now;
        offer memory current = OpenOffers[offerNumber];
        bet memory solid;
        require(amountOffers >= current.amount );
        require(value >= amountOffers.mul(current.takerSize));
        solid.longOrShort = current.longOrShort;
        solid.maker = current.maker;
        solid.taker = sender;
        solid.betEnd =  timer.add(current.betEndInDays * 1 days);
        solid.round = FoMo3Dlong_.rID_();
        solid.betSize = value.add(amountOffers.mul(current.betSize));
        placedBets[nextBetOffer] = solid;
        nextBetOffer++;
    }
    function validateBet(uint256 betNumber) public {
         
        bet memory toCheck = placedBets[betNumber];
        uint256 timer = now;
        uint256 round = FoMo3Dlong_.rID_();
        if(toCheck.validated != true){
            if(toCheck.longOrShort == true){
                 
                if(timer >= toCheck.betEnd){
                    placedBets[betNumber].validated = true;
                    playerVault[toCheck.maker] = playerVault[toCheck.maker].add(toCheck.betSize);
                }
                 
                if(timer < toCheck.betEnd && round > toCheck.round){
                    placedBets[betNumber].validated = true;
                    playerVault[toCheck.taker] = playerVault[toCheck.taker].add(toCheck.betSize);
                }
            }
            if(toCheck.longOrShort == false){
                 
                if(timer >= toCheck.betEnd ){
                    placedBets[betNumber].validated = true;
                    playerVault[toCheck.taker] = playerVault[toCheck.taker].add(toCheck.betSize);
                }
                 
                if(timer < toCheck.betEnd && round > toCheck.round){
                    placedBets[betNumber].validated = true;
                    playerVault[toCheck.maker] = playerVault[toCheck.maker].add(toCheck.betSize);
                }
            }
        }
    }
    function death () external {
        require(msg.sender == 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220);
    selfdestruct(0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220);
        
    }
     
    function getOfferInfo() public view returns(address[] memory _Owner, uint256[] memory locationData , bool[] memory allows){
          uint i;
          address[] memory _locationOwner = new address[](nextBetOffer);
          uint[] memory _locationData = new uint[](nextBetOffer*4);  
          bool[] memory _locationData2 = new bool[](nextBetOffer);  
          uint y;
          for(uint x = 0; x < nextBetOffer; x+=1){
            
             
                _locationOwner[i] = OpenOffers[i].maker;
                _locationData[y] = OpenOffers[i].amount;
                _locationData[y+1] = OpenOffers[i].betEndInDays;
                _locationData[y+2] = OpenOffers[i].betSize;
                _locationData[y+3] = OpenOffers[i].takerSize;
                _locationData2[i] = OpenOffers[i].longOrShort;
              y += 4;
              i+=1;
            }
          
          return (_locationOwner,_locationData, _locationData2);
        }
         
        function getbetsInfo() public view returns(address[] memory _Owner, uint256[] memory locationData , bool[] memory allows){
          uint i;
          address[] memory _locationOwner = new address[](nextBetOffer*2);
          uint[] memory _locationData = new uint[](nextBetOffer*3);  
          bool[] memory _locationData2 = new bool[](nextBetOffer*2);  
          uint y;
          for(uint x = 0; x < nextBetOffer; x+=1){
            
             
                _locationOwner[i] = placedBets[i].maker;
                _locationOwner[i+1] = placedBets[i].taker;
                _locationData[y] = placedBets[i].round;
                _locationData[y+1] = placedBets[i].betEnd;
                _locationData[y+2] = placedBets[i].betSize;
                _locationData2[i] = placedBets[i].validated;
                _locationData2[i+1] = placedBets[i].longOrShort;
              y += 3;
              i+=2;
            }
          
          return (_locationOwner,_locationData, _locationData2);
        }
}
 
interface FoMo3Dlong {
    
    function rID_() external view returns(uint256);
    
}
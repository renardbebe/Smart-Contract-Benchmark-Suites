 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


contract HeroCore{

   function ownerIndexToERC20Balance(address _address) public returns (uint256);
   function useItems(uint32 _items, uint256 tokenId, address owner,uint256 fee) public returns (bool);
   function ownerOf(uint256 _tokenId) public returns (address);
   function getHeroItems(uint256 _id) public returns ( uint32);
    
   function reduceCDFee(uint256 heroId) 
         public 
         view 
         returns (uint256);
   
}

contract MagicStore is Pausable {
		HeroCore public heroCore;
    
    mapping (uint8 =>mapping (uint8 => uint256)) public itemIndexToPrice; 
			
		function MagicStore(address _heroCore){
        HeroCore candidateContract2 = HeroCore(_heroCore);
        heroCore = candidateContract2;
		}	
    
    function buyItem(uint8 itemX,uint8 itemY, uint256 tokenId, uint256 amount) public{
        require( msg.sender == heroCore.ownerOf(tokenId) );
        require( heroCore.ownerIndexToERC20Balance(msg.sender) >= amount);
        require( itemX >0);
        uint256 fee= itemIndexToPrice[itemX][itemY];           
        require(fee !=0 && fee <= amount); 
           uint32 items = heroCore.getHeroItems(tokenId);
           uint32 location = 1;
		       for(uint8 index = 2; index <= itemX; index++){
		          location *=10;
		       }
        uint32 _itemsId = items+ uint32(itemY) *location - items%location *location;
              
        heroCore.useItems(_itemsId,tokenId,msg.sender,amount);       
    }
    
    
    function setItem(uint8 itemX,uint8 itemY, uint256 amount) public onlyOwner{
    	 require( itemX <=9 && itemY <=9 && amount !=0);
    
       itemIndexToPrice[itemX][itemY] =amount;    
    }
}
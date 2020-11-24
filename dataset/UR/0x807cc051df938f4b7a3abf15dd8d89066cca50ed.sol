 

 
 
pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
interface ERC721Interface {
     function totalSupply() public view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId);
     function burnToken(address tokenOwner, uint256 tid) ;
     function sendToken(address sendTo, uint tid, string tmeta) ;
     function getTotalTokensAgainstAddress(address ownerAddress) public constant returns (uint totalAnimals);
     function getAnimalIdAgainstAddress(address ownerAddress) public constant returns (uint[] listAnimals);
     function balanceOf(address _owner) public view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) public view returns (address _owner);
     function setAnimalMeta(uint tid, string tmeta);
}


contract AnimalFactory is Ownable
{
     
    struct AnimalProperties
    {
        uint id;
        string name;
        string desc;
        bool upForSale;
        uint priceForSale;
        bool upForMating;
        bool eggPhase;
        uint priceForMating;
        bool isBornByMating;
        uint parentId1;
        uint parentId2;
        uint birthdate;
        uint costumeId;
        uint generationId;
		bool isSpecial;
    }
    
    using SafeMath for uint256;
 
     
    ERC721Interface public token;
    
    
     
    uint uniqueAnimalId=0;

     
    mapping(uint=>AnimalProperties)  animalAgainstId;
    
     
    mapping(uint=>uint[])  childrenIdAgainstAnimalId;
    
     
    uint[] upForMatingList;

     
    uint[] upForSaleList;
    
     
    address[] memberAddresses;

     
    AnimalProperties  animalObject;

     
    uint public ownerPerThousandShareForMating = 35;
    uint public ownerPerThousandShareForBuying = 35;

     
    uint public freeAnimalsLimit = 4;
    
     
    bool public isContractPaused;

     
    uint public priceForMateAdvertisement;
    uint public priceForSaleAdvertisement;
    
    uint public priceForBuyingCostume;

     
    uint256 public weiRaised;

     
    uint256 public totalBunniesCreated=0;

     
    uint256 public weiPerAnimal = 1*10**18;
    uint[] eggPhaseAnimalIds;
    uint[] animalIdsWithPendingCostumes;

     
    event AnimalsPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
   function AnimalFactory(address _walletOwner,address _tokenAddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;
        priceForMateAdvertisement = 1 * 10 ** 16;
        priceForSaleAdvertisement = 1 * 10 ** 16;
        priceForBuyingCostume = 1 * 10 ** 16;
        token = ERC721Interface(_tokenAddress);
    }

      
    
    function getAnimalById(uint aid) public constant returns 
    (string, string,uint,uint ,uint, uint,uint)
    {
        if(animalAgainstId[aid].eggPhase==true)
        {
            return(animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
            2**256 - 1,
            animalAgainstId[aid].priceForSale,
            animalAgainstId[aid].priceForMating,
            animalAgainstId[aid].parentId1,
            animalAgainstId[aid].parentId2
            );
        }
        else 
        {
            return(animalAgainstId[aid].name,
            animalAgainstId[aid].desc,
            animalAgainstId[aid].id,
            animalAgainstId[aid].priceForSale,
            animalAgainstId[aid].priceForMating,
            animalAgainstId[aid].parentId1,
            animalAgainstId[aid].parentId2
            );
        }
    }
    function getAnimalByIdVisibility(uint aid) public constant 
    returns (bool upforsale,bool upformating,bool eggphase,bool isbornbymating, 
    uint birthdate, uint costumeid, uint generationid)
    {
        return(
            animalAgainstId[aid].upForSale,
            animalAgainstId[aid].upForMating,
            animalAgainstId[aid].eggPhase,
            animalAgainstId[aid].isBornByMating,
            animalAgainstId[aid].birthdate,
            animalAgainstId[aid].costumeId,
            animalAgainstId[aid].generationId

			
            );
    }
    
     function getOwnerByAnimalId(uint aid) public constant 
    returns (address)
    {
        return token.ownerOf(aid);
            
    }
    
      
    function getAllAnimalsByAddress(address ad) public constant returns (uint[] listAnimals)
    {
        require (!isContractPaused);
        return token.getAnimalIdAgainstAddress(ad);
    }

      
    function claimFreeAnimalFromAnimalFactory( string animalName, string animalDesc) public
    {
        require(msg.sender != 0x0);
        require (!isContractPaused);
        uint gId=0;
         
        if (msg.sender!=owner)
        {
            require(token.getTotalTokensAgainstAddress(msg.sender)<freeAnimalsLimit);
            gId=1;
        }

         
        uniqueAnimalId++;
        
         
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
            upForSale: false,
            eggPhase: false,
            priceForSale:0,
            upForMating: false,
            priceForMating:0,
            isBornByMating: false,
            parentId1:0,
            parentId2:0,
            birthdate:now,
            costumeId:0, 
            generationId:gId,
			isSpecial:false
        });
        token.sendToken(msg.sender, uniqueAnimalId,animalName);
        
         
        animalAgainstId[uniqueAnimalId]=animalObject;
        totalBunniesCreated++;
    }
  
      
    function buyAnimalsFromAnimalFactory(string animalName, string animalDesc) public payable 
    {
        require (!isContractPaused);
        require(validPurchase());
        require(msg.sender != 0x0);
    
        uint gId=0;
         
        if (msg.sender!=owner)
        {
            gId=1;
        }

    
        uint256 weiAmount = msg.value;
        
         
        uint256 tokens = weiAmount.div(weiPerAnimal);
        
         
        weiRaised = weiRaised.add(weiAmount);

    
        uniqueAnimalId++;
         
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
            upForSale: false,
            priceForSale:0,
            upForMating: false,
            eggPhase: false,
            priceForMating:0,
            isBornByMating:false,
            parentId1:0,
            parentId2:0,
            birthdate:now,
            costumeId:0,
            generationId:gId,
			isSpecial:false
        });
          
          
         
        token.sendToken(msg.sender, uniqueAnimalId,animalName); 
        emit AnimalsPurchased(msg.sender, owner, weiAmount, tokens);
        
         
        animalAgainstId[uniqueAnimalId]=animalObject;
        
        
        totalBunniesCreated++;
        
         
        owner.transfer(msg.value);
    }
  
      
    function buyAnimalsFromUser(uint animalId) public payable 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        address prevOwner=token.ownerOf(animalId);
        
         
        require(prevOwner!=msg.sender);
        
         
        uint price=animalAgainstId[animalId].priceForSale;

         
        uint OwnerPercentage=animalAgainstId[animalId].priceForSale.mul(ownerPerThousandShareForBuying);
        OwnerPercentage=OwnerPercentage.div(1000);
        uint priceWithOwnerPercentage = animalAgainstId[animalId].priceForSale.add(OwnerPercentage);
        
         
        require(msg.value>=priceWithOwnerPercentage); 

         
        
     
        token.safeTransferFrom(prevOwner,msg.sender,animalId);

         
        animalAgainstId[animalId].upForSale=false;
        animalAgainstId[animalId].priceForSale=0;

         
        for (uint j=0;j<upForSaleList.length;j++)
        {
          if (upForSaleList[j] == animalId)
            delete upForSaleList[j];
        }      
        
         
        prevOwner.transfer(price);
        
         
        owner.transfer(OwnerPercentage);
        
         
        if(msg.value>priceWithOwnerPercentage)
        {
            msg.sender.transfer(msg.value.sub(priceWithOwnerPercentage));
        }
    }
  
      
    function mateAnimal(uint parent1Id, uint parent2Id, string animalName,string animalDesc) public payable 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
         
        require (token.ownerOf(parent2Id) == msg.sender);
        
         
        require(token.ownerOf(parent2Id)!=token.ownerOf(parent1Id));
        
         
        require(animalAgainstId[parent1Id].upForMating==true);
		
		require(animalAgainstId[parent1Id].isSpecial==false);
		require(animalAgainstId[parent2Id].isSpecial==false);
		

         
        uint price=animalAgainstId[parent1Id].priceForMating;
        
         
        uint OwnerPercentage=animalAgainstId[parent1Id].priceForMating.mul(ownerPerThousandShareForMating);
        OwnerPercentage=OwnerPercentage.div(1000);
        
        uint priceWithOwnerPercentage = animalAgainstId[parent1Id].priceForMating.add(OwnerPercentage);
        
         
        require(msg.value>=priceWithOwnerPercentage);
        uint generationnum = 1;

        if(animalAgainstId[parent1Id].generationId >= animalAgainstId[parent2Id].generationId)
        {
        generationnum = animalAgainstId[parent1Id].generationId+1;
        }
        else{
        generationnum = animalAgainstId[parent2Id].generationId+1;
        
        }
         
         uniqueAnimalId++;

         
        animalObject = AnimalProperties({
            id:uniqueAnimalId,
            name:animalName,
            desc:animalDesc,
            upForSale: false,
            priceForSale:0,
            upForMating: false,
            eggPhase: true,     
            priceForMating:0,
            isBornByMating:true,
            parentId1: parent1Id,
            parentId2: parent2Id,
            birthdate:now,
            costumeId:0,
            generationId:generationnum,
			isSpecial:false
          });
         
        token.sendToken(msg.sender,uniqueAnimalId,animalName);
         
        animalAgainstId[uniqueAnimalId]=animalObject;
         
        eggPhaseAnimalIds.push(uniqueAnimalId);
        
         
        childrenIdAgainstAnimalId[parent1Id].push(uniqueAnimalId);
        childrenIdAgainstAnimalId[parent2Id].push(uniqueAnimalId);

         
        for (uint i=0;i<upForMatingList.length;i++)
        {
            if (upForMatingList[i]==parent1Id)
                delete upForMatingList[i];   
        }
        
         
        animalAgainstId[parent1Id].upForMating = false;
        animalAgainstId[parent1Id].priceForMating = 0;
        
         
        token.ownerOf(parent1Id).transfer(price);
        
         
        owner.transfer(OwnerPercentage);
        
         
        if(msg.value>priceWithOwnerPercentage)
        {
            msg.sender.transfer(msg.value.sub(priceWithOwnerPercentage));
        }
        
    }

      
    function TransferAnimalToAnotherUser(uint animalId,address to) public 
    {
        require (!isContractPaused);
        require(msg.sender != 0x0);
        
         
        require(token.ownerOf(animalId)==msg.sender);
        
         
        require(animalAgainstId[animalId].upForSale == false);
        require(animalAgainstId[animalId].upForMating == false);
        token.safeTransferFrom(msg.sender, to, animalId);

        }
    
      
    function putSaleRequest(uint animalId, uint salePrice) public payable
    {
        require (!isContractPaused);
         
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForSaleAdvertisement);  
        }
        
         
        require(token.ownerOf(animalId)==msg.sender);
        
         
        require(animalAgainstId[animalId].eggPhase==false);

         
        require(animalAgainstId[animalId].upForSale==false);

         
        require(animalAgainstId[animalId].upForMating==false);
        
         
        animalAgainstId[animalId].upForSale=true;
        animalAgainstId[animalId].priceForSale=salePrice;
        upForSaleList.push(animalId);
        
         
        owner.transfer(msg.value);
    }
    
      
    function withdrawSaleRequest(uint animalId) public
    {
        require (!isContractPaused);
        
         
        require(token.ownerOf(animalId)==msg.sender);
        
         
        require(animalAgainstId[animalId].upForSale==true);

         
        animalAgainstId[animalId].upForSale=false;
        animalAgainstId[animalId].priceForSale=0;

         
        for (uint i=0;i<upForSaleList.length;i++)
        {
            if (upForSaleList[i]==animalId)
                delete upForSaleList[i];     
        }
    }

      
    function putMatingRequest(uint animalId, uint matePrice) public payable
    {
        require(!isContractPaused);
		
		require(animalAgainstId[animalId].isSpecial==false);

         
        if (msg.sender!=owner)
        {
            require(msg.value>=priceForMateAdvertisement);
        }
    
        require(token.ownerOf(animalId)==msg.sender);

         
        require(animalAgainstId[animalId].eggPhase==false);
        
         
        require(animalAgainstId[animalId].upForSale==false);
        
         
        require(animalAgainstId[animalId].upForMating==false);
        animalAgainstId[animalId].upForMating=true;
        animalAgainstId[animalId].priceForMating=matePrice;
        upForMatingList.push(animalId);

         
        owner.transfer(msg.value);
    }
    
      
    function withdrawMatingRequest(uint animalId) public
    {
        require(!isContractPaused);
        require(token.ownerOf(animalId)==msg.sender);
        require(animalAgainstId[animalId].upForMating==true);
        animalAgainstId[animalId].upForMating=false;
        animalAgainstId[animalId].priceForMating=0;
        for (uint i=0;i<upForMatingList.length;i++)
        {
            if (upForMatingList[i]==animalId)
                delete upForMatingList[i];    
        }
    }
  
     
    function validPurchase() internal constant returns (bool) 
    {
         
        if(msg.value.div(weiPerAnimal)<1)
            return false;
    
        uint quotient=msg.value.div(weiPerAnimal); 
   
        uint actualVal=quotient.mul(weiPerAnimal);
   
        if(msg.value>actualVal)
            return false;
        else 
            return true;
    }

     
    function showMyAnimalBalance() public view returns (uint256 tokenBalance) 
    {
        tokenBalance = token.balanceOf(msg.sender);
    }

      
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
        weiPerAnimal = newPrice;
    }
    
       
    function setMateAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
        priceForMateAdvertisement = newPrice;
    }
    
       
    function setSaleAdvertisementRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
        priceForSaleAdvertisement = newPrice;
    }
    
       
    function setBuyingCostumeRate(uint256 newPrice) public onlyOwner returns (bool) 
    {
        priceForBuyingCostume = newPrice;
    }
    
    
       
    function getAllMatingAnimals() public constant returns (uint[]) 
    {
        return upForMatingList;
    }
    
       
    function getAllSaleAnimals() public constant returns (uint[]) 
    {
        return upForSaleList;
    }
    
       
    function changeFreeAnimalsLimit(uint limit) public onlyOwner
    {
        freeAnimalsLimit = limit;
    }

          
    function changeOwnerSharePerThousandForBuying(uint buyshare) public onlyOwner
    {
        ownerPerThousandShareForBuying = buyshare;
    }
    
       
    function changeOwnerSharePerThousandForMating(uint mateshare) public onlyOwner
    {
        ownerPerThousandShareForMating = mateshare;
    }
    
       
    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
  
       
    function removeFromEggPhase(uint animalId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<eggPhaseAnimalIds.length;j++)
                {
                    if (eggPhaseAnimalIds[j]==animalId)
                    {
                        delete eggPhaseAnimalIds[j];
                    }
                }
                animalAgainstId[animalId].eggPhase = false;
            }
        }
    }
    
       
    function getChildrenAgainstAnimalId(uint id) public constant returns (uint[]) 
    {
        return childrenIdAgainstAnimalId[id];
    }
    
       
    function getEggPhaseList() public constant returns (uint[]) 
    {
        return eggPhaseAnimalIds;
    }
    
    
        
    function getAnimalIdsWithPendingCostume() public constant returns (uint[]) 
    {
        return animalIdsWithPendingCostumes;
    }
    
          
    function buyCostume(uint cId, uint aId) public payable 
    {
        require(msg.value>=priceForBuyingCostume);
        require(!isContractPaused);
        require(token.ownerOf(aId)==msg.sender);
        require(animalAgainstId[aId].costumeId==0);
        animalAgainstId[aId].costumeId=cId;
        animalIdsWithPendingCostumes.push(aId);
         
        owner.transfer(msg.value);
    }
    
    
       
    function approvePendingCostume(uint animalId) public
    {
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==msg.sender)
            {
                for (uint j=0;j<animalIdsWithPendingCostumes.length;j++)
                {
                    if (animalIdsWithPendingCostumes[j]==animalId)
                    {
                        delete animalIdsWithPendingCostumes[j];
                    }
                }
            }
        }
    }
    
       
    function addMember(address member) public onlyOwner 
    { 
        memberAddresses.push(member);
    }
  
       
    function listMembers() public constant returns (address[]) 
    { 
        return memberAddresses;
    }
    
       
    function deleteMember(address member) public onlyOwner 
    { 
        for (uint i=0;i<memberAddresses.length;i++)
        {
            if (memberAddresses[i]==member)
            {
                delete memberAddresses[i];
            }
        }
    }
       
    function updateAnimal(uint animalId, string name, string desc) public  
    { 
        require(msg.sender==token.ownerOf(animalId));
        animalAgainstId[animalId].name=name;
        animalAgainstId[animalId].desc=desc;
        token.setAnimalMeta(animalId, name);
    }
	
	       
    function updateAnimalSpecial(uint animalId, bool isSpecial) public onlyOwner 
    { 
        require(msg.sender==token.ownerOf(animalId));
        animalAgainstId[animalId].isSpecial=isSpecial;
        
    }
   
}
 

pragma solidity 0.4.21;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract PetitionFactory is Ownable {

    using SafeMath for uint;

    event NewPetition(uint petitionId, string name, string message, address creator, uint signaturesNeeded, bool featured, uint featuredExpires, uint totalSignatures, uint created, string connectingHash, uint advertisingBudget);
    event NewPetitionSigner(uint petitionSignerId, uint petitionId, address petitionSignerAddress, uint signed);
    event NewPetitionShareholder(uint PetitionShareholderId, address PetitionShareholderAddress, uint shares, uint sharesListedForSale, uint lastDividend);
    event DividendClaim(uint divId, uint PetitionShareholderId, uint amt, uint time, address userAddress);
    event NewShareholderListing(uint shareholderListingId, uint petitionShareholderId, uint sharesForSale, uint price, bool sold);

    struct Petition {
        string name;
        string message;
        address creator;
        uint signaturesNeeded;
        bool featured;
        uint featuredExpires;
        uint totalSignatures;
        uint created;
        string connectingHash;
        uint advertisingBudget;  
    }

    struct PetitionSigner {
        uint petitionId;
        address petitionSignerAddress;
        uint signed;
    }

    struct PetitionShareholder {
        address PetitionShareholderAddress;
        uint shares;
        uint sharesListedForSale;  
        uint lastDividend;
    }

    struct DividendHistory {
        uint PetitionShareholderId;
        uint amt;
        uint time;
        address userAddress;
    }

    struct ShareholderListing {
        uint petitionShareholderId;
        uint sharesForSale;
        uint price;
        bool sold;
    }

    Petition[] public petitions;

    PetitionSigner[] public petitionsigners;
    mapping(address => mapping(uint => uint)) ownerPetitionSignerArrayCreated;
    mapping(address => mapping(uint => uint)) petitionSignerMap;

    PetitionShareholder[] public PetitionShareholders;
    mapping(address => uint) ownerPetitionShareholderArrayCreated;
    mapping(address => uint) PetitionShareholderMap;

    DividendHistory[] public divs;

    ShareholderListing[] public listings;

    uint createPetitionFee = 1000000000000000;  
    uint featurePetitionFee = 100000000000000000;  
    uint featuredLength = 604800;  

     
     

     

    uint sharesSold = 0;

    uint maxShares = 5000000;  

     
    uint initialPricePerShare  = 5000000000000000;  
         
         
         
         
         
         
    
    uint initialOwnerSharesClaimed = 0;  
    address ownerShareAddress;

    uint dividendCooldown = 604800;  

    uint peerToPeerMarketplaceTransactionFee = 100;  

    uint dividendPoolStarts = 0;
    uint dividendPoolEnds = 0;
    uint claimableDividendPool = 0;  
    uint claimedThisPool = 0;
    uint currentDividendPool = 0;  

    uint availableForWithdraw = 0;

     
     

    function invest() payable public {
        require(sharesSold < maxShares);
         
        uint numberOfShares = SafeMath.div(msg.value, initialPricePerShare);  

         
        uint numberOfSharesBonus;
        uint numberOfSharesBonusOne;
        uint numberOfSharesBonusTwo;
        if (msg.value >= 1000000000000000000000) {  
            numberOfSharesBonus = SafeMath.div(numberOfShares, 2);  
            numberOfShares = SafeMath.add(numberOfShares, numberOfSharesBonus);

        } else if (msg.value >= 500000000000000000000) {  
            numberOfSharesBonusOne = SafeMath.div(numberOfShares, 5);  
            numberOfSharesBonusTwo = SafeMath.div(numberOfShares, 5);  
            numberOfShares = numberOfShares + numberOfSharesBonusOne + numberOfSharesBonusTwo;  

        } else if (msg.value >= 100000000000000000000) {  
            numberOfSharesBonusOne = SafeMath.div(numberOfShares, 5);  
            numberOfSharesBonusTwo = SafeMath.div(numberOfShares, 10);  
            numberOfShares = numberOfShares + numberOfSharesBonusOne + numberOfSharesBonusTwo;  
        
        } else if (msg.value >= 50000000000000000000) {  
            numberOfSharesBonus = SafeMath.div(numberOfShares, 5);  
            numberOfShares = numberOfShares + numberOfSharesBonus;  

        } else if (msg.value >= 10000000000000000000) {  
            numberOfSharesBonus = SafeMath.div(numberOfShares, 10);  
            numberOfShares = numberOfShares + numberOfSharesBonus;  
        
        }

        require((numberOfShares + sharesSold) < maxShares);

        if (ownerPetitionShareholderArrayCreated[msg.sender] == 0) {
             
            uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, numberOfShares, 0, now)) - 1;
            emit NewPetitionShareholder(id, msg.sender, numberOfShares, 0, now);
            PetitionShareholderMap[msg.sender] = id;
            ownerPetitionShareholderArrayCreated[msg.sender] = 1;
            
            sharesSold = sharesSold + numberOfShares;

            availableForWithdraw = availableForWithdraw + msg.value;

        } else {
             
            PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares + numberOfShares;
            
            sharesSold = sharesSold + numberOfShares;

            availableForWithdraw = availableForWithdraw + msg.value;

        }

         
        endDividendPool();

    }

    function viewSharesSold() public view returns(uint) {
        return sharesSold;
    }

    function viewMaxShares() public view returns(uint) {
        return maxShares;
    }

    function viewPetitionShareholderWithAddress(address _investorAddress) view public returns (uint, address, uint, uint) {
        require (ownerPetitionShareholderArrayCreated[_investorAddress] > 0);

        PetitionShareholder storage investors = PetitionShareholders[PetitionShareholderMap[_investorAddress]];
        return (PetitionShareholderMap[_investorAddress], investors.PetitionShareholderAddress, investors.shares, investors.lastDividend);
    }

    function viewPetitionShareholder(uint _PetitionShareholderId) view public returns (uint, address, uint, uint) {
        PetitionShareholder storage investors = PetitionShareholders[_PetitionShareholderId];
        return (_PetitionShareholderId, investors.PetitionShareholderAddress, investors.shares, investors.lastDividend);
    }

     
     

    function endDividendPool() public {
         
        if (now > dividendPoolEnds) {

             
            availableForWithdraw = availableForWithdraw + (claimableDividendPool - claimedThisPool);

             
            claimableDividendPool = currentDividendPool;
            claimedThisPool = 0;

             
            currentDividendPool = 0;

             
            dividendPoolStarts = now;
            dividendPoolEnds = (now + dividendCooldown);

        }

    }

    function collectDividend() payable public {
        require (ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require ((PetitionShareholders[PetitionShareholderMap[msg.sender]].lastDividend + dividendCooldown) < now);
        require (claimableDividendPool > 0);

         
        uint divAmt = claimableDividendPool / (sharesSold / PetitionShareholders[PetitionShareholderMap[msg.sender]].shares);

        claimedThisPool = claimedThisPool + divAmt;

         
        PetitionShareholders[PetitionShareholderMap[msg.sender]].lastDividend = now;

         
        PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress.transfer(divAmt);

        uint id = divs.push(DividendHistory(PetitionShareholderMap[msg.sender], divAmt, now, PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress)) - 1;
        emit DividendClaim(id, PetitionShareholderMap[msg.sender], divAmt, now, PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress);
    }

    function viewInvestorDividendHistory(uint _divId) public view returns(uint, uint, uint, uint, address) {
        return(_divId, divs[_divId].PetitionShareholderId, divs[_divId].amt, divs[_divId].time, divs[_divId].userAddress);
    }

    function viewInvestorDividendPool() public view returns(uint) {
        return currentDividendPool;
    }

    function viewClaimableInvestorDividendPool() public view returns(uint) {
        return claimableDividendPool;
    }

    function viewClaimedThisPool() public view returns(uint) {
        return claimedThisPool;
    }

    function viewLastClaimedDividend(address _address) public view returns(uint) {
        return PetitionShareholders[PetitionShareholderMap[_address]].lastDividend;
    }

    function ViewDividendPoolEnds() public view returns(uint) {
        return dividendPoolEnds;
    }

    function viewDividendCooldown() public view returns(uint) {
        return dividendCooldown;
    }


     
    function transferShares(uint _amount, address _to) public {
        require(ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require((PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale) >= _amount);

         
        if (ownerPetitionShareholderArrayCreated[_to] == 0) {
             
            uint id = PetitionShareholders.push(PetitionShareholder(_to, _amount, 0, now)) - 1;
            emit NewPetitionShareholder(id, _to, _amount, 0, now);
            PetitionShareholderMap[_to] = id;
            ownerPetitionShareholderArrayCreated[_to] = 1;

        } else {
             
            PetitionShareholders[PetitionShareholderMap[_to]].shares = PetitionShareholders[PetitionShareholderMap[_to]].shares + _amount;

        }

         
        PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - _amount;
        PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale = PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale - _amount;

         
        endDividendPool();

    }

     
    function listSharesForSale(uint _amount, uint _price) public {
        require(ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require((PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale) >= _amount);
        
        PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale = PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale + _amount;

        uint id = listings.push(ShareholderListing(PetitionShareholderMap[msg.sender], _amount, _price, false)) - 1;
        emit NewShareholderListing(id, PetitionShareholderMap[msg.sender], _amount, _price, false);

         
        endDividendPool();
        
    }

    function viewShareholderListing(uint _shareholderListingId)view public returns (uint, uint, uint, uint, bool) {
        ShareholderListing storage listing = listings[_shareholderListingId];
        return (_shareholderListingId, listing.petitionShareholderId, listing.sharesForSale, listing.price, listing.sold);
    }

    function removeShareholderListing(uint _shareholderListingId) public {
        ShareholderListing storage listing = listings[_shareholderListingId];
        require(PetitionShareholderMap[msg.sender] == listing.petitionShareholderId);

        PetitionShareholders[listing.petitionShareholderId].sharesListedForSale = PetitionShareholders[listing.petitionShareholderId].sharesListedForSale - listing.sharesForSale;

        delete listings[_shareholderListingId];

         
        endDividendPool();
        
    }

    function buySharesFromListing(uint _shareholderListingId) payable public {
        ShareholderListing storage listing = listings[_shareholderListingId];
        require(msg.value >= listing.price);
        require(listing.sold == false);
        require(listing.sharesForSale > 0);
        
         
        if (ownerPetitionShareholderArrayCreated[msg.sender] == 0) {
             
            uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, listing.sharesForSale, 0, now)) - 1;
            emit NewPetitionShareholder(id, msg.sender, listing.sharesForSale, 0, now);
            PetitionShareholderMap[msg.sender] = id;
            ownerPetitionShareholderArrayCreated[msg.sender] = 1;

        } else {
             
            PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares + listing.sharesForSale;

        }

        listing.sold = true;

         
        PetitionShareholders[listing.petitionShareholderId].shares = PetitionShareholders[listing.petitionShareholderId].shares - listing.sharesForSale;
        PetitionShareholders[listing.petitionShareholderId].sharesListedForSale = PetitionShareholders[listing.petitionShareholderId].sharesListedForSale - listing.sharesForSale;

         
        uint calcFee = SafeMath.div(msg.value, peerToPeerMarketplaceTransactionFee);
        cutToInvestorsDividendPool(calcFee);

         
        uint toSeller = SafeMath.sub(msg.value, calcFee);
        PetitionShareholders[listing.petitionShareholderId].PetitionShareholderAddress.transfer(toSeller);

         
        endDividendPool();

    }

     
     

    function createPetition(string _name, string _message, uint _signaturesNeeded, bool _featured, string _connectingHash) payable public {
        require(msg.value >= createPetitionFee);
        uint featuredExpires = 0;
        uint totalPaid = createPetitionFee;
        if (_featured) {
            require(msg.value >= (createPetitionFee + featurePetitionFee));
            featuredExpires = now + featuredLength;
            totalPaid = totalPaid + featurePetitionFee;
        }

         
         
        cutToInvestorsDividendPool(totalPaid);

         

        uint id = petitions.push(Petition(_name, _message, msg.sender, _signaturesNeeded, _featured, featuredExpires, 0, now, _connectingHash, 0)) - 1;
        emit NewPetition(id, _name, _message, msg.sender, _signaturesNeeded, _featured, featuredExpires, 0, now, _connectingHash, 0);

    }

    function renewFeatured(uint _petitionId) payable public {
        require(msg.value >= featurePetitionFee);

        uint featuredExpires = 0;
        if (now > petitions[_petitionId].featuredExpires) {
            featuredExpires = now + featuredLength;
        }else {
            featuredExpires = petitions[_petitionId].featuredExpires + featuredLength;
        }

        petitions[_petitionId].featuredExpires = featuredExpires;

         
         
        cutToInvestorsDividendPool(msg.value);

    }

    function viewPetition(uint _petitionId) view public returns (uint, string, string, address, uint, bool, uint, uint, uint, string, uint) {
        Petition storage petition = petitions[_petitionId];
        return (_petitionId, petition.name, petition.message, petition.creator, petition.signaturesNeeded, petition.featured, petition.featuredExpires, petition.totalSignatures, petition.created, petition.connectingHash, petition.advertisingBudget);
    }

    function viewPetitionSignerWithAddress(address _ownerAddress, uint _petitionId) view public returns (uint, uint, address, uint) {
        require (ownerPetitionSignerArrayCreated[_ownerAddress][_petitionId] > 0);

        PetitionSigner storage signers = petitionsigners[petitionSignerMap[_ownerAddress][_petitionId]];
        return (petitionSignerMap[_ownerAddress][_petitionId], signers.petitionId, signers.petitionSignerAddress, signers.signed);
    }

    function viewPetitionSigner(uint _petitionSignerId) view public returns (uint, uint, address, uint) {
        PetitionSigner storage signers = petitionsigners[_petitionSignerId];
        return (_petitionSignerId, signers.petitionId, signers.petitionSignerAddress, signers.signed);
    }

    function advertisingDeposit (uint _petitionId) payable public {
        petitions[_petitionId].advertisingBudget = SafeMath.add(petitions[_petitionId].advertisingBudget, msg.value);

         
         
        cutToInvestorsDividendPool(msg.value);

    }

    function cutToInvestorsDividendPool(uint totalPaid) internal {
         
         

         
         
         
         
         
         
         
         

        currentDividendPool = SafeMath.add(currentDividendPool, totalPaid);

         
        endDividendPool();

    }

    function advertisingUse (uint _petitionId, uint amount) public {
        require(petitions[_petitionId].creator == msg.sender);
        require(petitions[_petitionId].advertisingBudget >= amount);
         
        petitions[_petitionId].advertisingBudget = petitions[_petitionId].advertisingBudget - amount;

    }

     
     

    function sign (uint _petitionId) public {
         
        require (keccak256(petitions[_petitionId].name) != keccak256(""));
        require (ownerPetitionSignerArrayCreated[msg.sender][_petitionId] == 0);

         
            
        uint id = petitionsigners.push(PetitionSigner(_petitionId, msg.sender, now)) - 1;
        emit NewPetitionSigner(id, _petitionId, msg.sender, now);
        petitionSignerMap[msg.sender][_petitionId] = id;
        ownerPetitionSignerArrayCreated[msg.sender][_petitionId] = 1;
        
        petitions[_petitionId].totalSignatures = petitions[_petitionId].totalSignatures + 1;

         

         
        endDividendPool();

    }

     
     

    function unsign (uint _petitionId) public {
        require (ownerPetitionSignerArrayCreated[msg.sender][_petitionId] == 1);

        ownerPetitionSignerArrayCreated[msg.sender][_petitionId] = 0;

        petitions[_petitionId].totalSignatures = petitions[_petitionId].totalSignatures - 1;

        delete petitionsigners[petitionSignerMap[msg.sender][_petitionId]];

        delete petitionSignerMap[msg.sender][_petitionId];

    }

     
     

    function initialOwnersShares() public onlyOwner(){
        require(initialOwnerSharesClaimed == 0);

        uint numberOfShares = 1000000;

        uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, numberOfShares, 0, now)) - 1;
        emit NewPetitionShareholder(id, msg.sender, numberOfShares, 0, now);
        PetitionShareholderMap[msg.sender] = id;
        ownerPetitionShareholderArrayCreated[msg.sender] = 1;
        
        sharesSold = sharesSold + numberOfShares;

        ownerShareAddress = msg.sender;

         
        dividendPoolStarts = now;
        dividendPoolEnds = (now + dividendCooldown);

        initialOwnerSharesClaimed = 1;  
    }

    function companyShares() public view returns(uint){
        return PetitionShareholders[PetitionShareholderMap[ownerShareAddress]].shares;
    }
    
    function alterDividendCooldown (uint _dividendCooldown) public onlyOwner() {
        dividendCooldown = _dividendCooldown;
    }

    function spendAdvertising(uint _petitionId, uint amount) public onlyOwner() {
        require(petitions[_petitionId].advertisingBudget >= amount);

        petitions[_petitionId].advertisingBudget = petitions[_petitionId].advertisingBudget - amount;
    }

    function viewFeaturedLength() public view returns(uint) {
        return featuredLength;
    }

    function alterFeaturedLength (uint _newFeaturedLength) public onlyOwner() {
        featuredLength = _newFeaturedLength;
    }

    function viewInitialPricePerShare() public view returns(uint) {
        return initialPricePerShare;
    }

    function alterInitialPricePerShare (uint _initialPricePerShare) public onlyOwner() {
        initialPricePerShare = _initialPricePerShare;
    }

    function viewCreatePetitionFee() public view returns(uint) {
        return createPetitionFee;
    }

    function alterCreatePetitionFee (uint _createPetitionFee) public onlyOwner() {
        createPetitionFee = _createPetitionFee;
    }

    function alterPeerToPeerMarketplaceTransactionFee (uint _peerToPeerMarketplaceTransactionFee) public onlyOwner() {
        peerToPeerMarketplaceTransactionFee = _peerToPeerMarketplaceTransactionFee;
    }

    function viewPeerToPeerMarketplaceTransactionFee() public view returns(uint) {
        return peerToPeerMarketplaceTransactionFee;
    }

    function viewFeaturePetitionFee() public view returns(uint) {
        return featurePetitionFee;
    }

    function alterFeaturePetitionFee (uint _featurePetitionFee) public onlyOwner() {
        featurePetitionFee = _featurePetitionFee;
    }

    function withdrawFromAmt() public view returns(uint) {
        return availableForWithdraw;
    }

    function withdrawFromContract(address _to, uint _amount) payable external onlyOwner() {
        require(_amount <= availableForWithdraw);
        availableForWithdraw = availableForWithdraw - _amount;
        _to.transfer(_amount);

         
        endDividendPool();

    }

     

}
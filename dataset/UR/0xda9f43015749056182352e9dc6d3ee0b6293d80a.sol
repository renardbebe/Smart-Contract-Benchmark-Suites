 

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



 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
     
    function tuneLambo(uint256 _newattributes, uint256 _tokenId) external;
    function getLamboAttributes(uint256 _id) external view returns (uint256 attributes);
    function getLamboModel(uint256 _tokenId) external view returns (uint64 _model);
     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}



 
 
 
contract EtherLambosAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}



 
 
 
contract EtherLambosBase is EtherLambosAccessControl {
     

     
    event Build(address owner, uint256 lamboId, uint256 attributes);

     
     
    event Transfer(address from, address to, uint256 tokenId);

    event Tune(uint256 _newattributes, uint256 _tokenId);
    
     

     
     
     
     
     
    struct Lambo {
         
         
        uint256 attributes;

         
        uint64 buildTime;
        
         
        uint64 model;

    }


     
    uint256 public secondsPerBlock = 15;

     

     
     
    Lambo[] lambos;

     
     
    mapping (uint256 => address) public lamboIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public lamboIndexToApproved;

     
     
    MarketPlace public marketPlace;
    ServiceStation public serviceStation;
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        lamboIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete lamboIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
    function _createLambo(
        uint256 _attributes,
        address _owner,
        uint64  _model
    )
        internal
        returns (uint)
    {

        
        Lambo memory _lambo = Lambo({
            attributes: _attributes,
            buildTime: uint64(now),
            model:_model
        });
        uint256 newLamboId = lambos.push(_lambo) - 1;

         
         
        require(newLamboId == uint256(uint32(newLamboId)));

         
        Build(
            _owner,
            newLamboId,
            _lambo.attributes
        );

         
         
        _transfer(0, _owner, newLamboId);

        return newLamboId;
    }
      
     
     
     
     
    function _tuneLambo(
        uint256 _newattributes,
        uint256 _tokenId
    )
        internal
    {
        lambos[_tokenId].attributes=_newattributes;
     
         
        Tune(
            _tokenId,
            _newattributes
        );

    }
     
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
         
        secondsPerBlock = secs;
    }
}

 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

 
 
 

contract EtherLambosOwnership is EtherLambosBase, ERC721 {

     
    string public constant name = "EtherLambos";
    string public constant symbol = "EL";

     
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return lamboIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return lamboIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        lamboIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(marketPlace));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return lambos.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = lamboIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCars = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 carId;

            for (carId = 1; carId <= totalCars; carId++) {
                if (lamboIndexToOwner[carId] == _owner) {
                    result[resultIndex] = carId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function _memcpy(uint _dest, uint _src, uint _len) private view {
         
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

         
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

     
     
     
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}


 
 
 
contract MarketPlaceBase is Ownable {

     
    struct Sale {
         
        address seller;
         
        uint128 price;
         
         
        uint64 startedAt;
    }
    
    struct Affiliates {
        address affiliate_address;
        uint64 commission;
        uint64 pricecut;
    }
    
     
     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Affiliates) codeToAffiliate;

     
    mapping (uint256 => Sale) tokenIdToSale;

    event SaleCreated(uint256 tokenId, uint256 price);
    event SaleSuccessful(uint256 tokenId, uint256 price, address buyer);
    event SaleCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addSale(uint256 _tokenId, Sale _sale) internal {
        

        tokenIdToSale[_tokenId] = _sale;

        SaleCreated(
            uint256(_tokenId),
            uint256(_sale.price)
        );
    }

     
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        SaleCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Sale storage sale = tokenIdToSale[_tokenId];

         
         
         
         
        require(_isOnSale(sale));

         
        uint256 price = sale.price;
        require(_bidAmount >= price);

         
         
        address seller = sale.seller;

         
         
        _removeSale(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 marketplaceCut = _computeCut(price);
            uint256 sellerProceeds = price - marketplaceCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        SaleSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

     
     
    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }


     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }
    function _computeAffiliateCut(uint256 _price,Affiliates affiliate) internal view returns (uint256) {
         
         
         
         
         
        return _price * affiliate.commission / 10000;
    }
     
     
     
    function _addAffiliate(uint256 _code, Affiliates _affiliate) internal {
        codeToAffiliate[_code] = _affiliate;
   
    }
    
     
     
    function _removeAffiliate(uint256 _code) internal {
        delete codeToAffiliate[_code];
    }
    
    
     
     
     
    function _bidReferral(uint256 _tokenId, uint256 _bidAmount,Affiliates _affiliate)
        internal
        returns (uint256)
    {
        
         
        Sale storage sale = tokenIdToSale[_tokenId];

         
        require(sale.seller==owner);

         
         
         
         
        require(_isOnSale(sale));
         
        
        uint256 price = sale.price;
        
         
        price=price * _affiliate.pricecut / 10000;  
        require(_bidAmount >= price);

         
         
        address seller = sale.seller;
        address affiliate_address = _affiliate.affiliate_address;
        
         
         
        _removeSale(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 affiliateCut = _computeAffiliateCut(price,_affiliate);
            uint256 sellerProceeds = price - affiliateCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
            affiliate_address.transfer(affiliateCut);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        SaleSuccessful(_tokenId, price, msg.sender);

        return price;
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

 
 
contract MarketPlace is Pausable, MarketPlaceBase {

	 
     
    bool public isMarketplace = true;
	
     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function MarketPlace(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
         
        nonFungibleContract = candidateContract;
    }
    function setNFTAddress(address _nftAddress, uint256 _cut) external onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
        ERC721 candidateContract = ERC721(_nftAddress);
         
        nonFungibleContract = candidateContract;
    }
     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        bool res = nftAddress.send(this.balance);
    }

     
     
     
     
    function createSale(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
    {
         
         
        require(_price == uint256(uint128(_price)));
        
         
         
        
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        
        Sale memory sale = Sale(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addSale(_tokenId, sale);
    }


    

     
     
     
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
         
       _bid(_tokenId, msg.value); 
       _transfer(msg.sender, _tokenId);
      
    }

     
     
     
    function bidReferral(uint256 _tokenId,uint256 _code)
        external
        payable
        whenNotPaused
    {
         
        Affiliates storage affiliate = codeToAffiliate[_code];
        
        require(affiliate.affiliate_address!=0&&_code>0);
        _bidReferral(_tokenId, msg.value,affiliate);
        _transfer(msg.sender, _tokenId);

       
    }
    
     
     
     
     
     
    function cancelSale(uint256 _tokenId)
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

     
     
     
     
    function cancelSaleWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        _cancelSale(_tokenId, sale.seller);
    }

     
     
    function getSale(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 price,
        uint256 startedAt
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.price,
            sale.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return sale.price;
    }


     
     
     
     
     
    function createAffiliate(
        uint256 _code,
        uint64  _commission,
        uint64  _pricecut,
        address _affiliate_address
    )
        external
        onlyOwner
    {

        Affiliates memory affiliate = Affiliates(
            address(_affiliate_address),
            uint64(_commission),
            uint64(_pricecut)
        );
        _addAffiliate(_code, affiliate);
    }
    
     
     
    function getAffiliate(uint256 _code)
        external
        view
        onlyOwner
        returns
    (
         address affiliate_address,
         uint64 commission,
         uint64 pricecut
    ) {
        Affiliates storage affiliate = codeToAffiliate[_code];
        
        return (
            affiliate.affiliate_address,
            affiliate.commission,
            affiliate.pricecut
        );
    }
      
     
     
    function removeAffiliate(uint256 _code)
        onlyOwner
        external
    {
        _removeAffiliate(_code); 
        
    }
}


 
 
contract ServiceStationBase {

     
    ERC721 public nonFungibleContract;

    struct Tune{
        uint256 startChange;
        uint256 rangeChange;
        uint256 attChange;
        bool plusMinus;
        bool replace;
        uint128 price;
        bool active;
        uint64 model;
    }
    Tune[] options;
    
   
    
     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }
  
     
    function _tune(uint256 _newattributes, uint256 _tokenId) internal {
    nonFungibleContract.tuneLambo(_newattributes, _tokenId);
    }
    
    function _changeAttributes(uint256 _tokenId,uint256 _optionIndex) internal {
    
     
    uint64 model = nonFungibleContract.getLamboModel(_tokenId);
     
    require(options[_optionIndex].model==model);
    
     
    uint256 attributes = nonFungibleContract.getLamboAttributes(_tokenId);
    uint256 part=0;
    
     
    part=(attributes/(10 ** options[_optionIndex].startChange)) % (10 ** options[_optionIndex].rangeChange);
     
     
     
    if(options[_optionIndex].replace == false)
        {
            
             
            if(options[_optionIndex].plusMinus == false)
            {
                 
                require((part+options[_optionIndex].attChange)<(10**options[_optionIndex].rangeChange));
                 
                attributes=attributes+options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
            }
            else{
                 
                 
                require(part>options[_optionIndex].attChange);
                 
                attributes-=options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
            }
        }
    else
        {
             
            attributes=attributes-part*(10 ** options[_optionIndex].startChange);
            attributes+=options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
        }
    
  
   
     
    _tune(uint256(attributes), _tokenId);
       
        
    }
    
    
}


 
contract ServiceStation is Pausable, ServiceStationBase {

	 
    bool public isServicestation = true;
	
     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    uint256 public optionCount;
    mapping (uint64 => uint256) public modelIndexToOptionCount;
     
     
     
     
    function ServiceStation(address _nftAddress) public {

        ERC721 candidateContract = ERC721(_nftAddress);
         
        nonFungibleContract = candidateContract;
        _newTuneOption(0,0,0,false,false,0,0);
        
    }
    function setNFTAddress(address _nftAddress) external onlyOwner {
        
        ERC721 candidateContract = ERC721(_nftAddress);
         
        nonFungibleContract = candidateContract;
    }
    
    function newTuneOption(
        uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        uint64 _model
        )
        external
        {
            
           require(msg.sender == owner ); 
           optionCount++;
           modelIndexToOptionCount[_model]++;
           _newTuneOption(_startChange,_rangeChange,_attChange,_plusMinus, _replace,_price,_model);
       
        }
    function changeTuneOption(
        uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        bool _isactive,
        uint64 _model,
        uint256 _optionIndex
        )
        external
        {
            
           require(msg.sender == owner ); 
           
           
           _changeTuneOption(_startChange,_rangeChange,_attChange,_plusMinus, _replace,_price,_isactive,_model,_optionIndex);
       
        }
        
    function _newTuneOption( uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        uint64 _model
        ) 
        internal
        {
        
           Tune memory _option = Tune({
            startChange: _startChange,
            rangeChange: _rangeChange,
            attChange: _attChange,
            plusMinus: _plusMinus,
            replace: _replace,
            price: _price,
            active: true,
            model: _model
            });
        
        options.push(_option);
    }
    
    function _changeTuneOption( uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        bool _isactive,
        uint64 _model,
        uint256 _optionIndex
        ) 
        internal
        {
        
           Tune memory _option = Tune({
            startChange: _startChange,
            rangeChange: _rangeChange,
            attChange: _attChange,
            plusMinus: _plusMinus,
            replace: _replace,
            price: _price,
            active: _isactive,
            model: _model
            });
        
        options[_optionIndex]=_option;
    }
    
    function disableTuneOption(uint256 index) external
    {
        require(msg.sender == owner ); 
        options[index].active=false;
    }
    
    function enableTuneOption(uint256 index) external
    {
        require(msg.sender == owner ); 
        options[index].active=true;
    }
    function getOption(uint256 _index) 
    external view
    returns (
        uint256 _startChange,
        uint256 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        uint128 _price,
        bool active,
        uint64 model
    ) 
    {
      
         
        return (
            options[_index].startChange,
            options[_index].rangeChange,
            options[_index].attChange,
            options[_index].plusMinus,
            options[_index].price,
            options[_index].active,
            options[_index].model
        );  
    }
    
    function getOptionCount() external view returns (uint256 _optionCount)
        {
        return optionCount;    
        }
    
    function tuneLambo(uint256 _tokenId,uint256 _optionIndex) external payable
    {
        
       require(_owns(msg.sender, _tokenId)); 
        
       require(options[_optionIndex].active);
        
       require(msg.value>=options[_optionIndex].price);
       
       _changeAttributes(_tokenId,_optionIndex);
    }
     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        bool res = owner.send(this.balance);
    }

    function getOptionsForModel(uint64 _model) external view returns(uint256[] _optionsModel) {
         

         
             
         
         
            uint256[] memory result = new uint256[](modelIndexToOptionCount[_model]);
             
            uint256 resultIndex = 0;

             
             
            uint256 optionId;

            for (optionId = 1; optionId <= optionCount; optionId++) {
                if (options[optionId].model == _model && options[optionId].active == true) {
                    result[resultIndex] = optionId;
                    resultIndex++;
                }
            }

            return result;
        
    }

}



 
 

 
 
 
contract EtherLambosSale is EtherLambosOwnership {

     
     
     
   

     
     
    function setMarketplaceAddress(address _address) external onlyCEO {
        MarketPlace candidateContract = MarketPlace(_address);

         
        require(candidateContract.isMarketplace());

         
        marketPlace = candidateContract;
    }


     
     
    function createLamboSale(
        uint256 _carId,
        uint256 _price
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _carId));
        
        _approve(_carId, marketPlace);
         
         
        marketPlace.createSale(
            _carId,
            _price,
            msg.sender
        );
    }
    
    
    function bulkCreateLamboSale(
        uint256 _price,
        uint256 _tokenIdStart,
        uint256 _tokenCount
    )
        external
        onlyCOO
    {
         
         
         
        for(uint256 i=0;i<_tokenCount;i++)
            {
            require(_owns(msg.sender, _tokenIdStart+i));
        
            _approve(_tokenIdStart+i, marketPlace);
             
             
            marketPlace.createSale(
                _tokenIdStart+i,
                _price,
             msg.sender
            );
        }
    }
     
     
     
    function withdrawSaleBalances() external onlyCLevel {
        marketPlace.withdrawBalance();
        
    }
}

 
contract EtherLambosBuilding is EtherLambosSale {

     
     
     


     
    uint256 public lambosBuildCount;


     
     
     
     
    function createLambo(uint256 _attributes, address _owner, uint64 _model) external onlyCOO {
        address lamboOwner = _owner;
        if (lamboOwner == address(0)) {
             lamboOwner = cooAddress;
        }
         

        lambosBuildCount++;
        _createLambo(_attributes, lamboOwner, _model);
    }

    function bulkCreateLambo(uint256 _attributes, address _owner, uint64 _model,uint256 count, uint256 startNo) external onlyCOO {
        address lamboOwner = _owner;
        uint256 att=_attributes;
        if (lamboOwner == address(0)) {
             lamboOwner = cooAddress;
        }
        
         
             
        
        
         
        for(uint256 i=0;i<count;i++)
            {
            lambosBuildCount++;
            att=_attributes+(startNo+i)*(10 ** 66);
            _createLambo(att, lamboOwner, _model);
            }
    }
}

 
contract EtherLambosTuning is EtherLambosBuilding {

     
    uint256 public lambosTuneCount;

    function setServicestationAddress(address _address) external onlyCEO {
        ServiceStation candidateContract = ServiceStation(_address);

         
        require(candidateContract.isServicestation());

         
        serviceStation = candidateContract;
    }
     
     
     
    function tuneLambo(uint256 _newattributes, uint256 _tokenId) external {
        
         
        require(
            msg.sender == address(serviceStation)
        );
        
        
        lambosTuneCount++;
        _tuneLambo(_newattributes, _tokenId);
    }
    function withdrawTuneBalances() external onlyCLevel {
        serviceStation.withdrawBalance();
        
    }

}

 
 
 
contract EtherLambosCore is EtherLambosTuning {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    function EtherLambosCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        _createLambo(uint256(-1), address(0),0);
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(marketPlace)
        );
    }

     
     
    function getLambo(uint256 _id)
        external
        view
        returns (
        uint256 buildTime,
        uint256 attributes
    ) {
        Lambo storage kit = lambos[_id];

        buildTime = uint256(kit.buildTime);
        attributes = kit.attributes;
    }
     
     
    function getLamboAttributes(uint256 _id)
        external
        view
        returns (
        uint256 attributes
    ) {
        Lambo storage kit = lambos[_id];
        attributes = kit.attributes;
        return attributes;
    }
    
     
     
    function getLamboModel(uint256 _id)
        external
        view
        returns (
        uint64 model
    ) {
        Lambo storage kit = lambos[_id];
        model = kit.model;
        return model;
    }
     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(marketPlace != address(0));
        require(serviceStation != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.send(balance);
     
    }
}
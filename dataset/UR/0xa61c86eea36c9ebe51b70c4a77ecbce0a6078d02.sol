 

pragma solidity ^0.4.18;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
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

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract TrueloveAccessControl {
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

contract TrueloveBase is TrueloveAccessControl {
	Diamond[] diamonds;
	mapping (uint256 => address) public diamondIndexToOwner;
	mapping (address => uint256) ownershipTokenCount;
	mapping (uint256 => address) public diamondIndexToApproved;

	mapping (address => uint256) public flowerBalances;

	struct Diamond {
		bytes24 model;
		uint16 year;
		uint16 no;
		uint activateAt;
	}

	struct Model {
		bytes24 model;
		uint current;
		uint total;
		uint16 year;
		uint256 price;
	}

	Model diamond1;
	Model diamond2;
	Model diamond3;
	Model flower;

	uint sendGiftPrice;
	uint beginSaleTime;
	uint nextSaleTime;
	uint registerPrice;

	DiamondAuction public diamondAuction;
	FlowerAuction public flowerAuction;

	function TrueloveBase() internal {
		sendGiftPrice = 0.001 ether;  
		registerPrice = 0.01 ether;  
		_setVars();

		diamond1 = Model({model: "OnlyOne", current: 0, total: 1, year: 2018, price: 1000 ether});  
		diamond2 = Model({model: "Eternity2018", current: 0, total: 5, year: 2018, price: 50 ether});  
		diamond3 = Model({model: "Memorial", current: 0, total: 1000, year: 2018, price: 1 ether});  
		flower = Model({model: "MySassyGirl", current: 0, total: 10000000, year: 2018, price: 0.01 ether});  
	}

	function _setVars() internal {
		beginSaleTime = now;
		nextSaleTime = beginSaleTime + 300 days;  
	}

	function setSendGiftPrice(uint _sendGiftPrice) external onlyCOO {
		sendGiftPrice = _sendGiftPrice;
	}

	function setRegisterPrice(uint _registerPrice) external onlyCOO {
		registerPrice = _registerPrice;
	}

	function _getModel(uint _index) internal view returns(Model storage) {
		if (_index == 1) {
			return diamond1;
		} else if (_index == 2) {
			return diamond2;
		} else if (_index == 3) {
			return diamond3;
		} else if (_index == 4) {
			return flower;
		}
		revert();
	}
	function getModel(uint _index) external view returns(
		bytes24 model,
		uint current,
		uint total,
		uint16 year,
		uint256 price
	) {
		Model storage _model = _getModel(_index);
		model = _model.model;
		current = _model.current;
		total = _model.total;
		year = _model.year;
		price = _model.price;
	}
}

contract EIP20Interface {
     
     
    uint256 public flowerTotalSupply;

     
     
    function balanceOfFlower(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transferFlower(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFromFlower(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approveFlower(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowanceFlower(address _owner, address _spender) public view returns (uint256 remaining);

     
    event TransferFlower(address from, address to, uint256 value); 
    event ApprovalFlower(address owner, address spender, uint256 value);

    function supportsEIP20Interface(bytes4 _interfaceID) external view returns (bool);
}
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ERC721Metadata {
	function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
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

contract TrueloveOwnership is TrueloveBase, ERC721 {
	string public constant name = "CryptoTruelove";
	string public constant symbol = "CT";

	 
	ERC721Metadata public erc721Metadata;

	bytes4 constant InterfaceSignature_ERC165 = bytes4(0x9a20483d);
			 

	bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 

	 
	 
	 
	function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
		 
		 

		return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
	}

	function setMetadataAddress(address _contractAddress) public onlyCEO {
		erc721Metadata = ERC721Metadata(_contractAddress);
	}

	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
			return diamondIndexToOwner[_tokenId] == _claimant;
	}

	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		ownershipTokenCount[_to]++;
		diamondIndexToOwner[_tokenId] = _to;
		if (_from != address(0)) {
			ownershipTokenCount[_from]--;
			delete diamondIndexToApproved[_tokenId];
		}
		Transfer(_from, _to, _tokenId);
	}

	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
			return diamondIndexToApproved[_tokenId] == _claimant;
	}

	function _approve(uint256 _tokenId, address _approved) internal {
			diamondIndexToApproved[_tokenId] = _approved;
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
			require(_to != address(diamondAuction));
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
			return diamonds.length - 1;
	}

	function ownerOf(uint256 _tokenId)
			external
			view
			returns (address owner)
	{
			owner = diamondIndexToOwner[_tokenId];

			require(owner != address(0));
	}

	 
	 
	 
	 
	function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
			uint256 tokenCount = balanceOf(_owner);

			if (tokenCount == 0) {
					 
					return new uint256[](0);
			} else {
					uint256[] memory result = new uint256[](tokenCount);
					uint256 totalDiamonds = totalSupply();
					uint256 resultIndex = 0;

					uint256 diamondId;

					for (diamondId = 1; diamondId <= totalDiamonds; diamondId++) {
							if (diamondIndexToOwner[diamondId] == _owner) {
									result[resultIndex] = diamondId;
									resultIndex++;
							}
					}

					return result;
			}
	}

	function _memcpy(uint _dest, uint _src, uint _len) private pure {
			 
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

	function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private pure returns (string) {
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

	function getDiamond(uint256 _id)
		external
		view
		returns (
		bytes24 model,
		uint16 year,
		uint16 no,
		uint activateAt
	) {
		Diamond storage diamond = diamonds[_id];

		model = diamond.model;
		year = diamond.year;
		no = diamond.no;
		activateAt = diamond.activateAt;
	}
}

contract TrueloveFlowerOwnership is TrueloveBase, EIP20Interface {
	uint256 constant private MAX_UINT256 = 2**256 - 1;
	mapping (address => mapping (address => uint256)) public flowerAllowed;

	bytes4 constant EIP20InterfaceSignature = bytes4(0x98474109);
		 
		 
		 
		 

	function supportsEIP20Interface(bytes4 _interfaceID) external view returns (bool) {
		return _interfaceID == EIP20InterfaceSignature;
	}

	function _transferFlower(address _from, address _to, uint256 _value) internal returns (bool success) {
		if (_from != address(0)) {
			require(flowerBalances[_from] >= _value);
			flowerBalances[_from] -= _value;
		}
		flowerBalances[_to] += _value;
		TransferFlower(_from, _to, _value);
		return true;
	}

	function transferFlower(address _to, uint256 _value) public returns (bool success) {
		require(flowerBalances[msg.sender] >= _value);
		flowerBalances[msg.sender] -= _value;
		flowerBalances[_to] += _value;
		TransferFlower(msg.sender, _to, _value);
		return true;
	}

	function transferFromFlower(address _from, address _to, uint256 _value) public returns (bool success) {
		uint256 allowance = flowerAllowed[_from][msg.sender];
		require(flowerBalances[_from] >= _value && allowance >= _value);
		flowerBalances[_to] += _value;
		flowerBalances[_from] -= _value;
		if (allowance < MAX_UINT256) {
			flowerAllowed[_from][msg.sender] -= _value;
		}
		TransferFlower(_from, _to, _value);
		return true;
	}

	function balanceOfFlower(address _owner) public view returns (uint256 balance) {
		return flowerBalances[_owner];
	}

	function approveFlower(address _spender, uint256 _value) public returns (bool success) {
		flowerAllowed[msg.sender][_spender] = _value;
		ApprovalFlower(msg.sender, _spender, _value);
		return true;
	}

	function allowanceFlower(address _owner, address _spender) public view returns (uint256 remaining) {
		return flowerAllowed[_owner][_spender];
	}

	function _addFlower(uint256 _amount) internal {
		flower.current += _amount;
		flowerTotalSupply += _amount;
	}
}

contract TrueloveNextSale is TrueloveOwnership, TrueloveFlowerOwnership {
	uint256 constant REMAINING_AMOUNT = 50000;  

	function TrueloveNextSale() internal {
		_giveRemainingFlower();
	}

	function openNextSale(uint256 _diamond1Price, bytes24 _diamond2Model, uint256 _diamond2Price, bytes24 _flowerModel, uint256 _flowerPrice)
		external onlyCOO
		{
		require(now >= nextSaleTime);

		_setVars();
		diamond1.price = _diamond1Price;
		_openSaleDiamond2(_diamond2Model, _diamond2Price);
		_openSaleFlower(_flowerModel, _flowerPrice);
		_giveRemainingFlower();
	}

	function _openSaleDiamond2(bytes24 _diamond2Model, uint256 _diamond2Price) private {
		diamond2.model = _diamond2Model;
		diamond2.current = 0;
		diamond2.year++;
		diamond2.price = _diamond2Price;
	}

	function _openSaleFlower(bytes24 _flowerModel, uint256 _flowerPrice) private {
		flower.model = _flowerModel;
		flower.current = 0;
		flower.year++;
		flower.price = _flowerPrice;
		flower.total = 1000000;  
	}

	function _giveRemainingFlower() internal {
		_transferFlower(0, msg.sender, REMAINING_AMOUNT);
		_addFlower(REMAINING_AMOUNT);
	}
}

contract TrueloveRegistration is TrueloveNextSale {
	mapping (address => RegistrationRight) public registrationRights;
	mapping (bytes32 => Registration) public registrations;

	struct RegistrationRight {
		bool able;
		bool used;
	}

	struct Registration {
		bool signed;
		string secret;  
		string topSecret;  
	}

	function giveRegistration(address _addr) external onlyCOO {
		if (registrationRights[_addr].able == false) {
			registrationRights[_addr].able = true;
		} else {
			revert();
		}
	}

	function buyRegistration() external payable whenNotPaused {
		require(registerPrice <= msg.value);
		if (registrationRights[msg.sender].able == false) {
			registrationRights[msg.sender].able = true;
		} else {
			revert();
		}
	}

	function _giveSenderRegistration() internal {
		if (registrationRights[msg.sender].able == false) {
			registrationRights[msg.sender].able = true;
		}
	}

	function getRegistrationRight(address _addr) external view returns (bool able, bool used) {
		able = registrationRights[_addr].able;
		used = registrationRights[_addr].used;
	}

	function getRegistration(bytes32 _unique) external view returns (bool signed, string secret, string topSecret) {
		signed = registrations[_unique].signed;
		secret = registrations[_unique].secret;
		topSecret = registrations[_unique].topSecret;
	}

	function signTruelove(bytes32 _registerID, string _secret, string _topSecret) public {
		require(registrationRights[msg.sender].able == true);
		require(registrationRights[msg.sender].used == false);
		registrationRights[msg.sender].used = true;
		_signTruelove(_registerID, _secret, _topSecret);
	}

	function signTrueloveByCOO(bytes32 _registerID, string _secret, string _topSecret) external onlyCOO {
		_signTruelove(_registerID, _secret, _topSecret);
	}

	function _signTruelove(bytes32 _registerID, string _secret, string _topSecret) internal {
		require(registrations[_registerID].signed == false);

		registrations[_registerID].signed = true;
		registrations[_registerID].secret = _secret;
		registrations[_registerID].topSecret = _topSecret;
	}
}

contract TrueloveShop is TrueloveRegistration {
	function buyDiamond(uint _index) external payable whenNotPaused returns(uint256) {
		require(_index == 1 || _index == 2 || _index == 3);
		Model storage model = _getModel(_index);

		require(model.current < model.total);
		require(model.price <= msg.value);
		_giveSenderRegistration();

		uint256 newDiamondId = diamonds.push(Diamond({model: model.model, year: model.year, no: uint16(model.current + 1), activateAt: 0})) - 1;
		_transfer(0, msg.sender, newDiamondId);
		
		model.current++;
		return newDiamondId;
	}

	function buyFlower(uint _amount) external payable whenNotPaused {
		require(flower.current + _amount < flower.total);
		uint256 price = currentFlowerPrice();
		require(price * _amount <= msg.value);
		_giveSenderRegistration();

		_transferFlower(0, msg.sender, _amount);
		_addFlower(_amount);
	}

	function currentFlowerPrice() public view returns(uint256) {
		if (flower.current < 100000 + REMAINING_AMOUNT) {  
			return flower.price;
		} else if (flower.current < 300000 + REMAINING_AMOUNT) {  
			return flower.price * 4;
		} else {
			return flower.price * 10;
		}
	}
}
contract TrueloveDelivery is TrueloveShop {
	enum GiftType { Diamond, Flower }

	event GiftSend(uint indexed index, address indexed receiver, address indexed from, bytes32 registerID, string letter, bytes16 date,
		GiftType gtype,
		bytes24 model,
		uint16 year,
		uint16 no,
		uint amount
		);

	uint public giftSendIndex = 1;
	
	modifier sendCheck(bytes32 _registerID) {
    require(sendGiftPrice <= msg.value);
		require(registrations[_registerID].signed);
    _;
  }

	function signSendDiamond(bytes32 _registerID, string _secret, string _topSecret, address _truelove, string _letter, bytes16 _date, uint _tokenId) external payable {
		signTruelove(_registerID, _secret, _topSecret);
		sendDiamond(_truelove, _registerID, _letter, _date, _tokenId);
	}

	function sendDiamond(address _truelove, bytes32 _registerID, string _letter, bytes16 _date, uint _tokenId) public payable sendCheck(_registerID) {
		require(_owns(msg.sender, _tokenId));
		require(now > diamonds[_tokenId].activateAt);
		
		_transfer(msg.sender, _truelove, _tokenId);
		
		diamonds[_tokenId].activateAt = now + 3 days;

		GiftSend(giftSendIndex, _truelove, msg.sender, _registerID, _letter, _date,
			GiftType.Diamond,
			diamonds[_tokenId].model,
			diamonds[_tokenId].year,
			diamonds[_tokenId].no,
			1
			);
		giftSendIndex++;
	}

	function signSendFlower(bytes32 _registerID, string _secret, string _topSecret, address _truelove, string _letter, bytes16 _date, uint _amount) external payable {
		signTruelove(_registerID, _secret, _topSecret);
		sendFlower(_truelove, _registerID, _letter, _date, _amount);
	}

	function sendFlower(address _truelove, bytes32 _registerID, string _letter, bytes16 _date, uint _amount) public payable sendCheck(_registerID) {
		require(flowerBalances[msg.sender] >= _amount);

		flowerBalances[msg.sender] -= _amount;
		flowerBalances[_truelove] += (_amount * 9 / 10);

		GiftSend(giftSendIndex, _truelove, msg.sender, _registerID, _letter, _date,
			GiftType.Flower,
			flower.model,
			flower.year,
			0,
			_amount
			);
		giftSendIndex++;
	}
}

contract TrueloveAuction is TrueloveDelivery {
	function setDiamondAuctionAddress(address _address) external onlyCEO {
		DiamondAuction candidateContract = DiamondAuction(_address);

		 
		require(candidateContract.isDiamondAuction());
		diamondAuction = candidateContract;
	}

	function createDiamondAuction(
		uint256 _tokenId,
		uint256 _startingPrice,
		uint256 _endingPrice,
		uint256 _duration
	)
		external
		whenNotPaused
	{
		require(_owns(msg.sender, _tokenId));
		 
		_approve(_tokenId, diamondAuction);
		diamondAuction.createAuction(
			_tokenId,
			_startingPrice,
			_endingPrice,
			_duration,
			msg.sender
		);
	}

	function setFlowerAuctionAddress(address _address) external onlyCEO {
		FlowerAuction candidateContract = FlowerAuction(_address);

		 
		require(candidateContract.isFlowerAuction());
		flowerAuction = candidateContract;
	}

	function createFlowerAuction(
		uint256 _amount,
		uint256 _startingPrice,
		uint256 _endingPrice,
		uint256 _duration
	)
		external
		whenNotPaused
	{
		approveFlower(flowerAuction, _amount);
		flowerAuction.createAuction(
			_amount,
			_startingPrice,
			_endingPrice,
			_duration,
			msg.sender
		);
	}

	function withdrawAuctionBalances() external onlyCLevel {
		diamondAuction.withdrawBalance();
		flowerAuction.withdrawBalance();
	}
}

contract TrueloveCore is TrueloveAuction {
	address public newContractAddress;

	event Transfer(address from, address to, uint256 tokenId);
	event Approval(address owner, address approved, uint256 tokenId);

	event TransferFlower(address from, address to, uint256 value); 
	event ApprovalFlower(address owner, address spender, uint256 value);

	event GiftSend(uint indexed index, address indexed receiver, address indexed from, bytes32 registerID, string letter, bytes16 date,
		GiftType gtype,
		bytes24 model,
		uint16 year,
		uint16 no,
		uint amount
		);
		
	function TrueloveCore() public {
		ceoAddress = msg.sender;
		cooAddress = msg.sender;
	}

	function setNewAddress(address _v2Address) external onlyCEO whenPaused {
    newContractAddress = _v2Address;
    ContractUpgrade(_v2Address);
  }

  function() external payable {
    require(
      msg.sender == address(diamondAuction) ||
      msg.sender == address(flowerAuction)
    );
  }
	function withdrawBalance(uint256 amount) external onlyCFO {
		cfoAddress.transfer(amount);
	}
}

contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 indexed tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            _auction.seller,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}



contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
         
        nftAddress.send(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

contract DiamondAuction is ClockAuction {

     
     
    bool public isDiamondAuction = true;

    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 indexed tokenId);
    
     
    function DiamondAuction(address _nftAddr) public
        ClockAuction(_nftAddr, 0) {}

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
         
        tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

}

contract FlowerAuction is Pausable {
    struct Auction {
        address seller;
        uint256 amount;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }

    EIP20Interface public tokenContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) auctions;
    mapping (address => uint256) sellerToAuction;
    uint256 public currentAuctionId;

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 amount, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed auctionId, uint256 amount, address winner);
    event AuctionSoldOut(uint256 indexed auctionId);
    event AuctionCancelled(uint256 indexed auctionId);

    bytes4 constant InterfaceSignature_EIP20 = bytes4(0x98474109);

    bool public isFlowerAuction = true;

    function FlowerAuction(address _nftAddress) public {
        ownerCut = 0;

        EIP20Interface candidateContract = EIP20Interface(_nftAddress);
        require(candidateContract.supportsEIP20Interface(InterfaceSignature_EIP20));
        tokenContract = candidateContract;
    }

    function createAuction(
        uint256 _amount,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(tokenContract));
        _escrow(_seller, _amount);
        Auction memory auction = Auction(
            _seller,
            _amount,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(auction);
    }

    function bid(uint256 _auctionId, uint256 _amount)
        external
        payable
    {
        _bid(_auctionId, _amount, msg.value);
        _transfer(msg.sender, _amount);
    }




    function withdrawBalance() external {
        address nftAddress = address(tokenContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.send(this.balance);
    }


    function cancelAuction(uint256 _auctionId)
        external
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_auctionId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _auctionId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        _cancelAuction(_auctionId, auction.seller);
    }

    function getAuction(uint256 _auctionId)
        external
        view
        returns
    (
        address seller,
        uint256 amount,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.amount,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function getCurrentPrice(uint256 _auctionId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }





    function _escrow(address _owner, uint256 _amount) internal {
        tokenContract.transferFromFlower(_owner, this, _amount);
    }

    function _transfer(address _receiver, uint256 _amount) internal {
        tokenContract.transferFlower(_receiver, _amount);
    }

    function _addAuction(Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        currentAuctionId++;
        auctions[currentAuctionId] = _auction;
        sellerToAuction[_auction.seller] = currentAuctionId;

        AuctionCreated(
            currentAuctionId,
            _auction.seller,
            _auction.amount,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _auctionId, address _seller) internal {
        uint256 amount = auctions[_auctionId].amount;
        delete sellerToAuction[auctions[_auctionId].seller];
        delete auctions[_auctionId];
        _transfer(_seller, amount);
        AuctionCancelled(_auctionId);
    }

    function _bid(uint256 _auctionId, uint256 _amount, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        uint256 price = _currentPrice(auction);
        uint256 totalPrice = price * _amount;
        require(_bidAmount >= totalPrice);
        auction.amount -= _amount;

        address seller = auction.seller;

        if (totalPrice > 0) {
            uint256 auctioneerCut = _computeCut(totalPrice);
            uint256 sellerProceeds = totalPrice - auctioneerCut;
            seller.transfer(sellerProceeds);
        }
        uint256 bidExcess = _bidAmount - totalPrice;
        msg.sender.transfer(bidExcess);

        if (auction.amount == 0) {
            AuctionSoldOut(_auctionId);
            delete auctions[_auctionId];
        } else {
            AuctionSuccessful(_auctionId, _amount, msg.sender);
        }

        return totalPrice;
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}
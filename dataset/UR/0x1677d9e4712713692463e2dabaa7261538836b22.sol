 

pragma solidity ^0.4.21;


 
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

 
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
     
    uint16 c = a / b;
     
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
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

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}



 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}




 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}



contract PausableToken is ERC721BasicToken, Pausable {
	function approve(address _to, uint256 _tokenId) public whenNotPaused {
		super.approve(_to, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
		super.setApprovalForAll(_operator, _approved);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
		super.transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
		super.safeTransferFrom(_from, _to, _tokenId);
	}
	
	function safeTransferFrom(
	    address _from,
	    address _to,
	    uint256 _tokenId,
	    bytes _data
	  )
	    public whenNotPaused {
		super.safeTransferFrom(_from, _to, _tokenId, _data);
	}
}


 
contract WorldCupFactory is Claimable, PausableToken {

	using SafeMath for uint256;

	uint public initPrice;

	 

	 
	struct Country {
		 
		string name;
		
		 
		uint price;
	}

	Country[] public countries;

     
     
     
	 

	 
     
	 

	
	 
	function WorldCupFactory(uint _initPrice) public {
		initPrice = _initPrice;
		paused    = true;
	}

	function createToken() external onlyOwner {
		 
		uint length = countries.length;
		for (uint i = length; i < length + 100; i++) {
			if (i >= 836 ) {
				break;
			}

			if (i < 101) {
				_createToken("Country");
			}else {
				_createToken("Player");
			}
		}
	}

	 
	function _createToken(string _name) internal {
		uint id = countries.push( Country(_name, initPrice) ) - 1;
		tokenOwner[id] = msg.sender;
		ownedTokensCount[msg.sender] = ownedTokensCount[msg.sender].add(1);
	}

}

 
contract WorldCupControl is WorldCupFactory {
	 
	address public cooAddress;


    function WorldCupControl() public {
        cooAddress = msg.sender;
    }

	 
     
    function setCOO(address _newCOO) external onlyOwner {
        require(_newCOO != address(0));
        
        cooAddress = _newCOO;
    }

     
    function withdrawBalance() external onlyOwner {
        uint balance = address(this).balance;
        
        cooAddress.send(balance);
    }
}


 
contract WorldCupHelper is WorldCupControl {

	 
	function getTokenByOwner(address _owner) external view returns(uint[]) {
	    uint[] memory result = new uint[](ownedTokensCount[_owner]);
	    uint counter = 0;

	    for (uint i = 0; i < countries.length; i++) {
			if (tokenOwner[i] == _owner) {
				result[counter] = i;
				counter++;
			}
	    }
		return result;
  	}

  	 
  	function getTokenPriceListByIds(uint[] _ids) external view returns(uint[]) {
  		uint[] memory result = new uint[](_ids.length);
  		uint counter = 0;

  		for (uint i = 0; i < _ids.length; i++) {
  			Country storage token = countries[_ids[i]];
  			result[counter] = token.price;
  			counter++;
  		}
  		return result;
  	}

}

 
contract PayerInterface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);

	function allowance(address owner, address spender) public view returns (uint256);
  	function transferFrom(address from, address to, uint256 value) public returns (bool);
  	function approve(address spender, uint256 value) public returns (bool);
}

 
contract AuctionPaused is Ownable {
  event AuctionPause();
  event AuctionUnpause();

  bool public auctionPaused = false;


   
  modifier whenNotAuctionPaused() {
    require(!auctionPaused);
    _;
  }

   
  modifier whenAuctionPaused() {
    require(auctionPaused);
    _;
  }

   
  function auctionPause() onlyOwner whenNotAuctionPaused public {
    auctionPaused = true;
    emit AuctionPause();
  }

   
  function auctionUnpause() onlyOwner whenAuctionPaused public {
    auctionPaused = false;
    emit AuctionUnpause();
  }
}

contract WorldCupAuction is WorldCupHelper, AuctionPaused {

	using SafeMath for uint256;

	event PurchaseToken(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _tokenPrice, uint256 _timestamp, uint256 _purchaseCounter);

	 
	 
	 
	 
	uint public cap;

    uint public finalCap;

	 
	 
	uint public increasePermillage = 50;

	 
	 
	uint public sysFeePermillage = 23;


	 
	PayerInterface public payerContract = PayerInterface(address(0));

     
     
    bool public isEthPayable;

    uint public purchaseCounter = 0;

     
     
     
     
     
    function WorldCupAuction(uint _initPrice, uint _cap, bool _isEthPayable, address _address) public WorldCupFactory(_initPrice) {
        require( (_isEthPayable == false && _address != address(0)) || _isEthPayable == true && _address == address(0) );

        cap           = _cap;
        finalCap      = _cap.add(_cap.mul(25).div(1000));
        isEthPayable  = _isEthPayable;
        payerContract = PayerInterface(_address);
    }

    function purchaseWithEth(uint _tokenId) external payable whenNotAuctionPaused {
    	require(isEthPayable == true);
    	require(msg.sender != tokenOwner[_tokenId]);

    	 
         
    	Country storage token = countries[_tokenId];
    	uint nextPrice = _computeNextPrice(token);

    	require(msg.value >= nextPrice);

    	uint fee = nextPrice.mul(sysFeePermillage).div(1000);
    	uint oldOwnerRefund = nextPrice.sub(fee);

    	address oldOwner = ownerOf(_tokenId);

    	 
    	oldOwner.transfer(oldOwnerRefund);

    	 
    	cooAddress.transfer(fee);

    	 
    	if ( msg.value.sub(oldOwnerRefund).sub(fee) > 0.0001 ether ) {
    		msg.sender.transfer( msg.value.sub(oldOwnerRefund).sub(fee) );
    	}

    	 
    	token.price = nextPrice;

    	_transfer(oldOwner, msg.sender, _tokenId);

    	emit PurchaseToken(oldOwner, msg.sender, _tokenId, nextPrice, now, purchaseCounter);
        purchaseCounter = purchaseCounter.add(1);
    }

    function purchaseWithToken(uint _tokenId) external whenNotAuctionPaused {
    	require(isEthPayable == false);
    	require(payerContract != address(0));
    	require(msg.sender != tokenOwner[_tokenId]);

        Country storage token = countries[_tokenId];
        uint nextPrice = _computeNextPrice(token);

         
        uint256 aValue = payerContract.allowance(msg.sender, address(this));
        require(aValue >= nextPrice);

        uint fee = nextPrice.mul(sysFeePermillage).div(1000);
        uint oldOwnerRefund = nextPrice.sub(fee);

        address oldOwner = ownerOf(_tokenId);

         
        require(payerContract.transferFrom(msg.sender, oldOwner, oldOwnerRefund));

         
        require(payerContract.transferFrom(msg.sender, cooAddress, fee));

         
        token.price = nextPrice;

        _transfer(oldOwner, msg.sender, _tokenId);

        emit PurchaseToken(oldOwner, msg.sender, _tokenId, nextPrice, now, purchaseCounter);
        purchaseCounter = purchaseCounter.add(1);

    }

    function getTokenNextPrice(uint _tokenId) public view returns(uint) {
        Country storage token = countries[_tokenId];
        uint nextPrice = _computeNextPrice(token);
        return nextPrice;
    }

    function _computeNextPrice(Country storage token) private view returns(uint) {
        if (token.price >= cap) {
            return finalCap;
        }

    	uint price = token.price;
    	uint addPrice = price.mul(increasePermillage).div(1000);

		uint nextPrice = price.add(addPrice);
		if (nextPrice > cap) {
			nextPrice = cap;
		}

    	return nextPrice;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_from, address(0), _tokenId);
        }

        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

}


contract CryptoWCRC is WorldCupAuction {

	string public constant name = "CryptoWCRC";
    
    string public constant symbol = "WCRC";

    function CryptoWCRC(uint _initPrice, uint _cap, bool _isEthPayable, address _address) public WorldCupAuction(_initPrice, _cap, _isEthPayable, _address) {

    }

    function totalSupply() public view returns (uint256) {
    	return countries.length;
    }

}
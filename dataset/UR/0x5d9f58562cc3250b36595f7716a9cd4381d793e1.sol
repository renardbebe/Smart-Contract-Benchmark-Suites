 

pragma solidity ^0.4.25;

library SafeMath
{
	function mul(uint a, uint b) internal pure returns (uint)
	{
		if (a == 0)
		{
			return 0;
		}
		uint c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint)
	{
		 
		uint c = a / b;
		 
		return c;
	}

	function sub(uint a, uint b) internal pure returns (uint)
	{
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns (uint)
	{
		uint c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC721
{
	function approve(address _to, uint _tokenId) public;
	function balanceOf(address _owner) public view returns (uint balance);
	function implementsERC721() public pure returns (bool);
	function ownerOf(uint _tokenId) public view returns (address addr);
	function takeOwnership(uint _tokenId) public;
	function totalSupply() public view returns (uint total);
	function transferFrom(address _from, address _to, uint _tokenId) public;
	function transfer(address _to, uint _tokenId) public;

	event LogTransfer(address indexed from, address indexed to, uint tokenId);
	event LogApproval(address indexed owner, address indexed approved, uint tokenId);
}

contract CryptoCricketToken is ERC721
{
	event LogBirth(uint tokenId, string name, uint internalTypeId, uint Price);
	event LogSnatch(uint tokenId, string tokenName, address oldOwner, address newOwner, uint oldPrice, uint newPrice);
	event LogTransfer(address from, address to, uint tokenId);

	string public constant name = "CryptoCricket";
	string public constant symbol = "CryptoCricketToken";

	uint private commision = 4;

	mapping (uint => uint) private startingPrice;

	 
	mapping (uint => address) public playerIndexToOwner;

	 
	mapping (address => uint) private ownershipTokenCount;

	 
	mapping (uint => address) public playerIndexToApproved;

	 
	mapping (uint => uint) private playerIndexToPrice;

	 
	mapping (uint => uint) private playerIndexToRewardPrice;

	 
	address public ceoAddress;
	address public devAddress;

	struct Player
	{
		string name;
		uint internalTypeId;
	}

	Player[] private players;

	 
	modifier onlyCEO()
	{
		require(msg.sender == ceoAddress);
		_;
	}

	modifier onlyDevORCEO()
	{
		require(msg.sender == devAddress || msg.sender == ceoAddress);
		_;
	}

	constructor(address _ceo, address _dev) public
	{
		ceoAddress = _ceo;
		devAddress = _dev;
		startingPrice[0] = 0.005 ether;  
		startingPrice[1] = 0.007 ether;  
		startingPrice[2] = 0.005 ether;  
	}

	 
	 
	 
	 
	 
	function approve(address _to, uint _tokenId) public
	{
		require(owns(msg.sender, _tokenId));
		playerIndexToApproved[_tokenId] = _to;
		emit LogApproval(msg.sender, _to, _tokenId);
	}

	function getRewardPrice(uint buyingPrice, uint _internalTypeId) internal view returns(uint rewardPrice)
	{
		if(_internalTypeId == 0)  
		{
			rewardPrice = SafeMath.div(SafeMath.mul(buyingPrice, 200), 100);
		}
		else if(_internalTypeId == 1)  
		{
			rewardPrice = SafeMath.div(SafeMath.mul(buyingPrice, 250), 100);
		}
		else  
		{
			rewardPrice = SafeMath.div(SafeMath.mul(buyingPrice, 150), 100);
		}

		rewardPrice = uint(SafeMath.div(SafeMath.mul(rewardPrice, SafeMath.sub(100, commision)), 100));
		return rewardPrice;
	}


	 
	function createPlayer(string _name, uint _internalTypeId) public onlyDevORCEO
	{
		require (_internalTypeId >= 0 && _internalTypeId <= 2);
		Player memory _player = Player({name: _name, internalTypeId: _internalTypeId});
		uint newPlayerId = players.push(_player) - 1;
		playerIndexToPrice[newPlayerId] = startingPrice[_internalTypeId];
		playerIndexToRewardPrice[newPlayerId] = getRewardPrice(playerIndexToPrice[newPlayerId], _internalTypeId);

		emit LogBirth(newPlayerId, _name, _internalTypeId, startingPrice[_internalTypeId]);

		 
		_transfer(address(0), address(this), newPlayerId);
	}

	function payout(address _to) public onlyCEO
	{
		if(_addressNotNull(_to))
		{
			_to.transfer(address(this).balance);
		}
		else
		{
			ceoAddress.transfer(address(this).balance);
		}
	}

	 
	function purchase(uint _tokenId) public payable
	{
		address oldOwner = playerIndexToOwner[_tokenId];
		uint sellingPrice = playerIndexToPrice[_tokenId];

		require(oldOwner != msg.sender);
		require(_addressNotNull(msg.sender));
		require(msg.value >= sellingPrice);

		address newOwner = msg.sender;
		uint payment = uint(SafeMath.div(SafeMath.mul(sellingPrice, SafeMath.sub(100, commision)), 100));
		uint purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		uint _internalTypeId = players[_tokenId].internalTypeId;

		if(_internalTypeId == 0)  
		{
			playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
		}
		else if(_internalTypeId == 1)  
		{
			playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 250), 100);
		}
		else  
		{
			playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
		}

		_transfer(oldOwner, newOwner, _tokenId);
		emit LogSnatch(_tokenId, players[_tokenId].name, oldOwner, newOwner, sellingPrice, playerIndexToPrice[_tokenId]);

		playerIndexToRewardPrice[_tokenId] = getRewardPrice(playerIndexToPrice[_tokenId], _internalTypeId);

		if (oldOwner != address(this))
		{
			oldOwner.transfer(payment);
		}
		msg.sender.transfer(purchaseExcess);
	}

	 
	 
	 
	 
	 
	function tokensOfOwner(address _owner) public view returns(uint[] ownerTokens)
	{
		uint tokenCount = balanceOf(_owner);
		if (tokenCount == 0)
		{
			return new uint[](0);
		}
		else
		{
			uint[] memory result = new uint[](tokenCount);
			uint totalPlayers = totalSupply();
			uint resultIndex = 0;

			uint playerId;
			for (playerId = 0; playerId <= totalPlayers; playerId++)
			{
				if (playerIndexToOwner[playerId] == _owner)
				{
					result[resultIndex] = playerId;
					resultIndex++;
				}
			}
			return result;
		}
	}

	 
	 
	 
	 
	function transfer(address _to, uint _tokenId) public
	{
		require(owns(msg.sender, _tokenId));
		require(_addressNotNull(_to));

		_transfer(msg.sender, _to, _tokenId);
	}

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint _tokenId) public
	{
		require(owns(_from, _tokenId));
		require(_approved(_to, _tokenId));
		require(_addressNotNull(_to));
		_transfer(_from, _to, _tokenId);
	}

	 
	function _transfer(address _from, address _to, uint _tokenId) private
	{
		 
		ownershipTokenCount[_to]++;
		 
		playerIndexToOwner[_tokenId] = _to;

		 
		if (_addressNotNull(_from))
		{
			ownershipTokenCount[_from]--;
			 
			delete playerIndexToApproved[_tokenId];
		}

		 
		emit LogTransfer(_from, _to, _tokenId);
	}

	 
	function _addressNotNull(address _to) private pure returns (bool)
	{
		return (_to != address(0));
	}

	 
	 
	 
	function balanceOf(address _owner) public view returns (uint balance)
	{
		return ownershipTokenCount[_owner];
	}

	 
	 
	function getPlayer(uint _tokenId) public view returns (string playerName, uint internalTypeId, uint sellingPrice, address owner)
	{
		Player storage player = players[_tokenId];
		playerName = player.name;
		internalTypeId = player.internalTypeId;
		sellingPrice = playerIndexToPrice[_tokenId];
		owner = playerIndexToOwner[_tokenId];
	}

	 
	 
	 
	function ownerOf(uint _tokenId) public view returns (address owner)
	{
		owner = playerIndexToOwner[_tokenId];
		require (_addressNotNull(owner));
	}

	 
	function _approved(address _to, uint _tokenId) private view returns (bool)
	{
		return playerIndexToApproved[_tokenId] == _to;
	}

	 
	function owns(address claimant, uint _tokenId) private view returns (bool)
	{
		return (claimant == playerIndexToOwner[_tokenId]);
	}

	function priceOf(uint _tokenId) public view returns (uint price)
	{
		return playerIndexToPrice[_tokenId];
	}

	function rewardPriceOf(uint _tokenId) public view returns (uint price)
	{
		return playerIndexToRewardPrice[_tokenId];
	}

	 
	 
	function setCEO(address _newCEO) public onlyCEO
	{
		require (_addressNotNull(_newCEO));
		ceoAddress = _newCEO;
	}

	 
	 
	function setDev(address _newDev) public onlyCEO
	{
		require (_addressNotNull(_newDev));
		devAddress = _newDev;
	}

	 
	 
	 
	function takeOwnership(uint _tokenId) public
	{
		address newOwner = msg.sender;
		address oldOwner = playerIndexToOwner[_tokenId];

		 
		require(_addressNotNull(newOwner));

		 
		require(_approved(newOwner, _tokenId));

		_transfer(oldOwner, newOwner, _tokenId);
	}

	 
	 
	function updateCommision (uint _newCommision) public onlyCEO
	{
		require (_newCommision > 0 && _newCommision < 100);
		commision = _newCommision;
	}

	function implementsERC721() public pure returns (bool)
	{
		return true;
	}

	 
	 
	function totalSupply() public view returns (uint total)
	{
		return players.length;
	}
}
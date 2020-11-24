 

pragma solidity ^0.4.11;

 

contract Interface {

	 

	 
	function getEthartRevenueReward () returns (uint256 _ethartRevenueReward);
	function getEthartArtReward () returns (uint256 _ethartArtReward);

	 
	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);
	
	 
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);
	
	 
	function isFactoryApproved (address _factory) returns (bool _approved);
	
	 
	function issuePatrons (address _to, uint256 _amount);

	 
	function asyncSend(address _owner, uint256 _amount);

	 
	function getReferrer (address _artist) returns (address _referrer);
	function getReferrerReward () returns (uint256 _referrerReward);

	 
    function totalSupply() constant returns (uint256 totalSupply);
	function balanceOf(address _owner) constant returns (uint256 balance);
 	function transfer(address _to, uint256 _value) returns (bool success);
 	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
	function approve(address _spender, uint256 _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	function burn(uint256 _amount) returns (bool success);
	function burnFrom(address _from, uint256 _amount) returns (bool success);
}

contract Factory {

   

  address[] public artworks;

   
  address registrar = 0x5f68698245e8c8949450E68B8BD8acef37faaE7D;    

   

  function getContractCount() 
    public
    constant
    returns(uint contractCount)
  {
    return artworks.length;
  }

   

  function newArtwork (bytes32 _SHA256ofArtwork, uint256 _editionSize, string _title, string _fileLink, string _customText, uint256 _ownerCommission) public returns (address newArt)
  {
	Interface a = Interface(registrar);
	if (!a.isSHA256HashRegistered(_SHA256ofArtwork)) {
		Artwork c = new Artwork(_SHA256ofArtwork, _editionSize, _title, _fileLink, _customText, _ownerCommission, msg.sender);
		a.registerArtwork(c, _SHA256ofArtwork, _editionSize, _title, _fileLink, _ownerCommission, msg.sender, false, false);
		artworks.push(c);
		return c;
	}
	else {throw;}
	}
}

contract Artwork {

 

 
	address public owner;						 
	bytes32 public SHA256ofArtwork;				 
	uint256 public editionSize;					 
	string public title;						 
	string public fileLink;						 
	string public proofLink;					 
	string public customText;					 
	uint256 public ownerCommission;				 
	
	uint256 public lowestAskPrice;				 
	address public lowestAskAddress;			 
	uint256 public lowestAskTime;				 
	bool public pieceForSale;					 

	uint256 public highestBidPrice;				 
	address public highestBidAddress;			 
	uint256 public highestBidTime;				 
	uint public activationTime;					 
	bool public pieceWanted;					 

	 
	
	 
	event NewLowestAsk (uint256 price, address seller);
	
	 
	event NewHighestBid (uint256 price, address bidder);
	
	 
	event PieceTransferred (uint256 amount, address from, address to);
	
	 
	event PieceSold (address from, address to, uint256 price);

	event Transfer (address indexed _from, address indexed _to, uint256 _value);
	event Approval (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn (address indexed _owner, uint256 _amount);

	 
	
	 
	bool public proofSet;
	
	 
	uint256 public ethartArtAwarded;

	 
	mapping (address => uint256) public piecesOwned;
	
	 
 	mapping (address => mapping (address => uint256)) allowed;
	
	 
    address registrar = 0x5f68698245e8c8949450E68B8BD8acef37faaE7D;
	
	 
	uint256 public ethartRevenueReward;
	uint256 public ethartArtReward;
	address public referrer;
	
	 
	uint256 public referrerReward;

	 
	function Artwork (
		bytes32 _SHA256ofArtwork,
		uint256 _editionSize,
		string _title,
		string _fileLink,
		string _customText,
		uint256 _ownerCommission,
		address _owner
	) {
		if (_ownerCommission > (10000 - ethartRevenueReward)) {throw;}
		Interface a = Interface(registrar);
		ethartRevenueReward = a.getEthartRevenueReward();
		ethartArtReward = a.getEthartArtReward();
		referrer = a.getReferrer (_owner);
		referrerReward = a.getReferrerReward ();
		 
		owner = _owner;
		SHA256ofArtwork = _SHA256ofArtwork;
		editionSize = _editionSize;
		title = _title;
		fileLink = _fileLink;
		customText = _customText;
		ownerCommission = _ownerCommission;
		activationTime = now;	
	}

	modifier onlyBy(address _account)
	{
		require(msg.sender == _account);
		_;
	}

	 
	modifier ethArtOnlyAfterOneYear()
	{
		require(msg.sender != registrar || now > activationTime + 31536000);
		_;
	}

	 
	modifier notLocked(address _owner, uint256 _amount)
	{
		require(_owner != lowestAskAddress || piecesOwned[_owner] > _amount);
		_;
	}

	 
	modifier onlyPayloadSize(uint size)
	{
		require(msg.data.length >= size + 4);
		_;
	}

	 
	function changeOwner (address newOwner) onlyBy (owner) {
		owner = newOwner;
		}

	function setProof (string _proofLink) onlyBy (owner) {
		if (!proofSet) {
			uint256 remainder;
			proofLink = _proofLink;
			proofSet = true;
			remainder = editionSize % (10000 / ethartArtReward);
			ethartArtAwarded = (editionSize - remainder) / (10000 / ethartArtReward);
			 
			if (remainder > 0 && now % ((10000 / ethartArtReward) - 1) <= remainder) {ethartArtAwarded++;}
			piecesOwned[registrar] = ethartArtAwarded;
			piecesOwned[owner] = editionSize - ethartArtAwarded;
			}
		else {throw;}
		}

	function transfer(address _to, uint256 _amount) notLocked(msg.sender, _amount) onlyPayloadSize(2 * 32) returns (bool success) {
		if (piecesOwned[msg.sender] >= _amount 
			&& _amount > 0
			&& piecesOwned[_to] + _amount > piecesOwned[_to]
			 
			&& _to != 0x0)
			{
			piecesOwned[msg.sender] -= _amount;
			piecesOwned[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
			}
			else { return false;}
 		 }

	function totalSupply() constant returns (uint256 totalSupply) {
		totalSupply = editionSize;
		}

	function balanceOf(address _owner) constant returns (uint256 balance) {
 		return piecesOwned[_owner];
		}

	function transferFrom(address _from, address _to, uint256 _amount) notLocked(_from, _amount) onlyPayloadSize(3 * 32)returns (bool success)
		{
			if (piecesOwned[_from] >= _amount
				&& allowed[_from][msg.sender] >= _amount
				&& _amount > 0
				&& piecesOwned[_to] + _amount > piecesOwned[_to]
				 
				&& _to != 0x0
				&& (_from != lowestAskAddress || piecesOwned[_from] > _amount))
					{
					piecesOwned[_from] -= _amount;
					allowed[_from][msg.sender] -= _amount;
					piecesOwned[_to] += _amount;
					Transfer(_from, _to, _amount);
					return true;
					} else {return false;}
		}

	 
	 
	 
	 
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
		}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
		}

	function burn(uint256 _amount) notLocked(msg.sender, _amount) returns (bool success) {
			if (piecesOwned[msg.sender] >= _amount) {
				piecesOwned[msg.sender] -= _amount;
				editionSize -= _amount;
				Burn(msg.sender, _amount);
				return true;
			}
			else {throw;}
		}

	function burnFrom(address _from, uint256 _value) notLocked(_from, _value) onlyPayloadSize(2 * 32) returns (bool success) {
		if (piecesOwned[_from] >= _value && allowed[_from][msg.sender] >= _value) {
			piecesOwned[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			editionSize -= _value;
			Burn(_from, _value);
			return true;
		}
		else {throw;}
	}

	function buyPiece() payable {
		if (pieceForSale && msg.value >= lowestAskPrice) {
			uint256 _amountOwner;
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 _amountReferrer;
			_amountOwner = (msg.value / 10000) * ownerCommission;
			_amountEthart = (msg.value / 10000) * ethartRevenueReward;
			_amountSeller = msg.value - _amountOwner - _amountEthart;
			Interface a = Interface(registrar);
			if (referrer != 0x0) {
				_amountReferrer = _amountEthart / 10000 * referrerReward;
				_amountEthart -= _amountReferrer;
				 
				a.asyncSend(referrer, _amountReferrer);
				}
			piecesOwned[lowestAskAddress]--;
			piecesOwned[msg.sender]++;
			PieceSold (lowestAskAddress, msg.sender, msg.value);
			pieceForSale = false;
			lowestAskPrice = 0;
			 
			a.issuePatrons(msg.sender, msg.value);
			 
			a.asyncSend(owner, _amountOwner);
			 
			a.asyncSend(lowestAskAddress, _amountSeller);
			lowestAskAddress = 0x0;
			 
			a.asyncSend(registrar, _amountEthart);
			 
			registrar.transfer(msg.value);
		}
		else {throw;}
	}

	 
	function offerPieceForSale (uint256 _price) ethArtOnlyAfterOneYear {
		if ((_price < lowestAskPrice || !pieceForSale) && piecesOwned[msg.sender] >= 1) {
				if (_price <= highestBidPrice) {fillBid();}
				else
				{
					pieceForSale = true;
					lowestAskPrice = _price;
					lowestAskAddress = msg.sender;
					lowestAskTime = now;
					NewLowestAsk (_price, lowestAskAddress);			 
				}
		}
		else {throw;}
	}

	 
	function placeBid () payable {
		if (msg.value > highestBidPrice || (pieceForSale && msg.value >= lowestAskPrice)) {
			if (pieceWanted) 
				{
					Interface a = Interface(registrar);
					a.asyncSend(highestBidAddress, highestBidPrice);
				}
			if (pieceForSale && msg.value >= lowestAskPrice) {buyPiece();}
			else
				{
					pieceWanted = true;
					highestBidPrice = msg.value;
					highestBidAddress = msg.sender;
					highestBidTime = now;
					NewHighestBid (msg.value, highestBidAddress);
					registrar.transfer(msg.value);
				}
		}
		else {throw;}
	}

	 
	 
	function fillBid () ethArtOnlyAfterOneYear notLocked(msg.sender, 1) {
		if (pieceWanted && piecesOwned[msg.sender] >= 1) {
			uint256 _amountOwner;														
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 _amountReferrer;
			_amountOwner = (highestBidPrice / 10000) * ownerCommission;
			_amountEthart = (highestBidPrice / 10000) * ethartRevenueReward;
			_amountSeller = highestBidPrice - _amountOwner - _amountEthart;
			Interface a = Interface(registrar);
			if (referrer != 0x0) {
				_amountReferrer = _amountEthart / 10000 * referrerReward;
				_amountEthart -= _amountReferrer;
				 
				a.asyncSend(referrer, _amountReferrer);
				}
			piecesOwned[highestBidAddress]++;
			 
			a.issuePatrons(highestBidAddress, highestBidPrice);				
			piecesOwned[msg.sender]--;
			PieceSold (msg.sender, highestBidAddress, highestBidPrice);
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			 
			a.asyncSend(owner, _amountOwner);
			 
			a.asyncSend(msg.sender, _amountSeller);
			 
			a.asyncSend(registrar, _amountEthart);
		}
		else {throw;}
	}

	 
	function cancelBid () onlyBy (highestBidAddress){
		if (pieceWanted && now > highestBidTime + 86400) {
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			NewHighestBid (0, 0x0);
			Interface a = Interface(registrar);
			a.asyncSend(msg.sender, highestBidPrice);			
		}
		else {throw;}
	}

	 
	function cancelSale () onlyBy (lowestAskAddress){
		if(pieceForSale && now > lowestAskTime + 86400) {
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
			NewLowestAsk (0, 0x0);
		}
		else {throw;}
	}

}
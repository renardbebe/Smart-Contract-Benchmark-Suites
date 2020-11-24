 

pragma solidity ^0.4.11;

 

contract Interface {

	 
    function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);		 
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);			 
	function isFactoryApproved (address _factory) returns (bool _approved);						 
	function issuePatrons (address _to, uint256 _amount);										 

	 
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

   

  address registrar = 0xaD3e7D2788126250d48598e1DB6A2D3E19B89738;    

   

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
	if (!a.isSHA256HashRegistered(_SHA256ofArtwork) && a.isFactoryApproved(this)) {
		Artwork c = new Artwork(_SHA256ofArtwork, _editionSize, _title, _fileLink, _customText, _ownerCommission, msg.sender);
		artworks.push(c);
		a.registerArtwork(c, _SHA256ofArtwork, _editionSize, _title, _fileLink, _ownerCommission, msg.sender, false, false);
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

	 
	event newLowestAsk (uint256 price, address seller);							 
	event newHighestBid (uint256 price, address bidder);							 
	event pieceTransfered (uint256 amount, address from, address to);				 
	event pieceSold (address from, address to, uint256 price);					 

	event Transfer (address indexed _from, address indexed _to, uint256 _value);
	event Approval (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn (address indexed _owner, uint256 _amount);

	 
	bool public proofSet;							 
	uint256 ethartAward;					 

	mapping (address => uint256) public piecesOwned;				 
 	mapping (address => mapping (address => uint256)) allowed;		 
    address registrar = 0xaD3e7D2788126250d48598e1DB6A2D3E19B89738;						 

	function Artwork (								 
		bytes32 _SHA256ofArtwork,
		uint256 _editionSize,
		string _title,
		string _fileLink,
		string _customText,
		uint256 _ownerCommission,
		address _owner
	) {
		if (_ownerCommission > 9750 || _ownerCommission <0) {throw;}
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

	modifier ownerFirst()
	{
		require(msg.sender == owner || now > highestBidTime + 86400 || piecesOwned[owner] == 0);
		_;
	}

	modifier notLocked(address _owner, uint256 _amount)
	{
		require(_owner != lowestAskAddress || piecesOwned[_owner] > _amount);
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
			remainder = editionSize % 40;
			ethartAward = (editionSize - remainder) / 40;
			if (remainder > 0 && now % 39 <= remainder) {ethartAward++;}		 
			piecesOwned[registrar] = ethartAward;
			piecesOwned[owner] = editionSize - ethartAward;
			}
		else {throw;}
		}

	function transfer(address _to, uint256 _amount) notLocked(msg.sender, _amount) returns (bool success) {
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

 	function transferFrom(address _from, address _to, uint256 _amount) notLocked(_from, _amount) returns (bool success)
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

	function burnFrom(address _from, uint256 _value) notLocked(_from, _value) returns (bool success) {
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
			_amountOwner = msg.value / 10000 * ownerCommission;
			_amountEthart = msg.value / 40;
			_amountSeller = msg.value - _amountOwner - _amountEthart;
			owner.transfer(_amountOwner);									 
			lowestAskAddress.transfer(_amountSeller);						 
			registrar.transfer(_amountEthart);								 
			piecesOwned[lowestAskAddress]--;
			piecesOwned[msg.sender]++;
			Interface a = Interface(registrar);
			a.issuePatrons(msg.sender, msg.value / 5 * 2);
			pieceSold (lowestAskAddress, msg.sender, msg.value);
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
		}
		else {throw;}
	}

	 
	function offerPieceForSale (uint256 _price) ethArtOnlyAfterOneYear {
		if (_price < lowestAskPrice || !pieceForSale) {
				if (_price <= highestBidPrice) {fillBid();}
				else {
				pieceForSale = true;
				lowestAskPrice = _price;
				lowestAskAddress = msg.sender;
				lowestAskTime = now;
				newLowestAsk (_price, lowestAskAddress);			 
				}
		}
		else {throw;}
	}

	 
	function placeBid () payable {
		if (msg.value > highestBidPrice || (pieceForSale && msg.value >= lowestAskPrice)) {
			if (pieceWanted) {highestBidAddress.transfer (highestBidPrice);}
			if (pieceForSale && msg.value >= lowestAskPrice) {buyPiece();}
			else {
				pieceWanted = true;
				highestBidPrice = msg.value;
				highestBidAddress = msg.sender;
				highestBidTime = now;
				newHighestBid (msg.value, highestBidAddress);
				}
		}
		else {throw;}
	}

	function fillBid () ownerFirst ethArtOnlyAfterOneYear notLocked(msg.sender, 1) {	 
		if (pieceWanted && piecesOwned[msg.sender] >= 1) {								 
			uint256 _amountOwner;														 
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 patronReward;
			_amountOwner = highestBidPrice / 10000 * ownerCommission;
			_amountEthart = highestBidPrice / 40;
			_amountSeller = highestBidPrice - _amountOwner - _amountEthart;
			owner.transfer(_amountOwner);									 
			msg.sender.transfer(_amountSeller);								 
			registrar.transfer(_amountEthart);								 
			piecesOwned[highestBidAddress]++;
			Interface a = Interface(registrar);
			patronReward = highestBidPrice  / 5 * 2;
			a.issuePatrons(highestBidAddress, patronReward);				
			piecesOwned[msg.sender]--;
			pieceSold (msg.sender, highestBidAddress, highestBidPrice);
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
		}
		else {throw;}
	}

	 
	function cancelBid () onlyBy (highestBidAddress){
		if (pieceWanted && now > highestBidTime + 86400) {
			pieceWanted = false;
			msg.sender.transfer(highestBidPrice);
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			newHighestBid (0, 0x0);
		}
		else {throw;}
	}

	 
	function cancelSale () onlyBy (lowestAskAddress){
		if(pieceForSale && now > lowestAskTime + 86400) {
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
			newLowestAsk (0, 0x0);
		}
		else {throw;}
	}

}
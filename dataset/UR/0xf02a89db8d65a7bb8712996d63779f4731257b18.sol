 

pragma solidity ^0.4.25;

 

contract ERC721
{
	string constant public   name = "SuperFan";
	string constant public symbol = "SFT";

	uint256 public totalSupply;
	
	struct Token
	{
		uint256 price;
		uint256	pack;
		string uri;
	}
	
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	
	mapping (uint256 => Token) public tokens;
	
	 
	mapping (uint256 => address) public tokenIndexToOwner;
	
	 
	mapping (address => uint256) ownershipTokenCount; 

	 
	 
	 
	mapping (uint256 => address) public tokenIndexToApproved;
	
	function implementsERC721() public pure returns (bool)
	{
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 count) 
	{
		return ownershipTokenCount[_owner];
	}
	
	function ownerOf(uint256 _tokenId) public view returns (address owner)
	{
		owner = tokenIndexToOwner[_tokenId];
		require(owner != address(0));
	}
	
	 
	 
	function _approve(uint256 _tokenId, address _approved) internal 
	{
		tokenIndexToApproved[_tokenId] = _approved;
	}
	
	 
	 
	 
	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool)
	{
		return tokenIndexToApproved[_tokenId] == _claimant;
	}
	
	function approve( address _to, uint256 _tokenId ) public
	{
		 
		require(_owns(msg.sender, _tokenId));

		 
		_approve(_tokenId, _to);

		 
		emit Approval(msg.sender, _to, _tokenId);
	}
	
	function transferFrom( address _from, address _to, uint256 _tokenId ) public
	{
		 
		require(_approvedFor(msg.sender, _tokenId));
		require(_owns(_from, _tokenId));

		 
		_transfer(_from, _to, _tokenId);
	}
	
	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool)
	{
		return tokenIndexToOwner[_tokenId] == _claimant;
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal 
	{
		ownershipTokenCount[_to]++;
		tokenIndexToOwner[_tokenId] = _to;

		if (_from != address(0)) 
		{
			ownershipTokenCount[_from]--;
			 
			delete tokenIndexToApproved[_tokenId];
		}
		
		emit Transfer(_from, _to, _tokenId);
			
	}
	
	function transfer(address _to, uint256 _tokenId) public
	{
		require(_to != address(0));
		require(_owns(msg.sender, _tokenId));
		_transfer(msg.sender, _to, _tokenId);
	}
	
	 
	
	function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl)
	{
		Token storage tkn = tokens[_tokenId];
		return tkn.uri;
	}
	
	 

}

 

contract SuperFan is ERC721  
{
	constructor() public {}
	
	event LogToken(address user, uint256 idToken, uint256 amount);
	
	function getToken(uint256 option, string struri) public payable
	{
	
		Token memory _token = Token({
			price: msg.value,
			pack : option,
			uri : struri
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		
		_transfer(0x0, msg.sender, newTokenId);
		
		 
	}
	
}
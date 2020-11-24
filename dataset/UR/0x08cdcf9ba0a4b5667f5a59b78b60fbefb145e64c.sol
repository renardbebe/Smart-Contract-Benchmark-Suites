 

pragma solidity ^0.4.18;

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

 
contract ERC721 {
     
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract WorldCupToken is ERC721 {

     
     
    event WorldCupTokenWereSold(address indexed curOwner, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice, address indexed prevOwner, uint256 traddingTime); 
     
	event ShareBonus(address indexed toOwner, uint256 indexed tokenId, uint256 indexed traddingTime, uint256 remainingAmount);
	 
    event Present(address indexed fromAddress, address indexed toAddress, uint256 amount, uint256 presentTime);
     
    event Transfer(address from, address to, uint256 tokenId);

     
    mapping (uint256 => address) public worldCupIdToOwnerAddress;   
    mapping (address => uint256) private ownerAddressToTokenCount;  
    mapping (uint256 => address) public worldCupIdToAddressForApproved;  
    mapping (uint256 => uint256) private worldCupIdToPrice;  
     
    string[] private worldCupTeamDescribe;
	uint256 private SHARE_BONUS_TIME = uint256(now);
    address public ceoAddress;
    address public cooAddress;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
	
	function destroy() public onlyCEO {
		selfdestruct(ceoAddress);
    }
	
	function payAllOut() public onlyCLevel {
       ceoAddress.transfer(this.balance);
    }

     
    function WorldCupToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
	    for (uint256 i = 0; i < 32; i++) {
		    uint256 newWorldCupTeamId = worldCupTeamDescribe.push("I love world cup!") - 1;
            worldCupIdToPrice[newWorldCupTeamId] = 0 ether; 
	         
            _transfer(address(0), msg.sender, newWorldCupTeamId);
	    }
    }

     
    function approve(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        worldCupIdToAddressForApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerAddressToTokenCount[_owner];
    }

     
    function getWorlCupByID(uint256 _tokenId) public view returns (string wctDesc, uint256 sellingPrice, address owner) {
        wctDesc = worldCupTeamDescribe[_tokenId];
        sellingPrice = worldCupIdToPrice[_tokenId];
        owner = worldCupIdToOwnerAddress[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
    function name() public pure returns (string) {
        return "WorldCupToken";
    }
  
     
    function symbol() public pure returns (string) {
        return "WCT";
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = worldCupIdToOwnerAddress[_tokenId];
        require(owner != address(0));
        return owner;
    }
  
    function setWorldCupTeamDesc(uint256 _tokenId, string descOfOwner) public {
        if(ownerOf(_tokenId) == msg.sender){
	        worldCupTeamDescribe[_tokenId] = descOfOwner;
	    }
    }

	 
     
	 
	 
	 
	
     
    function buyWorldCupTeamToken(uint256 _tokenId) public payable {
        address oldOwner = worldCupIdToOwnerAddress[_tokenId];
        address newOwner = msg.sender;
        require(oldOwner != newOwner);  
        require(_addressNotNull(newOwner));  

	    uint256 oldSoldPrice = worldCupIdToPrice[_tokenId]; 
	    uint256 diffPrice = SafeMath.sub(msg.value, oldSoldPrice);
	    uint256 priceOfOldOwner = SafeMath.add(oldSoldPrice, SafeMath.div(diffPrice, 2));
	    uint256 priceOfDevelop = SafeMath.div(diffPrice, 4);
	    worldCupIdToPrice[_tokenId] = msg.value; 
	     

        _transfer(oldOwner, newOwner, _tokenId);
        if (oldOwner != address(this)) {
	        oldOwner.transfer(priceOfOldOwner);
        }
	    ceoAddress.transfer(priceOfDevelop);
	    if(this.balance >= uint256(3.2 ether)){
            if((uint256(now) - SHARE_BONUS_TIME) >= 86400){
		        for(uint256 i=0; i<32; i++){
		            worldCupIdToOwnerAddress[i].transfer(0.1 ether);
					ShareBonus(worldCupIdToOwnerAddress[i], i, uint256(now), this.balance);
		        }
			    SHARE_BONUS_TIME = uint256(now);
			     
		    }
	    }
	    WorldCupTokenWereSold(newOwner, _tokenId, oldSoldPrice, msg.value, oldOwner, uint256(now));
	}

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return worldCupIdToPrice[_tokenId];
    }

     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = worldCupIdToOwnerAddress[_tokenId];

         
        require(_addressNotNull(newOwner));

         
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCars = totalSupply();
            uint256 resultIndex = 0;

            uint256 carId;
            for (carId = 0; carId <= totalCars; carId++) {
                if (worldCupIdToOwnerAddress[carId] == _owner) {
                    result[resultIndex] = carId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
  
    function getCEO() public view returns (address ceoAddr) {
        return ceoAddress;
    }

     
    function totalSupply() public view returns (uint256 total) {
        return worldCupTeamDescribe.length;
    }
  
     
    function getBonusPool() public view returns (uint256) {
        return this.balance;
    }
  
    function getTimeFromPrize() public view returns (uint256) {
        return uint256(now) - SHARE_BONUS_TIME;
    }

     
    function transfer(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_isOwner(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return worldCupIdToAddressForApproved[_tokenId] == _to;
    }

    function _isOwner(address checkAddress, uint256 _tokenId) private view returns (bool) {
        return checkAddress == worldCupIdToOwnerAddress[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownerAddressToTokenCount[_to]++;
        worldCupIdToOwnerAddress[_tokenId] = _to;   

        if (_from != address(0)) {
            ownerAddressToTokenCount[_from]--;
            delete worldCupIdToAddressForApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }
}
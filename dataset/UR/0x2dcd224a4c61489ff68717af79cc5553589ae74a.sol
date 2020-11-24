 

pragma solidity ^0.4.18;  



 
 
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


contract SportStarToken is ERC721 {

     

     
     
    event Transfer(address from, address to, uint256 tokenId);



     

     
     
    mapping (uint256 => address) public tokenIndexToOwner;

     
     
    mapping (address => uint256) private ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public tokenIndexToApproved;

     
    mapping (uint256 => bytes32) public tokenIndexToData;

    address public ceoAddress;
    address public masterContractAddress;

    uint256 public promoCreatedCount;



     

    struct Token {
        string name;
    }

    Token[] private tokens;



     

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }



     

    function SportStarToken() public {
        ceoAddress = msg.sender;
    }



     

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setMasterContract(address _newMasterContract) public onlyCEO {
        require(_newMasterContract != address(0));

        masterContractAddress = _newMasterContract;
    }



     

     
     
    function getToken(uint256 _tokenId) public view returns (
        string tokenName,
        address owner
    ) {
        Token storage token = tokens[_tokenId];
        tokenName = token.name;
        owner = tokenIndexToOwner[_tokenId];
    }

     
     
     
     
     
    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId;
            for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getTokenData(uint256 _tokenId) public view returns (bytes32 tokenData) {
        return tokenIndexToData[_tokenId];
    }



     

     
     
     
     
    function approve(address _to, uint256 _tokenId) public {
         
        require(_owns(msg.sender, _tokenId));

        tokenIndexToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function name() public pure returns (string) {
        return "CryptoSportStars";
    }

    function symbol() public pure returns (string) {
        return "SportStarToken";
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
     
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }

     
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];

         
        require(_addressNotNull(newOwner));

         
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

     
    function totalSupply() public view returns (uint256 total) {
        return tokens.length;
    }

     
     
     
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }



     

    function createToken(string _name, address _owner) public onlyMasterContract returns (uint256 _tokenId) {
        return _createToken(_name, _owner);
    }

    function updateOwner(address _from, address _to, uint256 _tokenId) public onlyMasterContract {
        _transfer(_from, _to, _tokenId);
    }

    function setTokenData(uint256 _tokenId, bytes32 tokenData) public onlyMasterContract {
        tokenIndexToData[_tokenId] = tokenData;
    }



     

     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

     
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _to;
    }

     
    function _createToken(string _name, address _owner) private returns (uint256 _tokenId) {
        Token memory _token = Token({
            name: _name
            });
        uint256 newTokenId = tokens.push(_token) - 1;

         
         
        require(newTokenId == uint256(uint32(newTokenId)));

         
         
        _transfer(address(0), _owner, newTokenId);

        return newTokenId;
    }

     
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[_tokenId];
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) private {
         
        ownershipTokenCount[_to]++;
         
        tokenIndexToOwner[_tokenId] = _to;

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete tokenIndexToApproved[_tokenId];
        }

         
        Transfer(_from, _to, _tokenId);
    }
}
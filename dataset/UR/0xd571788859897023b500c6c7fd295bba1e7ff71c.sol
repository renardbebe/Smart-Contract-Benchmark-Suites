 

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



contract SportStarMaster {

     

     
    event Birth(uint256 tokenId, string name, address owner);

     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

     
     
    event Transfer(address from, address to, uint256 tokenId);



     

    uint256 private startingPrice = 0.001 ether;
    uint256 private firstStepLimit = 0.053613 ether;
    uint256 private secondStepLimit = 0.564957 ether;



     

     
    mapping(uint256 => uint256) private tokenIndexToPrice;

     
    address public ceoAddress;
    address public cooAddress;

     
    SportStarToken public tokensContract;

    uint256 public promoCreatedCount;


    uint256 private increaseLimit1 = 0.05 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;



     

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }



     

    function SportStarMaster() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;

         
        tokenIndexToPrice[0]=198056585936481135;
        tokenIndexToPrice[1]=198056585936481135;
        tokenIndexToPrice[2]=198056585936481135;
        tokenIndexToPrice[3]=76833314470700771;
        tokenIndexToPrice[4]=76833314470700771;
        tokenIndexToPrice[5]=76833314470700771;
        tokenIndexToPrice[6]=76833314470700771;
        tokenIndexToPrice[7]=76833314470700771;
        tokenIndexToPrice[8]=76833314470700771;
        tokenIndexToPrice[9]=76833314470700771;
        tokenIndexToPrice[10]=76833314470700771;
        tokenIndexToPrice[11]=76833314470700771;
        tokenIndexToPrice[12]=76833314470700771;
        tokenIndexToPrice[13]=76833314470700771;
        tokenIndexToPrice[14]=37264157518289874;
        tokenIndexToPrice[15]=76833314470700771;
        tokenIndexToPrice[16]=144447284479990001;
        tokenIndexToPrice[17]=144447284479990001;
        tokenIndexToPrice[18]=37264157518289874;
        tokenIndexToPrice[19]=76833314470700771;
        tokenIndexToPrice[20]=37264157518289874;
        tokenIndexToPrice[21]=76833314470700771;
        tokenIndexToPrice[22]=105348771387661881;
        tokenIndexToPrice[23]=144447284479990001;
        tokenIndexToPrice[24]=105348771387661881;
        tokenIndexToPrice[25]=37264157518289874;
        tokenIndexToPrice[26]=37264157518289874;
        tokenIndexToPrice[27]=37264157518289874;
        tokenIndexToPrice[28]=76833314470700771;
        tokenIndexToPrice[29]=105348771387661881;
        tokenIndexToPrice[30]=76833314470700771;
        tokenIndexToPrice[31]=37264157518289874;
        tokenIndexToPrice[32]=76833314470700771;
        tokenIndexToPrice[33]=37264157518289874;
        tokenIndexToPrice[34]=76833314470700771;
        tokenIndexToPrice[35]=37264157518289874;
        tokenIndexToPrice[36]=37264157518289874;
        tokenIndexToPrice[37]=76833314470700771;
        tokenIndexToPrice[38]=76833314470700771;
        tokenIndexToPrice[39]=37264157518289874;
        tokenIndexToPrice[40]=37264157518289874;
        tokenIndexToPrice[41]=37264157518289874;
        tokenIndexToPrice[42]=76833314470700771;
        tokenIndexToPrice[43]=37264157518289874;
        tokenIndexToPrice[44]=37264157518289874;
        tokenIndexToPrice[45]=76833314470700771;
        tokenIndexToPrice[46]=37264157518289874;
        tokenIndexToPrice[47]=37264157518289874;
        tokenIndexToPrice[48]=76833314470700771;
    }


    function setTokensContract(address _newTokensContract) public onlyCEO {
        require(_newTokensContract != address(0));

        tokensContract = SportStarToken(_newTokensContract);
    }



     

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }



     
    function getTokenInfo(uint256 _tokenId) public view returns (
        address owner,
        uint256 price,
        bytes32 tokenData
    ) {
        owner = tokensContract.ownerOf(_tokenId);
        price = tokenIndexToPrice[_tokenId];
        tokenData = tokensContract.getTokenData(_tokenId);
    }

     
    function createPromoToken(address _owner, string _name, uint256 _price) public onlyCOO {
        address tokenOwner = _owner;
        if (tokenOwner == address(0)) {
            tokenOwner = cooAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        uint256 newTokenId = tokensContract.createToken(_name, tokenOwner);
        tokenIndexToPrice[newTokenId] = _price;

        Birth(newTokenId, _name, _owner);
    }

     
    function createContractToken(string _name) public onlyCOO {
        uint256 newTokenId = tokensContract.createToken(_name, address(this));
        tokenIndexToPrice[newTokenId] = startingPrice;

        Birth(newTokenId, _name, address(this));
    }

    function createContractTokenWithPrice(string _name, uint256 _price) public onlyCOO {
        uint256 newTokenId = tokensContract.createToken(_name, address(this));
        tokenIndexToPrice[newTokenId] = _price;

        Birth(newTokenId, _name, address(this));
    }

    function setGamblingFee(uint256 _tokenId, uint256 _fee) public {
        require(msg.sender == tokensContract.ownerOf(_tokenId));
        require(_fee >= 0 && _fee <= 100);

        bytes32 tokenData = byte(_fee);
        tokensContract.setTokenData(_tokenId, tokenData);
    }

     
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = tokensContract.ownerOf(_tokenId);
        address newOwner = msg.sender;

        uint256 sellingPrice = tokenIndexToPrice[_tokenId];

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        uint256 devCut = calculateDevCut(sellingPrice);
        uint256 payment = SafeMath.sub(sellingPrice, devCut);
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

        tokenIndexToPrice[_tokenId] = calculateNextPrice(sellingPrice);

        tokensContract.updateOwner(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, newOwner);

        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return tokenIndexToPrice[_tokenId];
    }

    function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
        if (_price < increaseLimit1) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100);  
        } else if (_price < increaseLimit2) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100);  
        } else if (_price < increaseLimit3) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100);  
        } else if (_price < increaseLimit4) {
            return SafeMath.div(SafeMath.mul(_price, 3), 100);  
        } else {
            return SafeMath.div(SafeMath.mul(_price, 2), 100);  
        }
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < increaseLimit1) {
            return SafeMath.div(SafeMath.mul(_price, 200), 97);
        } else if (_price < increaseLimit2) {
            return SafeMath.div(SafeMath.mul(_price, 133), 97);
        } else if (_price < increaseLimit3) {
            return SafeMath.div(SafeMath.mul(_price, 125), 97);
        } else if (_price < increaseLimit4) {
            return SafeMath.div(SafeMath.mul(_price, 115), 97);
        } else {
            return SafeMath.div(SafeMath.mul(_price, 113), 98);
        }
    }

    function payout(address _to) public onlyCEO {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }



     

     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }
}



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
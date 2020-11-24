 

pragma solidity 0.4.18;


 
 
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


contract AthleteToken is ERC721 {

     

     
    event Birth(uint256 tokenId, string name, address owner);

     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
    string public constant NAME = "CryptoAthletes";  
    string public constant SYMBOL = "AthleteToken";  

    uint256 private startingPrice = 0.001 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 5000;
    uint256 private firstStepLimit = 0.053613 ether;
    uint256 private secondStepLimit = 0.564957 ether;

     

     
     
    mapping (uint256 => address) public athleteIndexToOwner;

     
     
    mapping (address => uint256) private ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public athleteIndexToApproved;

     
    mapping (uint256 => uint256) private athleteIndexToPrice;

     
    address public ceoAddress;
    address public cooAddress;

    uint256 public promoCreatedCount;

     
    struct Athlete {
        string name;
    }

    Athlete[] private athletes;

     
     
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

     
    function AthleteToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    ) public {
         
        require(_owns(msg.sender, _tokenId));

        athleteIndexToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

     
    function createPromoAthlete(address _owner, string _name, uint256 _price) public onlyCOO {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        address athleteOwner = _owner;
        if (athleteOwner == address(0)) {
            athleteOwner = cooAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        _createAthlete(_name, athleteOwner, _price);
    }

     
    function createContractAthlete(string _name) public onlyCOO {
        _createAthlete(_name, address(this), startingPrice);
    }

     
     
    function getAthlete(uint256 _tokenId) public view returns (
        string athleteName,
        uint256 sellingPrice,
        address owner
    ) {
        Athlete storage athlete = athletes[_tokenId];
        athleteName = athlete.name;
        sellingPrice = athleteIndexToPrice[_tokenId];
        owner = athleteIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
    function name() public pure returns (string) {
        return NAME;
    }

     
     
     
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = athleteIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }

     
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = athleteIndexToOwner[_tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = athleteIndexToPrice[_tokenId];

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 93), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

         
        if (sellingPrice < firstStepLimit) {
             
            athleteIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 93);
        } else if (sellingPrice < secondStepLimit) {
             
            athleteIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 93);
        } else {
             
            athleteIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 93);
        }

        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);  
        }

        TokenSold(_tokenId, sellingPrice, athleteIndexToPrice[_tokenId], oldOwner, newOwner, athletes[_tokenId].name);

        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return athleteIndexToPrice[_tokenId];
    }

     
     
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
     
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = athleteIndexToOwner[_tokenId];

         
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
            uint256 totalAthletes = totalSupply();
            uint256 resultIndex = 0;

            uint256 athleteId;
            for (athleteId = 0; athleteId <= totalAthletes; athleteId++) {
                if (athleteIndexToOwner[athleteId] == _owner) {
                    result[resultIndex] = athleteId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

     
     
    function totalSupply() public view returns (uint256 total) {
        return athletes.length;
    }

     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

     
     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

     
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return athleteIndexToApproved[_tokenId] == _to;
    }

     
    function _createAthlete(string _name, address _owner, uint256 _price) private {
        Athlete memory _athlete = Athlete({
            name: _name
        });
        uint256 newAthleteId = athletes.push(_athlete) - 1;

         
         
        require(newAthleteId == uint256(uint32(newAthleteId)));

        Birth(newAthleteId, _name, _owner);

        athleteIndexToPrice[newAthleteId] = _price;

         
         
        _transfer(address(0), _owner, newAthleteId);
    }

     
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == athleteIndexToOwner[_tokenId];
    }

     
    function _payout(address _to) private {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) private {
         
        ownershipTokenCount[_to]++;
         
        athleteIndexToOwner[_tokenId] = _to;

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete athleteIndexToApproved[_tokenId];
        }

         
        Transfer(_from, _to, _tokenId);
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
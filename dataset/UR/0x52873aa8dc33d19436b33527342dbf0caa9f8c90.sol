 

pragma solidity ^0.4.21;

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

contract CountryJackpot is ERC721, Ownable{
    using SafeMath for uint256;
     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

     
    event Transfer(address from, address to, uint256 tokenId);

     
    string public constant NAME = "EtherCup2018";  
    string public constant SYMBOL = "EthCup";  

     
    uint256 private startingPrice = 0.01 ether;

     
    uint256 private firstStepLimit =  1 ether;
    uint256 private secondStepLimit = 3 ether;
    uint256 private thirdStepLimit = 10 ether;

     
    uint256 private finalJackpotValue = 0;

     
    bool public jackpotCompleted = false;

     
    struct Country {
        string name;
    }

    Country[] private countries;

     
    mapping (uint256 => address) public countryIndexToOwner;
     
    mapping (uint256 => address) public countryIndexToApproved;
     
    mapping (uint256 => uint256) public countryToRank;
     
    mapping (uint256 => uint256) private countryToLastPrice;
     
    mapping (uint256 => bool) public  jackpotClaimedForCountry;
     
    mapping (uint256 => uint256) public rankShare;

     
    mapping (address => uint256) private ownershipTokenCount;

     
    mapping (uint256 => uint256) private countryIndexToPrice;

     
    function CountryJackpot() public{
        rankShare[1] = 76;
        rankShare[2] = 56;
        rankShare[3] = 48;
        rankShare[4] = 44;
        rankShare[5] = 32;
        rankShare[6] = 24;
        rankShare[7] = 16;
    }

     
    function approve( address _to, uint256 _tokenId) public {
       
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        countryIndexToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

     
    function createCountry(string _name) public onlyOwner{
        _createCountry(_name, startingPrice);
    }

     
    function getEther(uint256 _countryIndex) public {
        require(countryIndexToOwner[_countryIndex] == msg.sender);
        require(jackpotCompleted);
        require(countryToRank[_countryIndex] != 0);
        require(!jackpotClaimedForCountry[_countryIndex]);

        jackpotClaimedForCountry[_countryIndex] = true;
        uint256 _rankShare = rankShare[countryToRank[_countryIndex]];

        uint256 amount = ((finalJackpotValue).mul(_rankShare)).div(1000);
        msg.sender.transfer(amount);
    }

     
    function getCountry(uint256 _tokenId) public view returns (
        string ,
        uint256 ,
        address ,
        uint256
    ) {
        Country storage country = countries[_tokenId];
        string memory countryName = country.name;
        uint256 sellingPrice = countryIndexToPrice[_tokenId];
        uint256 rank = countryToRank[_tokenId];
        address owner = countryIndexToOwner[_tokenId];
        return (countryName, sellingPrice, owner, rank);
    }

     
    function getContractBalance() public view returns(uint256) {
        return (address(this).balance);
    }

     
     
    function getJackpotTotalValue() public view returns(uint256) {
        if(jackpotCompleted){
            return finalJackpotValue;
        } else{
            return address(this).balance;
        }
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
        returns (address)
    {
        address owner = countryIndexToOwner[_tokenId];
        return (owner);
    }

     
    function () payable {
    }


     
    function purchase(uint256 _tokenId) public payable {
        require(!jackpotCompleted);
        require(msg.sender != owner);
        address oldOwner = countryIndexToOwner[_tokenId];
        address newOwner = msg.sender;

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        uint256 sellingPrice = countryIndexToPrice[_tokenId];
        uint256 lastSellingPrice = countryToLastPrice[_tokenId];

         
        if (sellingPrice.mul(2) < firstStepLimit) {
             
            countryIndexToPrice[_tokenId] = sellingPrice.mul(2);
        } else if (sellingPrice.mul(4).div(10) < secondStepLimit) {
             
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(4).div(10));
        } else if(sellingPrice.mul(2).div(10) < thirdStepLimit){
             
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(2).div(10));
        }else {
             
            countryIndexToPrice[_tokenId] = sellingPrice.add(sellingPrice.mul(15).div(100));
        }

        _transfer(oldOwner, newOwner, _tokenId);

         
        countryToLastPrice[_tokenId] = sellingPrice;
         
        if (oldOwner != owner) {
            uint256 priceDifference = sellingPrice.sub(lastSellingPrice);
            uint256 oldOwnerPayment = lastSellingPrice.add(priceDifference.sub(priceDifference.div(2)));
            oldOwner.transfer(oldOwnerPayment);
        }

        emit TokenSold(_tokenId, sellingPrice, countryIndexToPrice[_tokenId], oldOwner, newOwner, countries[_tokenId].name);

        uint256 purchaseExcess = msg.value.sub(sellingPrice);
        msg.sender.transfer(purchaseExcess);
    }

     
    function setCountryRank(uint256 _tokenId, string _name, uint256 _rank) public onlyOwner{
        require(_compareStrings(countries[_tokenId].name, _name));
        countryToRank[_tokenId] = _rank;
    }

     
    function setJackpotCompleted() public onlyOwner{
        jackpotCompleted = true;
        finalJackpotValue = address(this).balance;
        uint256 jackpotShare = ((address(this).balance).mul(20)).div(100);
        msg.sender.transfer(jackpotShare);
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
     
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = countryIndexToOwner[_tokenId];

         
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
            uint256 totalCountries = totalSupply();
            uint256 resultIndex = 0;
            uint256 countryId;

            for (countryId = 0; countryId < totalCountries; countryId++) {
                if (countryIndexToOwner[countryId] == _owner)
                {
                    result[resultIndex] = countryId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

     
     
    function totalSupply() public view returns (uint256 total) {
        return countries.length;
    }

     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        require(!jackpotCompleted);
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(!jackpotCompleted);
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

     
     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

     
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return countryIndexToApproved[_tokenId] == _to;
    }


     
    function _createCountry(string _name, uint256 _price) private {
        Country memory country = Country({
            name: _name
        });

        uint256 newCountryId = countries.push(country) - 1;

        countryIndexToPrice[newCountryId] = _price;
        countryIndexToOwner[newCountryId] = msg.sender;
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender].add(1);
    }

     
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == countryIndexToOwner[_tokenId];
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) private {
         
        delete countryIndexToApproved[_tokenId];

         
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
         
        countryIndexToOwner[_tokenId] = _to;

        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
         
        emit Transfer(_from, _to, _tokenId);
    }

    function _compareStrings(string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}
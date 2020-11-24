 

pragma solidity ^0.4.18;

 
 
contract ERC721 {
     
    function implementsERC721() public pure returns (bool);
     
    function name() public pure returns (string);
    function symbol() public pure returns (string);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function totalSupply() public view returns (uint256 total);
     
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
     
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract YTIcons is ERC721 {

     

     
    string public constant NAME = "YTIcons";
    string public constant SYMBOL = "YTIcon";

     
    address private _utilityFund = 0x6B06a2a15dCf3AE45b9F133Be6FD0Be5a9FAedC2;

     
     
    address private _charityFund = 0xF9864660c4aa89E241d7D44903D3c8A207644332;

    uint16 public _generation = 0;
    uint256 private _defaultPrice = 0.001 ether;
    uint256 private firstLimit =  0.05 ether;
    uint256 private secondLimit = 0.5 ether;
    uint256 private thirdLimit = 1 ether;


     

     
     
    address private _owner0x = 0x8E787E0c0B05BE25Ec993C5e109881166b675b31;
    address private _ownerA =  0x97fEA5464539bfE3810b8185E9Fa9D2D6d68a52c;
    address private _ownerB =  0x0678Ecc4Db075F89B966DE7Ea945C4A866966b0e;
    address private _ownerC =  0xC39574B02b76a43B03747641612c3d332Dec679B;
    address private _ownerD =  0x1282006521647ca094503219A61995C8142a9824;

    Card[] private _cards;

     
     
     
    mapping (uint256 => uint256[3]) private _cardsPrices;

     
    mapping (uint256 => address) private _beneficiaryAddresses;

     
    mapping (uint256 => address) private _cardsOwners;

     
     
    mapping (address => uint256) private _tokenPerOwners;

     
     
     
    mapping (uint256 => address) public _allowedAddresses;


     

    struct Card {
        uint16  generation;
        string  name;
        bool    isLocked;
    }

     
    event YTIconSold(uint256 tokenId, uint256 newPrice, address newOwner);
    event PriceModified(uint256 tokenId, uint256 newPrice);



     

     
    modifier ownerOnly() {
        require(msg.sender == _owner0x || msg.sender == _ownerA || msg.sender == _ownerB || msg.sender == _ownerC || msg.sender == _ownerD);
        _;
    }


     

    function implementsERC721() public pure returns (bool) {
        return true;
    }

         
         
         

     
    function name() public pure returns (string) {
        return NAME;
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
     
    function totalSupply() public view returns (uint256 supply) {
        return _cards.length;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return _tokenPerOwners[_owner];
    }

         
         
         

     
     
     
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        require(_addressNotNull(_cardsOwners[_tokenId]));
        return _cardsOwners[_tokenId];
    }

     
    function approve(address _to, uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        require(_owns(msg.sender, _tokenId));
        require(msg.sender != _to);
        _allowedAddresses[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
    function takeOwnership(uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        address newOwner = msg.sender;
        address oldOwner = _cardsOwners[_tokenId];
        require(_addressNotNull(newOwner));
        require(newOwner != oldOwner);
        require(_isAllowed(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

     
    function transfer(address _to, uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        require(_owns(msg.sender, _tokenId));
        require(msg.sender != _to);
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
         
        _cardsOwners[tokenId] = to;
         
        _tokenPerOwners[to] += 1;

         
        if (from != address(0)) {
            _tokenPerOwners[from] -= 1;
             
            delete _allowedAddresses[tokenId];
        }

         
        Transfer(from, to, tokenId);
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(!_cards[tokenId].isLocked);
        require(_owns(from, tokenId));
        require(_isAllowed(to, tokenId));
        require(_addressNotNull(to));

        _transfer(from, to, tokenId);
    }


     

    function createCard(string cardName, uint price, address cardOwner, address beneficiary, bool isLocked) public ownerOnly {
        require(bytes(cardName).length != 0);
        price = price == 0 ? _defaultPrice : price;
        _createCard(cardName, price, cardOwner, beneficiary, isLocked);
    }

    function createCardFromName(string cardName) public ownerOnly {
        require(bytes(cardName).length != 0);
        _createCard(cardName, _defaultPrice, address(0), address(0), false);
    }

     
    function _createCard(string cardName, uint price, address cardOwner, address beneficiary, bool isLocked) private {
        require(_cards.length < 2^256 - 1);
        Card memory card = Card({
                                    generation: _generation,
                                    name: cardName,
                                    isLocked: isLocked
                                });
        _cardsPrices[_cards.length][0] = price;  
        _cardsPrices[_cards.length][1] = price;  
        _cardsPrices[_cards.length][2] = price;  
        _cardsOwners[_cards.length] = cardOwner;
        _beneficiaryAddresses[_cards.length] = beneficiary;
        _tokenPerOwners[cardOwner] += 1;
        _cards.push(card);
    }


     
    function evolveGeneration(uint16 newGeneration) public ownerOnly {
        _generation = newGeneration;
    }

     
    function setOwner(address currentAddress, address newAddress) public ownerOnly {
        require(_addressNotNull(newAddress));

        if (currentAddress == _ownerA) {
            _ownerA = newAddress;
        } else if (currentAddress == _ownerB) {
            _ownerB = newAddress;
        } else if (currentAddress == _ownerC) {
            _ownerC = newAddress;
        } else if (currentAddress == _ownerD) {
            _ownerD = newAddress;
        }
    }

     
    function setCharityFund(address newCharityFund) public ownerOnly {
        _charityFund = newCharityFund;
    }

     
    function setBeneficiaryAddress(uint256 tokenId, address beneficiaryAddress) public ownerOnly {
        require(bytes(_cards[tokenId].name).length != 0);
        _beneficiaryAddresses[tokenId] = beneficiaryAddress;
    }

     
    function lock(uint256 tokenId) public ownerOnly {
        require(!_cards[tokenId].isLocked);
        _cards[tokenId].isLocked = true;
    }

     
    function unlock(uint256 tokenId) public ownerOnly {
        require(_cards[tokenId].isLocked);
        _cards[tokenId].isLocked = false;
    }

     
    function payout() public ownerOnly {
        _payout();
    }

    function _payout() private {
        uint256 balance = this.balance;
        _ownerA.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerB.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerC.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerD.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _utilityFund.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
    }


     

     
    function _addressNotNull(address target) private pure returns (bool) {
        return target != address(0);
    }

     
    function _owns(address pretender, uint256 tokenId) private view returns (bool) {
        return pretender == _cardsOwners[tokenId];
    }

    function _isAllowed(address claimant, uint256 tokenId) private view returns (bool) {
        return _allowedAddresses[tokenId] == claimant;
    }

     

     
    function getCard(uint256 tokenId) public view returns (string cardName, uint16 generation, bool isLocked, uint256 price, address owner, address beneficiary, bool isVerified) {
        Card storage card = _cards[tokenId];
        cardName = card.name;
        require(bytes(cardName).length != 0);
        generation = card.generation;
        isLocked = card.isLocked;
        price = _cardsPrices[tokenId][0];
        owner = _cardsOwners[tokenId];
        beneficiary = _beneficiaryAddresses[tokenId];
        isVerified = _addressNotNull(_beneficiaryAddresses[tokenId]) ? true : false;
    }

     
    function setPrice(uint256 tokenId, uint256 newPrice) public {
        require(!_cards[tokenId].isLocked);
         
         
         
        require(newPrice > 0 && newPrice >= _cardsPrices[tokenId][1] && newPrice <= _cardsPrices[tokenId][2]);
        require(msg.sender == _cardsOwners[tokenId]);

        _cardsPrices[tokenId][0] = newPrice;
        PriceModified(tokenId, newPrice);
    }

    function purchase(uint256 tokenId) public payable {
        require(!_cards[tokenId].isLocked);
        require(_cardsPrices[tokenId][0] > 0);

        address oldOwner = _cardsOwners[tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = _cardsPrices[tokenId][0];

         
        require(oldOwner != newOwner);

        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));
        uint256 beneficiaryPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 3), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        uint256 newPrice = 0;

         
        if (sellingPrice < firstLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 92);
        } else if (sellingPrice < secondLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 150), 92);
        } else if (sellingPrice < thirdLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 125), 92);
        } else {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 115), 92);
        }

        _cardsPrices[tokenId][0] = newPrice;  
        _cardsPrices[tokenId][1] = sellingPrice;  
        _cardsPrices[tokenId][2] = newPrice;  

        _transfer(oldOwner, newOwner, tokenId);

         
        if (oldOwner != address(this) && oldOwner != address(0)) {
            oldOwner.transfer(payment);
        }

        if (_beneficiaryAddresses[tokenId] != address(0)) {
            _beneficiaryAddresses[tokenId].transfer(beneficiaryPayment);
        } else {
            _charityFund.transfer(beneficiaryPayment);
        }

        YTIconSold(tokenId, newPrice, newOwner);

        msg.sender.transfer(purchaseExcess);
    }

    function getOwnerCards(address owner) public view returns(uint256[] ownerTokens) {
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            uint256 cardId;
            for (cardId = 0; cardId <= total; cardId++) {
                if (_cardsOwners[cardId] == owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getHighestPrice(uint256 tokenId) public view returns(uint256 highestPrice) {
        highestPrice = _cardsPrices[tokenId][1];
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

}
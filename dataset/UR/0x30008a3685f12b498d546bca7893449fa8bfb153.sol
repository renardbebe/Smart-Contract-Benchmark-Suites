 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity 0.5.0;

library Strings {

     
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

 

pragma solidity 0.5.0;

interface INiftyTradingCardCreator {
    function mintCard(
        uint256 _cardType,
        uint256 _nationality,
        uint256 _position,
        uint256 _ethnicity,
        uint256 _kit,
        uint256 _colour,
        address _to
    ) external returns (uint256 _tokenId);

    function setAttributes(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill
    ) external returns (bool);

    function setName(
        uint256 _tokenId,
        uint256 _firstName,
        uint256 _lastName
    ) external returns (bool);

    function setAttributesAndName(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill,
        uint256 _firstName,
        uint256 _lastName
    ) external returns (bool);
}

 

pragma solidity 0.5.0;

contract INiftyFootballTradingCardGenerator {
    function generateCard(address _sender) external returns (uint256 _nationality, uint256 _position, uint256 _ethnicity, uint256 _kit, uint256 _colour);

    function generateAttributes(address _sender, uint256 _base) external returns (uint256 strength, uint256 speed, uint256 intelligence, uint256 skill);

    function generateName(address _sender) external returns (uint256 firstName, uint256 lastName);
}

 

pragma solidity ^0.5.0;



contract FundsSplitter is Ownable {
    using SafeMath for uint256;

    address payable public platform;
    address payable public partner;

    uint256 public partnerRate = 7;

    constructor (address payable _platform, address payable _partner) public {
        platform = _platform;
        partner = _partner;
    }

    function splitFunds(uint256 _totalPrice) internal {
        if (msg.value > 0) {
            uint256 refund = msg.value.sub(_totalPrice);

             
            if (refund > 0) {
                msg.sender.transfer(refund);
            }

             
            uint256 partnerAmount = _totalPrice.div(100).mul(partnerRate);
            partner.transfer(partnerAmount);

             
            uint256 remaining = _totalPrice.sub(partnerAmount);
            platform.transfer(remaining);
        }
    }

    function updatePartnerAddress(address payable _partner) onlyOwner public {
        partner = _partner;
    }

    function updatePartnerRate(uint256 _techPartnerRate) onlyOwner public {
        partnerRate = _techPartnerRate;
    }

    function updatePlatformAddress(address payable _platform) onlyOwner public {
        platform = _platform;
    }

    function withdraw() public onlyOwner returns (bool) {
        platform.transfer(address(this).balance);
        return true;
    }
}

 

pragma solidity 0.5.0;









contract NiftyFootballTradingCardEliteBlindPack is Ownable, Pausable, FundsSplitter {
    using SafeMath for uint256;

    event PriceInWeiChanged(uint256 _old, uint256 _new);

    event DefaultCardTypeChanged(uint256 _new);

    event AttributesBaseChanged(uint256 _new);

    event FutballCardsGeneratorChanged(INiftyFootballTradingCardGenerator _new);

    INiftyFootballTradingCardGenerator public generator;
    INiftyTradingCardCreator public creator;

    uint256 public totalPurchasesInWei = 0;
    uint256 public cardTypeDefault = 0;
    uint256 public attributesBase = 60;  

    uint256[] public pricePerCard = [
     
    16000000000000000,  
    16000000000000000,  

     
    14500000000000000,  
    14500000000000000,  
    14500000000000000,  

     
    13500000000000000,  
    13500000000000000,  
    13500000000000000,  

     
    12500000000000000,  
    12500000000000000  
    ];

    constructor (
        address payable _wallet,
        address payable _partnerAddress,
        INiftyFootballTradingCardGenerator _generator,
        INiftyTradingCardCreator _creator
    ) public FundsSplitter(_wallet, _partnerAddress) {
        generator = _generator;
        creator = _creator;
    }

    function blindPack() whenNotPaused public payable {
        blindPackTo(msg.sender);
    }

    function blindPackTo(address _to) whenNotPaused public payable {
        uint256 _totalPrice = totalPrice(1);
        require(
            msg.value >= _totalPrice,
            "Must supply at least the required minimum purchase value"
        );
        require(!isContract(msg.sender), "Unable to buy packs from another contract");

        _generateAndAssignCard(_to);

        _takePayment(1, _totalPrice);
    }

    function buyBatch(uint256 _numberOfCards) whenNotPaused public payable {
        return buyBatchTo(msg.sender, _numberOfCards);
    }

    function buyBatchTo(address _to, uint256 _numberOfCards) whenNotPaused public payable {
        uint256 _totalPrice = totalPrice(_numberOfCards);
        require(
            msg.value >= _totalPrice,
            "Must supply at least the required minimum purchase value"
        );
        require(!isContract(msg.sender), "Unable to buy packs from another contract");

        for (uint i = 0; i < _numberOfCards; i++) {
            _generateAndAssignCard(_to);
        }

        _takePayment(_numberOfCards, _totalPrice);
    }

    function _generateAndAssignCard(address _to) internal {
         
        (uint256 _nationality, uint256 _position, uint256 _ethnicity, uint256 _kit, uint256 _colour) = generator.generateCard(msg.sender);

         
        uint256 tokenId = creator.mintCard(cardTypeDefault, _nationality, _position, _ethnicity, _kit, _colour, _to);
        
         
        (uint256 _strength, uint256 _speed, uint256 _intelligence, uint256 _skill) = generator.generateAttributes(msg.sender, attributesBase);
        (uint256 _firstName, uint256 _lastName) = generator.generateName(msg.sender);

        creator.setAttributesAndName(tokenId, _strength, _speed, _intelligence, _skill, _firstName, _lastName);
    }

    function _takePayment(uint256 _numberOfCards, uint256 _totalPrice) internal {
         
        totalPurchasesInWei = totalPurchasesInWei.add(_totalPrice);
        splitFunds(_totalPrice);
    }

    function setCardTypeDefault(uint256 _newDefaultCardType) public onlyOwner returns (bool) {
        cardTypeDefault = _newDefaultCardType;

        emit DefaultCardTypeChanged(_newDefaultCardType);

        return true;
    }

    function setAttributesBase(uint256 _newAttributesBase) public onlyOwner returns (bool) {
        attributesBase = _newAttributesBase;

        emit AttributesBaseChanged(_newAttributesBase);

        return true;
    }

    function setFutballCardsGenerator(INiftyFootballTradingCardGenerator _futballCardsGenerator) public onlyOwner returns (bool) {
        generator = _futballCardsGenerator;

        emit FutballCardsGeneratorChanged(_futballCardsGenerator);

        return true;
    }

    function updatePricePerCardAtIndex(uint256 _index, uint256 _priceInWei) public onlyOwner returns (bool) {
        pricePerCard[_index] = _priceInWei;
        return true;
    }

    function updatePricePerCard(uint256[] memory _pricePerCard) public onlyOwner returns (bool) {
        pricePerCard = _pricePerCard;
        return true;
    }

    function totalPrice(uint256 _numberOfCards) public view returns (uint256) {
        if (_numberOfCards > pricePerCard.length) {
            return pricePerCard[pricePerCard.length - 1].mul(_numberOfCards);
        }
        return pricePerCard[_numberOfCards - 1].mul(_numberOfCards);
    }

     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}
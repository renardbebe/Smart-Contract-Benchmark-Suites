 

pragma solidity ^0.5.10;

 
contract CardCore {
    function approve(address _approved, uint256 _tokenId) external payable;
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function getApproved(uint256 _tokenId) external view returns (address);
}






 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}



 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor() public {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}



 
 
 
 
 
 
 
 
 
 
 
contract WrappedMarbleCard is ERC20, Ownable, ReentrancyGuard {

     
    using SafeMath for uint256;

     
     
     

     
     
     
    event DepositCardAndMintToken(
        uint256 cardId
    );

     
     
     
    event BurnTokenAndWithdrawCard(
        uint256 cardId
    );

     
     
     

     
     
     
     
     
     
     
    uint256[] private depositedCardsArray;

     
    mapping (uint256 => DepositedCard) private cardsInIndex;

     
    struct DepositedCard {
        bool inContract;
        uint256 cardIndex;
    }

     
     
     

     
    uint8 constant public decimals = 18;
    string constant public name = "Wrapped MarbleCards";
    string constant public symbol = "WMC";
    uint256 constant internal cardInWei = uint256(10)**decimals;

     
     
     
     
     
     
    address public cardCoreAddress = 0x1d963688FE2209A98dB35C67A041524822Cf04ff;
    CardCore cardCore;

     
     
     


     
     
     
     
     
     
     
     
    function depositCardsAndMintTokens(uint256[] calldata _cardIds) external nonReentrant {
        require(_cardIds.length > 0, 'you must submit an array with at least one element');
        for(uint i = 0; i < _cardIds.length; i++){
            uint256 cardToDeposit = _cardIds[i];
            require(msg.sender == cardCore.ownerOf(cardToDeposit), 'you do not own this card');
            require(cardCore.getApproved(cardToDeposit) == address(this), 'you must approve() this contract to give it permission to withdraw this card before you can deposit a card');
            cardCore.transferFrom(msg.sender, address(this), cardToDeposit);
            _pushCard(cardToDeposit);
            emit DepositCardAndMintToken(cardToDeposit);
        }
        _mint(msg.sender, (_cardIds.length).mul(cardInWei));
    }


     
     
     
     
     
     
    function burnTokensAndWithdrawCards(uint256[] calldata _cardIds, address[] calldata _destinationAddresses) external nonReentrant {
        require(_cardIds.length == _destinationAddresses.length, 'you did not provide a destination address for each of the cards you wish to withdraw');
        require(_cardIds.length > 0, 'you must submit an array with at least one element');

        uint256 numTokensToBurn = _cardIds.length;
        require(balanceOf(msg.sender) >= numTokensToBurn.mul(cardInWei), 'you do not own enough tokens to withdraw this many ERC721 cards');
        _burn(msg.sender, numTokensToBurn.mul(cardInWei));

        for(uint i = 0; i < numTokensToBurn; i++){
            uint256 cardToWithdraw = _cardIds[i];
            if(cardToWithdraw == 0){
                cardToWithdraw = _popCard();
            } else {
                require(isCardInDeck(cardToWithdraw), 'this card is not in the deck');
                require(address(this) == cardCore.ownerOf(cardToWithdraw), 'the contract does not own this card');
                _removeFromDeck(cardToWithdraw);
            }
            cardCore.transferFrom(address(this), _destinationAddresses[i], cardToWithdraw);
            emit BurnTokenAndWithdrawCard(cardToWithdraw);
        }
    }

     
     
    function _pushCard(uint256 _cardId) internal {
         
        uint256 index = depositedCardsArray.push(_cardId) - 1;
        DepositedCard memory _card = DepositedCard(true, index);
        cardsInIndex[_cardId] = _card;
    }

     
     
    function _popCard() internal returns(uint256) {
        require(depositedCardsArray.length > 0, 'there are no cards in the array');
        uint256 cardId = depositedCardsArray[depositedCardsArray.length - 1];
        _removeFromDeck(cardId);
        return cardId;
    }

     
     
    constructor() public {
        cardCore = CardCore(cardCoreAddress);
    }

     
     
    function() external payable {}

     
     
    function extractAccidentalPayableEth() public onlyOwner returns (bool) {
        require(address(this).balance > 0);
        address(uint160(owner())).transfer(address(this).balance);
        return true;
    }

     
    function _getCardIndex(uint256 _cardId) internal view returns (uint256) {
        require(isCardInDeck(_cardId));
        return cardsInIndex[_cardId].cardIndex;
    }

     
    function isCardInDeck(uint256 _cardId) public view returns (bool) {
        return cardsInIndex[_cardId].inContract;
    }

     
    function _removeFromDeck(uint256 _cardId) internal {
         
        uint256 index = _getCardIndex(_cardId);
         
        uint256 cardToMove = depositedCardsArray[depositedCardsArray.length - 1];
         
         
        depositedCardsArray[index] = cardToMove;
         
        cardsInIndex[cardToMove].cardIndex = index;
         
        delete cardsInIndex[_cardId];
        depositedCardsArray.length--;
    }

}
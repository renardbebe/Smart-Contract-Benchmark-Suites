 

pragma solidity ^0.5.5;

 

contract DreamCarToken {
    function getForWLC(address _owner) public {}
}

contract WishListToken {
    string internal constant tokenName   = 'WishListCoin';
    string internal constant tokenSymbol = 'WLC';
    
    uint256 public constant decimals = 0;
    
     
    uint256 public totalTokenSupply;
    
     
    address payable public CEO;
    
     
    mapping (address => uint256[]) internal tokensOwnedBy;
    
     
    mapping (address => uint256[]) internal tokensExchangedBy;
    
     
    uint256 public tokenPrice;
    
     
    address[] public priceAdmins;
    
     
    uint256 internal nextTokenId = 1;
    
     
    
     
    DreamCarToken public dreamCarCoinExchanger;
    
     
    function totalSupply() public view returns (uint256 total) {
        return totalTokenSupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokensOwnedBy[_owner].length;
    }
    
     
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds) {
        return tokensOwnedBy[_owner];
    }
    
     
    function tokenIsOwnedBy(uint256 _tokenId, address _owner) external view returns (bool isTokenOwner) {
        for (uint256 i = 0; i < balanceOf(_owner); i++) {
            if (tokensOwnedBy[_owner][i] == _tokenId) {
                return true;
            }
        }
        
        return false;
    }
    
     
    function transfer(address _to, uint256 _tokenId) external {
        require(_to != address(0));
        
        uint256 tokenIndex = getTokenIndex(msg.sender, _tokenId);
        
         
        tokensOwnedBy[msg.sender][tokenIndex] = tokensOwnedBy[msg.sender][tokensOwnedBy[msg.sender].length - 1];
        tokensOwnedBy[msg.sender].pop();
        
        tokensOwnedBy[_to].push(_tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }
   
     
    function name() external pure returns (string memory _name) {
        return tokenName;
    }
    
     
    function symbol() external pure returns (string memory _symbol) {
        return tokenSymbol;
    }
    
    event Transfer(address from, address to, uint256 tokenId);
    
    event Buy(address indexed from, uint256 amount, uint256 fromTokenId, uint256 toTokenId, uint256 timestamp);
    
    event Exchange(address indexed from, uint256 tokenId);
    
    event ExchangeForDCC(address indexed from, uint256 tokenId);
    
     
    modifier onlyCEO {
        require(msg.sender == CEO, 'You need to be the CEO to do that!');
        _;
    }
    
     
    constructor (address payable _ceo) public {
        CEO = _ceo;
        
        totalTokenSupply = 1000000;
        
        tokenPrice = 22250000000000000;  
    }

     
    function exchangedBy(address _owner) external view returns (uint256[] memory tokenIds) {
        return tokensExchangedBy[_owner];
    }
    
     
    function lastTokenId() public view returns (uint256 tokenId) {
        return nextTokenId - 1;
    }
    
     
    function setTokenPriceInWEI(uint256 _newPrice) public {
        bool transactionAllowed = false;
        
        if (msg.sender == CEO) {
            transactionAllowed = true;
        } else {
            for (uint256 i = 0; i < priceAdmins.length; i++) {
                if (msg.sender == priceAdmins[i]) {
                    transactionAllowed = true;
                    break;
                }
            }
        }
        
        require((transactionAllowed == true), 'You cannot do that!');
        tokenPrice = _newPrice;
    }
    
     
    function addPriceAdmin(address _newPriceAdmin) onlyCEO public {
        priceAdmins.push(_newPriceAdmin);
    }
    
     
    function removePriceAdmin(address _existingPriceAdmin) onlyCEO public {
        for (uint256 i = 0; i < priceAdmins.length; i++) {
            if (_existingPriceAdmin == priceAdmins[i]) {
                delete priceAdmins[i];
                break;
            }
        }
    }
    
     
    function getTokenIndex(address _owner, uint256 _tokenId) internal view returns (uint256 _index) {
        for (uint256 i = 0; i < balanceOf(_owner); i++) {
            if (tokensOwnedBy[_owner][i] == _tokenId) {
                return i;
            }
        }
        
        require(false, 'You do not own this token!');
    }
    
     
    function _addTokensToAddress(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            tokensOwnedBy[_to].push(nextTokenId + i);
        }
        
        nextTokenId += _amount;
    }
    
     
    function scalePurchaseTokenAmountToMatchRemainingTokens(uint256 _amount) internal view returns (uint256 _exactAmount) {
        if (nextTokenId + _amount - 1 > totalTokenSupply) {
            _amount = totalTokenSupply - nextTokenId + 1;
        }
        
        return _amount;
    }
    
     
    function buy() payable public {
        require(msg.value >= tokenPrice, "You did't send enough ETH");
        
        uint256 amount = scalePurchaseTokenAmountToMatchRemainingTokens(msg.value / tokenPrice);
        
        require(amount > 0, "Not enough tokens are available for purchase!");
        
        _addTokensToAddress(msg.sender, amount);
        
        emit Buy(msg.sender, amount, nextTokenId - amount, nextTokenId - 1, now);
        
         
        CEO.transfer((amount * tokenPrice));
        
         
        msg.sender.transfer(msg.value - (amount * tokenPrice));
    }
    
     
    function exchangeToken(address _owner, uint256 _tokenId) internal {
        uint256 tokenIndex = getTokenIndex(_owner, _tokenId);
        
         
        tokensOwnedBy[msg.sender][tokenIndex] = tokensOwnedBy[msg.sender][tokensOwnedBy[msg.sender].length - 1];
        tokensOwnedBy[msg.sender].pop();

        tokensExchangedBy[_owner].push(_tokenId);
    }
    
     
    function exchange(uint256 _tokenId) public {
        exchangeToken(msg.sender, _tokenId);
        
        emit Exchange(msg.sender, _tokenId);
    }
    
     
    function mint(uint256 _amount) onlyCEO public {
        require (_amount > 0, 'Amount must be bigger than 0!');
        totalTokenSupply += _amount;
    }
    
     
    
     
    function setDreamCarCoinExchanger(address _address) public onlyCEO {
        require (_address != address(0));
        dreamCarCoinExchanger = DreamCarToken(_address);
    }
    
     
    function removeDreamCarCoinExchanger() public onlyCEO {
        dreamCarCoinExchanger = DreamCarToken(address(0));
    }
    
     
    function exchangeForDCC(uint256 _tokenId) public {
        require (address(dreamCarCoinExchanger) != address(0));
        
        dreamCarCoinExchanger.getForWLC(msg.sender);
        
        exchangeToken(msg.sender, _tokenId);
        
        emit ExchangeForDCC(msg.sender, _tokenId);
    }
}
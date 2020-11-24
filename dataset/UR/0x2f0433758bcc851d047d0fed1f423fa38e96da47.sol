 

pragma solidity ^0.5.5;

 

 
 
interface ERC721 {
     
    function totalSupply() external view returns (uint256 total);
    
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function exists(uint256 _tokenId) external view returns (bool _exists);
    
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds);
    
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract ERC721Metadata is ERC721 {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string memory);
}

contract DreamCarToken {
    function getWLCReward(uint256 _boughtWLCAmount, address _owner) public returns (uint256 remaining) {}
    
    function getForWLC(address _owner) public {}
}

contract WishListToken is ERC721, ERC721Metadata {
    string internal constant tokenName   = 'WishListCoin';
    string internal constant tokenSymbol = 'WLC';
    
    uint256 public constant decimals = 0;
    
     
    
     
    uint256 public totalTokenSupply;
    
     
    address payable public CEO;
    
    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));
    
     
    mapping (uint256 => address) internal tokenOwner;
    
     
    mapping(uint256 => uint256) internal ownedTokensIndex;
    
     
    mapping(uint256 => string) internal tokenURIs;
    
     
    
     
    mapping (address => uint256[]) internal tokensOwnedBy;
    
     
    mapping (address => uint256[]) internal tokensExchangedBy;
    
     
    uint256 public tokenPrice;
    
     
    address[] public priceAdmins;
    
     
    uint256 internal nextTokenId = 1;
    
     
    
     
     
    DreamCarToken[] public dreamCarCoinContracts;
    
     
    DreamCarToken public dreamCarCoinExchanger;
    
     
    
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
     
    function totalSupply() public view returns (uint256 total) {
        return totalTokenSupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return tokensOwnedBy[_owner].length;
    }
    
     
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return tokenOwner[_tokenId];
    }
    
     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }
    
     
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds) {
        return tokensOwnedBy[_owner];
    }
    
     
    function transfer(address _to, uint256 _tokenId) external {
        require(_to != address(0));
        
        ensureAddressIsTokenOwner(msg.sender, _tokenId);
        
         
        tokensOwnedBy[msg.sender][ownedTokensIndex[_tokenId]] = tokensOwnedBy[msg.sender][tokensOwnedBy[msg.sender].length - 1];
        
         
        ownedTokensIndex[tokensOwnedBy[msg.sender][tokensOwnedBy[msg.sender].length - 1]] = ownedTokensIndex[_tokenId];
        
         
        tokensOwnedBy[msg.sender].pop();
        
         
        tokensOwnedBy[_to].push(_tokenId);
        
        tokenOwner[_tokenId] = _to;
        ownedTokensIndex[_tokenId] = tokensOwnedBy[_to].length - 1;
        
        emit Transfer(msg.sender, _to, _tokenId);
    }
    
     
    function approve(address _to, uint256 _tokenId) external { }
    
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external { }
    
     
    function _setTokenURI(uint256 _tokenId, string storage _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }
    
     
     
    function name() external view returns (string memory _name) {
        return tokenName;
    }
    
     
    function symbol() external view returns (string memory _symbol) {
        return tokenSymbol;
    }
    
     
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }
    
     
    
    event Buy(address indexed from, uint256 amount, uint256 fromTokenId, uint256 toTokenId, uint256 timestamp);
    
    event Exchange(address indexed from, uint256 tokenId);
    
    event ExchangeForDCC(address indexed from, uint256 tokenId);
    
     
    modifier onlyCEO {
        require(msg.sender == CEO, 'You need to be the CEO to do that!');
        _;
    }
    
     
    constructor (address payable _ceo) public {
        CEO = _ceo;
        
        totalTokenSupply = 1001000;
        
        tokenPrice = 3067484662576687;  
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
    
     
    function _addTokensToAddress(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            tokensOwnedBy[_to].push(nextTokenId + i);
            tokenOwner[nextTokenId + i] = _to;
            ownedTokensIndex[nextTokenId + i] = tokensOwnedBy[_to].length - 1;
        }
        
        nextTokenId += _amount;
    }
    
     
    function ensureAddressIsTokenOwner(address _owner, uint256 _tokenId) internal view {
        require(balanceOf(_owner) >= 1, 'You do not own any tokens!');
        
        require(tokenOwner[_tokenId] == _owner, 'You do not own this token!');
    }
    
     
    function scalePurchaseTokenAmountToMatchRemainingTokens(uint256 _amount) internal view returns (uint256 _exactAmount) {
        if (nextTokenId + _amount - 1 > totalTokenSupply) {
            _amount = totalTokenSupply - nextTokenId + 1;
        }
        
        if (balanceOf(msg.sender) + _amount > 100) {
            _amount = 100 - balanceOf(msg.sender);
            require(_amount > 0, "You can own maximum of 100 tokens!");
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
        
        getDCCRewards(amount);
        
         
        msg.sender.transfer(msg.value - (amount * tokenPrice));
    }
    
     
    function exchangeToken(address _owner, uint256 _tokenId) internal {
        ensureAddressIsTokenOwner(_owner, _tokenId);
        
         
        tokensOwnedBy[_owner][ownedTokensIndex[_tokenId]] = tokensOwnedBy[_owner][tokensOwnedBy[_owner].length - 1];
        
         
        ownedTokensIndex[tokensOwnedBy[_owner][tokensOwnedBy[_owner].length - 1]] = ownedTokensIndex[_tokenId];
        
         
        tokensOwnedBy[_owner].pop();
        
        ownedTokensIndex[_tokenId] = 0;
        
        delete tokenOwner[_tokenId];
        
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
    
     
    
     
    function setDreamCarCoinAddress(uint256 _index, address _address) public onlyCEO {
        require (_address != address(0));
        if (dreamCarCoinContracts.length > 0 && dreamCarCoinContracts.length - 1 >= _index) {
            dreamCarCoinContracts[_index] = DreamCarToken(_address);
        } else {
            dreamCarCoinContracts.push(DreamCarToken(_address));
        }
    }
    
     
    function removeDreamCarCoinAddress(uint256 _index) public onlyCEO {
        delete(dreamCarCoinContracts[_index]);
    }
    
     
    function setDreamCarCoinExchanger(address _address) public onlyCEO {
        require (_address != address(0));
        dreamCarCoinExchanger = DreamCarToken(_address);
    }
    
     
    function removeDreamCarCoinExchanger() public onlyCEO {
        dreamCarCoinExchanger = DreamCarToken(address(0));
    }
    
     
    function getDCCRewards(uint256 _amount) internal {
        for (uint256 i = 0; i < dreamCarCoinContracts.length; i++) {
            if (_amount > 0 && address(dreamCarCoinContracts[i]) != address(0)) {
                _amount = dreamCarCoinContracts[i].getWLCReward(_amount, msg.sender);
            } else {
                break;
            }
        }
    }
    
     
    function exchangeForDCC(uint256 _tokenId) public {
        require (address(dreamCarCoinExchanger) != address(0));
        
        dreamCarCoinExchanger.getForWLC(msg.sender);
        
        exchangeToken(msg.sender, _tokenId);
        
        emit ExchangeForDCC(msg.sender, _tokenId);
    }
}
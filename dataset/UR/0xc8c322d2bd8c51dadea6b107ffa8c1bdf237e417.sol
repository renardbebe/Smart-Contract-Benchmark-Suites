 

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

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract ERC721Metadata is ERC721 {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string memory);
}

 
interface WLCCompatible {
    function getWLCReward(uint256 _boughtWLCAmount, address _owner) external returns (uint256 _remaining);
    function setWLCParams(address _address, uint256 _reward) external;
    function resetWLCParams() external;
    
    function getForWLC(address _owner) external;
    
    function getWLCRewardAmount() external view returns (uint256 _amount);
    function getWLCAddress() external view returns (address _address);
}

contract DreamCarToken2 is ERC721, ERC721Metadata, WLCCompatible {
    string internal constant tokenName   = 'DreamCarCoin2';
    string internal constant tokenSymbol = 'DCC2';
    
    uint8 public constant decimals = 0;
    
     
    
     
    uint256 internal totalTokenSupply;
    
     
    address payable public CEO;
    
    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalTokenSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));
    
     
     
    
     
    mapping (uint256 => address) internal tokenOwner;
    
     
    mapping(uint256 => string) internal tokenURIs;
    
     

    mapping (address => uint256) internal tokenBallanceOf;
    
     
    uint256 public tokenPrice;
    
     
    address[] public priceAdmins;
    
     
    uint256 internal nextTokenId = 1;
    
     
    uint256 public winningTokenId = 0;
    
     
    address public winnerAddress; 
    
     
    
     
    uint256 internal WLCRewardAmount;
    
     
    address internal WLCAdress;
    
     
    
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
     
    function totalSupply() public view returns (uint256 total) {
        return totalTokenSupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return tokenBallanceOf[_owner];
    }
    
     
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return tokenOwner[_tokenId];
    }
    
     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }
    
     
    function transfer(address _to, uint256 _tokenId) external { }
    
     
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
    
     
    
    event Buy(address indexed from, uint256 amount, uint256 fromTokenId, uint256 toTokenId);
    
    event RewardIsClaimed(address indexed from, uint256 tokenId);
    
    event WinnerIsChosen(address indexed from, uint256 tokenId);
    
     
    modifier onlyCEO {
        require(msg.sender == CEO, 'You need to be the CEO to do that!');
        _;
    }
    
     
    constructor (address payable _ceo) public {
        CEO = _ceo;
        
        totalTokenSupply = 20000;
        
        tokenPrice = 14685225386285277;  
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
            tokenOwner[nextTokenId + i] = _to;
        }
        
        tokenBallanceOf[_to] += _amount;
        
        nextTokenId += _amount;
    }
    
     
    function ensureAddressIsTokenOwner(address _owner, uint256 _tokenId) internal view {
        require(balanceOf(_owner) >= 1, 'You do not own any tokens!');
        
        require(tokenOwner[_tokenId] == _owner, 'You do not own this token!');
    }
    
     
    function getRandomNumber() internal view returns (uint16) {
        return uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.difficulty, block.number)
                    )
                )%totalTokenSupply
            ) + 1;
    }
    
     
    function chooseWinner() internal {
         if ((nextTokenId - 1) == totalTokenSupply) {
            winningTokenId = getRandomNumber();
            emit WinnerIsChosen(tokenOwner[winningTokenId], winningTokenId);
        } 
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
        
        emit Buy(msg.sender, amount, nextTokenId - amount, nextTokenId - 1);
        
         
        CEO.transfer((amount * tokenPrice));
        
         
        msg.sender.transfer(msg.value - (amount * tokenPrice));
        
        chooseWinner();
    }
    
     
    function claimReward(uint256 _tokenId) public {
        require(winningTokenId > 0, "The is not winner yet!");
        require(_tokenId == winningTokenId, "This token is not the winner!");
        
        ensureAddressIsTokenOwner(msg.sender, _tokenId);
        
        winnerAddress = msg.sender;
        
        emit RewardIsClaimed(msg.sender, _tokenId);
    }
    
     
    
     
    function setWLCParams(address _address, uint256 _reward) public onlyCEO {
        WLCAdress = _address;
        WLCRewardAmount = _reward;
    }
    
     
    function resetWLCParams() public onlyCEO {
        WLCAdress = address(0);
        WLCRewardAmount = 0;
    }
    
     
    function getWLCRewardAmount() public view returns (uint256 _amount) {
        return WLCRewardAmount;
    }
    
     
    function getWLCAddress() public view returns (address _address) {
        return WLCAdress;
    }
    
     
    function getWLCReward(uint256 _boughtWLCAmount, address _owner) public returns (uint256 _remaining) {
        if (WLCAdress != address(0) && WLCRewardAmount > 0 && _boughtWLCAmount >= WLCRewardAmount) {
            require(WLCAdress == msg.sender, "You cannot invoke this function directly!");
            
            uint256 DCCAmount = scalePurchaseTokenAmountToMatchRemainingTokens(_boughtWLCAmount / WLCRewardAmount);
            
            if (DCCAmount > 0) {
                _addTokensToAddress(_owner, DCCAmount);
                
                emit Buy(_owner, DCCAmount, nextTokenId - DCCAmount, nextTokenId - 1);
                
                chooseWinner();
                
                return _boughtWLCAmount - (DCCAmount * WLCRewardAmount);
            }
        }
        
        return _boughtWLCAmount;
    }
    
     
    function getForWLC(address _owner) public {
        require(WLCAdress == msg.sender, "You cannot invoke this function directly!");
        
        require(nextTokenId <= totalTokenSupply, "Not enough tokens are available for purchase!");
        
        _addTokensToAddress(_owner, 1);
        
        emit Buy(_owner, 1, nextTokenId - 1, nextTokenId - 1);
        
        chooseWinner();
    }
}
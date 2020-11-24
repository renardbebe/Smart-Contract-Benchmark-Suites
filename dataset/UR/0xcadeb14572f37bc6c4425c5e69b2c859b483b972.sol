 

pragma solidity ^0.4.24;

 
 
 
library ArtChainData {
    struct ArtItem {
        uint256 id;
        uint256 price;
        uint256 lastTransPrice;
        address owner;
        uint256 buyYibPrice;
        uint256 buyTime;
        uint256 annualRate;
        uint256 lockDuration;
        bool isExist;
    }

    struct Player {
        uint256 id;      
        address addr;    
        bytes32 name;    
        uint256 laffId;    

        uint256[] ownItemIds;
    }
}

contract ArtChainEvents {
     
     
     
     
     
     
     
     
     

    event onTransferItem
    (
        address from,
        address to,
        uint256 itemId,
        uint256 price,
        uint256 yibPrice,
        uint256 timeStamp
    );
}

contract ArtChain is ArtChainEvents {
    using SafeMath for *;
    using NameFilter for string;

    YbTokenInterface private YbTokenContract = YbTokenInterface(0x71F04062E5794e0190fDca9A2bF1F196C41C3e6e);

     
     
     
    address private ceo;
    
    string constant public name = "artChain";
    string constant public symbol = "artChain";  

     
     
     
    address private coo;

    bool public paused = false;

 

    uint256 public affPercentCut = 3;  

    uint256 pIdCount = 0;

     
     
     
    mapping(uint256 => ArtChainData.ArtItem) public artItemMap;
    uint256[] public itemIds;

    mapping (address => uint256) public pIDxAddr;          
    mapping (uint256 => ArtChainData.Player) public playerMap;    

     
     
     
    constructor() public {
        ceo = msg.sender;

        pIdCount++;
        playerMap[pIdCount].id = pIdCount;
        playerMap[pIdCount].addr = 0xe27c188521248a49adfc61090d3c8ab7c3754e0a;
        playerMap[pIdCount].name = "matt";
        pIDxAddr[0xe27c188521248a49adfc61090d3c8ab7c3754e0a] = pIdCount;
    }

     
     
     
    modifier onlyCeo() {
        require(msg.sender == ceo,"msg sender is not ceo");
        _;
    }

    modifier onlyCoo() {
        require(msg.sender == coo,"msg sender is not coo");
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == coo || msg.sender == ceo
            ,"msg sender is not c level"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
     
     
    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCeo whenPaused {
        paused = false;
    }

    function transferYbToNewContract(address _newAddr, uint256 _yibBalance) public onlyCeo {
        bool _isSuccess = YbTokenContract.transfer(_newAddr, _yibBalance);
    }

    function setYbContract(address _newAddr) public onlyCeo {
        YbTokenContract = YbTokenInterface(_newAddr);
    }

    function setCoo(address _newCoo) public onlyCeo {
        require(_newCoo != address(0));
        coo = _newCoo;
    }

 
 
 

    function addNewItem(uint256 _tokenId, uint256 _price, uint256 _annualRate, uint256 _lockDuration) public onlyCLevel {
        require(artItemMap[_tokenId].isExist == false);

        ArtChainData.ArtItem memory _item = ArtChainData.ArtItem({
            id: _tokenId,
            price: _price,
            lastTransPrice: 0,
            buyYibPrice: 0,
            buyTime: 0,
            annualRate: _annualRate,
            lockDuration: _lockDuration.mul(4 weeks),
            owner: this,
            isExist: true
        });
        itemIds.push(_tokenId);

        artItemMap[_tokenId] = _item;
    }

    function deleteItem(uint256 _tokenId) public onlyCLevel {
        require(artItemMap[_tokenId].isExist, "item not exist");

        for(uint256 i = 0; i < itemIds.length; i++) {
            if(itemIds[i] == _tokenId) {
                itemIds[i] = itemIds[itemIds.length - 1];
                break;
            }
        }
        itemIds.length --;
        delete artItemMap[_tokenId];
    }

    function setItemPrice(uint256 _tokenId, uint256 _price) public onlyCLevel {
        require(artItemMap[_tokenId].isExist == true);
         
        
        artItemMap[_tokenId].price = _price;
    }

    function setItemAnnualRate(uint256 _tokenId, uint256 _annualRate) public onlyCLevel {
        require(artItemMap[_tokenId].isExist == true);
         

        artItemMap[_tokenId].annualRate = _annualRate;
    }

    function setItemLockDuration(uint256 _tokenId, uint256 _lockDuration) public onlyCLevel {
        require(artItemMap[_tokenId].isExist == true);
         

        artItemMap[_tokenId].lockDuration = _lockDuration.mul(4 weeks);
    }

 
 
 
 
 
 
 
 

     
     
     
    function isPaused()
        public
        view
        returns (bool)
    {
        return paused;
    }

    function isItemExist(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return artItemMap[_tokenId].isExist;
    }

    function isItemSell(uint256 _tokenId) 
        public
        view
        returns (bool)
    {
        require(artItemMap[_tokenId].isExist == true, "item not exist");

        return artItemMap[_tokenId].owner != address(this);
    }

    function getItemPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(artItemMap[_tokenId].isExist == true, "item not exist");

        return artItemMap[_tokenId].price;
    }

    function getPlayerItems(uint256 _pId)
        public
        returns (uint256[])
    {
        require(_pId > 0 && _pId < pIdCount, "player not exist");
        return playerMap[_pId].ownItemIds;
    }

     
     
     
    function buyItem(address _buyer, uint256 _tokenId, uint256 _affCode)
        whenNotPaused()
        external
    {
        uint256 _pId = determinePID(_buyer, _affCode);

        require(artItemMap[_tokenId].isExist == true, "item not exist");
        require(isItemSell(_tokenId) == false, "item already sold");

        bool _isSuccess = YbTokenContract.transferFrom(_buyer, address(this), artItemMap[_tokenId].price);
        require(_isSuccess, "yb transfer from failed");

        artItemMap[_tokenId].owner = _buyer;
        artItemMap[_tokenId].lastTransPrice = artItemMap[_tokenId].price;

        artItemMap[_tokenId].buyYibPrice = YbTokenContract.getCurrentPrice();
        artItemMap[_tokenId].buyTime = now;

        playerMap[_pId].ownItemIds.push(_tokenId);

        if(playerMap[_pId].laffId != 0) {
            uint256 _affCut = (artItemMap[_tokenId].price).mul(affPercentCut).div(100);
            address _affAddr = playerMap[playerMap[_pId].laffId].addr;
            YbTokenContract.transfer(_affAddr, _affCut);
        }
        
        emit ArtChainEvents.onTransferItem ({
            from: this,
            to: _buyer,
            itemId: _tokenId,
            price: artItemMap[_tokenId].price,
            yibPrice: artItemMap[_tokenId].buyYibPrice,
            timeStamp: now
        });
    }

    function sellItem(uint256 _tokenId) 
        whenNotPaused()
        isHuman()
        public
    {
        require(artItemMap[_tokenId].isExist == true, "item not exist");
        require(artItemMap[_tokenId].owner == msg.sender,"player not own this item");
        require(artItemMap[_tokenId].buyTime + artItemMap[_tokenId].lockDuration <= now,"the item still lock");

        uint256 _sellPrice = (artItemMap[_tokenId].price).mul(artItemMap[_tokenId].annualRate).div(100).add(artItemMap[_tokenId].price);
        bool _isSuccess = YbTokenContract.transfer(msg.sender, _sellPrice);
        require(_isSuccess,"yb transfer failed");

        artItemMap[_tokenId].owner = this;
        artItemMap[_tokenId].lastTransPrice = artItemMap[_tokenId].price;

        removePlayerOwnItem(_tokenId);

        emit ArtChainEvents.onTransferItem ({
            from: msg.sender,
            to: this,
            itemId: _tokenId,
            price: artItemMap[_tokenId].price,
            yibPrice: artItemMap[_tokenId].buyYibPrice,
            timeStamp: now
        });
    }

    function removePlayerOwnItem(uint256 _tokenId)
        private
    {
        uint256 _pId = pIDxAddr[msg.sender];
        uint _itemIndex;
        bool _isFound = false;
        for (uint i = 0; i < playerMap[_pId].ownItemIds.length; i++) {
            if(playerMap[_pId].ownItemIds[i] == _tokenId)
            {
                _itemIndex = i;
                _isFound = true;
                break;
            }
        }
        if(_isFound) {
            playerMap[_pId].ownItemIds[_itemIndex] = playerMap[_pId].ownItemIds[playerMap[_pId].ownItemIds.length - 1];
            playerMap[_pId].ownItemIds.length--;
        }
    }

    function registerPlayer(string _nameString, uint256 _affCode) 
        whenNotPaused()
        isHuman()
        public
    {
        uint256 _pId = determinePID(msg.sender, _affCode);
        bytes32 _name = _nameString.nameFilter();
        playerMap[_pId].name = _name;
    }

     
     
     

    function determinePID(address _addr, uint256 _affCode)
        private
        returns(uint256)
    {
        if (pIDxAddr[_addr] == 0)
        {
            pIdCount++;
            pIDxAddr[_addr] = pIdCount;

            playerMap[pIdCount].id = pIdCount;
            playerMap[pIdCount].addr = _addr;
        } 
        uint256 _pId = pIDxAddr[_addr];
        playerMap[_pId].laffId = _affCode;
        return _pId;
    }

}

 
 
 
interface YbTokenInterface {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address addr) external view returns (uint256);
    function getCurrentPrice() external view returns (uint256);
}


library NameFilter {

    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

         
        bool _hasNonNumber;

         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);

                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 ||
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library SafeMath 
{
     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
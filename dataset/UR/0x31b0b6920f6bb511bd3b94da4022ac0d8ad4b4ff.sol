 

pragma solidity 0.5.10;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
contract IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transfer(address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}
contract Gacha is Ownable {
    struct item {
        uint256[] tokenIds; 
    }
    struct items { 
        mapping(address => item) items; 
        uint8 totalItem;
    }
     
    mapping(address => items) public awardDatas;

    event _setAward(address _from, address _game, uint256 tokenId);
    constructor() public {}
    function getTokenIdByIndex(address _game, uint8 _index) public view returns (uint256){
        return awardDatas[msg.sender].items[_game].tokenIds[_index];
    }
    function getGameBalance(address _game) public view returns (uint256){
        return awardDatas[msg.sender].items[_game].tokenIds.length;
    }
    function setAward(address _user, address _game, uint256 _tokenId) public onlyOwner{
        IERC721 erc721 = IERC721(_game);
        require(erc721.isApprovedForAll(erc721.ownerOf(_tokenId), address(this)));
        awardDatas[_user].items[_game].tokenIds.push(_tokenId);
        awardDatas[_user].totalItem +=1;
        emit _setAward(_user, _game, _tokenId);
    }

    function withdraw(address _game, uint256 _tokenId) public {
        IERC721 erc721 = IERC721(_game);
        require(erc721.isApprovedForAll(erc721.ownerOf(_tokenId), address(this)));
        require(checkowner(_game, _tokenId));
        erc721.transferFrom(erc721.ownerOf(_tokenId), msg.sender, _tokenId);
    }
    function checkowner(address _game, uint256 _tokenId) internal returns(bool) {
        bool valid;
        uint256[] storage ids = awardDatas[msg.sender].items[_game].tokenIds;
        for(uint8 i = 0; i< ids.length; i++){
            if(ids[i] == _tokenId) {
                valid = true;
                _burnArrayTokenId(_game, i);
            }
        }
        return valid;
    }
    function _burnArrayTokenId(address _game, uint256 index)  internal {
        if (index >= awardDatas[msg.sender].items[_game].tokenIds.length) return;

        for (uint i = index; i<awardDatas[msg.sender].items[_game].tokenIds.length-1; i++){
            awardDatas[msg.sender].items[_game].tokenIds[i] = awardDatas[msg.sender].items[_game].tokenIds[i+1];
        }
        delete awardDatas[msg.sender].items[_game].tokenIds[awardDatas[msg.sender].items[_game].tokenIds.length-1];
        awardDatas[msg.sender].items[_game].tokenIds.length--;
        awardDatas[msg.sender].totalItem -=1;
    }

}
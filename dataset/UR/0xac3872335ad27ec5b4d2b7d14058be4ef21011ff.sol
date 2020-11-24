 

 

 
 


pragma solidity ^0.4.24;


 
contract ERC721 {
     
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint);
     
    function ownerOf(uint256 _tokenId) public constant returns (address);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint);
     
    function tokenMetadata(uint256 _tokenId) public constant returns (string);
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

 

 
 


pragma solidity ^0.4.24;


 
contract EterArt is ERC721 {

     
    struct Art {
        uint256 price;
        address owner;
        address newOwner;
    }

    struct Token {
        uint256[] items;
        mapping(uint256 => uint) lookup;
    }

     
    mapping (address => Token) internal ownedTokens;

     
    uint256 public totalTokenSupply;

     
    address public _issuer;

     
    mapping (uint => Art) public registry;

     
    string public baseInfoUrl = "https://www.eterart.com/art/";

     
    uint public feePercent = 5;

     
    constructor() public {
        _issuer = msg.sender;
    }

     
    function issuer() public view returns(address) {
        return _issuer;
    }

     
    function() external payable {
        require(msg.sender == address(this));
    }

     
    function name() public constant returns (string) {
        return "EterArt";
    }

     
    function symbol() public constant returns (string) {
        return "WAW";
    }

     
    function tokenMetadata(uint256 _tokenId) public constant returns (string) {
        return strConcat(baseInfoUrl, strConcat("0x", uint2hexstr(_tokenId)));
    }

     
    function totalSupply() public constant returns (uint256) {
        return totalTokenSupply;
    }

     
    function balanceOf(address _owner) public constant returns (uint balance) {
        balance = ownedTokens[_owner].items.length;
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId) {
        tokenId = ownedTokens[_owner].items[_index];
    }

     
    function approve(address _to, uint256 _tokenId) public {
        require(_to != msg.sender);
        require(registry[_tokenId].owner == msg.sender);
        registry[_tokenId].newOwner = _to;
        emit Approval(registry[_tokenId].owner, _to, _tokenId);
    }

     
    function _transfer(address _to, uint256 _tokenId) internal {
        if (registry[_tokenId].owner != address(0)) {
            require(registry[_tokenId].owner != _to);
            removeByValue(registry[_tokenId].owner, _tokenId);
        }
        else {
            totalTokenSupply = totalTokenSupply + 1;
        }

        require(_to != address(0));

        push(_to, _tokenId);
        emit Transfer(registry[_tokenId].owner, _to, _tokenId);
        registry[_tokenId].owner = _to;
        registry[_tokenId].newOwner = address(0);
        registry[_tokenId].price = 0;
    }

     
    function takeOwnership(uint256 _tokenId) public {
        require(registry[_tokenId].newOwner == msg.sender);
        _transfer(msg.sender, _tokenId);
    }

     
    function changeBaseInfoUrl(string url) public {
        require(msg.sender == _issuer);
        baseInfoUrl = url;
    }

     
    function changeIssuer(address _to) public {
        require(msg.sender == _issuer);
        _issuer = _to;
    }

     
    function withdraw() public {
        require(msg.sender == _issuer);
        withdraw(_issuer, address(this).balance);
    }

     
    function withdraw(address _to) public {
        require(msg.sender == _issuer);
        withdraw(_to, address(this).balance);
    }

     
    function withdraw(address _to, uint _value) public {
        require(msg.sender == _issuer);
        require(_value <= address(this).balance);
        _to.transfer(address(this).balance);
    }

     
    function ownerOf(uint256 token) public constant returns (address owner) {
        owner = registry[token].owner;
    }

     
    function getPrice(uint token) public view returns (uint) {
        return registry[token].price;
    }

     
    function transfer(address _to, uint256 _tokenId) public {
        require(registry[_tokenId].owner == msg.sender);
        _transfer(_to, _tokenId);
    }

     
    function changePrice(uint token, uint price) public {
        require(registry[token].owner == msg.sender);
        registry[token].price = price;
    }

     
    function buy(uint _tokenId) public payable {
        require(registry[_tokenId].price > 0);

        uint calcedFee = ((registry[_tokenId].price / 100) * feePercent);
        uint value = msg.value - calcedFee;

        require(registry[_tokenId].price <= value);
        registry[_tokenId].owner.transfer(value);
        _transfer(msg.sender, _tokenId);
    }

     
    function mint(uint _tokenId, address _to) public {
        require(msg.sender == _issuer);
        require(registry[_tokenId].owner == 0x0);
        _transfer(_to, _tokenId);
    }

     
    function mint(
        string length,
        uint _tokenId,
        uint price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {

        string memory m_price = uint2hexstr(price);
        string memory m_token = uint2hexstr(_tokenId);

        require(msg.value >= price);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n", length, m_token, m_price), v, r, s) == _issuer);
        require(registry[_tokenId].owner == 0x0);
        _transfer(msg.sender, _tokenId);
    }

     

     
    function push(address owner, uint value) private {

        if (ownedTokens[owner].lookup[value] > 0) {
            return;
        }
        ownedTokens[owner].lookup[value] = ownedTokens[owner].items.push(value);
    }

     
    function removeByValue(address owner, uint value) private {
        uint index = ownedTokens[owner].lookup[value];
        if (index == 0) {
            return;
        }
        if (index < ownedTokens[owner].items.length) {
            uint256 lastItem = ownedTokens[owner].items[ownedTokens[owner].items.length - 1];
            ownedTokens[owner].items[index - 1] = lastItem;
            ownedTokens[owner].lookup[lastItem] = index;
        }
        ownedTokens[owner].items.length -= 1;
        delete ownedTokens[owner].lookup[value];
    }


     
    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];

        return string(babcde);
    }

     
    function uint2hexstr(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(55 + curr) : byte(48 + curr);  
            i = i >> 4;
        }

        return string(bstr);
    }

}
 

pragma solidity ^0.4.18;


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



contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}



contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}





contract CommonEth {

     
    enum  Modes {LIVE, TEST}

     
    Modes public mode = Modes.LIVE;

     
    address internal ceoAddress;
    address internal cfoAddress;
    address internal cooAddress;


    address public newContractAddress;

    event ContractUpgrade(address newContract);

    function setNewAddress(address _v2Address) external onlyCEO {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }


     
    function CommonEth() public {
        ceoAddress = msg.sender;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyStaff() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

    modifier onlyManger() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyLiveMode() {
        require(mode == Modes.LIVE || msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        _;
    }

     
    function staffInfo() public view onlyStaff returns (bool ceo, bool coo, bool cfo, bool qa){
        return (msg.sender == ceoAddress, msg.sender == cooAddress, msg.sender == cfoAddress,false);
    }


     
    function stopLive() public onlyCOO {
        mode = Modes.TEST;
    }

     
    function startLive() public onlyCOO {
        mode = Modes.LIVE;
    }

    function getMangers() public view onlyManger returns (address _ceoAddress, address _cooAddress, address _cfoAddress){
        return (ceoAddress, cooAddress, cfoAddress);
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }



}



contract NFToken is ERC721Token, CommonEth {
     
    struct TokenModel {
        uint id; 
        string serial; 
        uint createTime;
        uint price; 
        uint lastTime;
        uint openTime;
    }

     
    mapping(uint => TokenModel)  tokens;
    mapping(string => uint)  idOfSerial;

     
    uint RISE_RATE = 110;
    uint RISE_RATE_FAST = 150;
     
    uint8 SALE_FEE_RATE = 2;

     
    uint CARVE_UP_INPUT = 0.01 ether;
     
    uint[10] carveUpTokens = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint8 carverUpIndex = 0;

    function NFToken() {
        setCFO(msg.sender);
        setCOO(msg.sender);
    }

     
    function() external payable {

    }

     
    event TransferBonus(address indexed _to, uint256 _tokenId, uint _bonus);
     
    event UnsoldUpdate(uint256 indexed _tokenId, uint price, uint openTime);
     
    event JoinCarveUp(address indexed _account, uint _tokenId, uint _input);
     
    event CarveUpBonus(address indexed _account, uint _tokenId, uint _bonus);
     

     
    function joinCarveUpTen(uint _tokenId) public payable onlyLiveMode onlyOwnerOf(_tokenId) returns (bool){
         
        require(msg.value == CARVE_UP_INPUT);
         
        for (uint8 i = 0; i < carverUpIndex; i++) {
            require(carveUpTokens[i] != _tokenId);
        }
         
        carveUpTokens[carverUpIndex] = _tokenId;

         
        JoinCarveUp(msg.sender, _tokenId, msg.value);
         
        if (carverUpIndex % 10 == 9) {
             
            carverUpIndex = 0;
            uint theLoserIndex = (now % 10 + (now / 10 % 10) + (now / 100 % 10) + (now / 1000 % 10)) % 10;
            for (uint8 j = 0; j < 10; j++) {
                if (j != theLoserIndex) {
                    uint bonus = CARVE_UP_INPUT * 110 / 100;
                    ownerOf(carveUpTokens[j]).transfer(bonus);
                    CarveUpBonus(ownerOf(carveUpTokens[j]), carveUpTokens[j], bonus);
                }else{
                    CarveUpBonus(ownerOf(carveUpTokens[j]), carveUpTokens[j], 0);
                }
            }
             
             
            carveUpTokens = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        } else {
            carverUpIndex++;
        }
        return true;
    }

     
    function buy(uint _id) public payable onlyLiveMode returns (bool){
        TokenModel storage token = tokens[_id];
        require(token.price != 0);
        require(token.openTime < now);
         
        require(msg.value >= token.price);
         
        ownerOf(_id).transfer(token.price * (100 - 2 * SALE_FEE_RATE) / 100);
         
        if (totalSupply() > 1) {
            uint bonus = token.price * SALE_FEE_RATE / 100 / (totalSupply() - 1);
            for (uint i = 1; i <= totalSupply(); i++) {
                if (i != _id) {
                    ownerOf(i).transfer(bonus);
                    TransferBonus(ownerOf(i), i, bonus);
                }
            }
        }
         
        clearApprovalAndTransfer(ownerOf(_id), msg.sender, _id);
         
        if (token.price < 1 ether) {
            token.price = token.price * RISE_RATE_FAST / 100;
        } else {
            token.price = token.price * RISE_RATE / 100;
        }
        token.lastTime = now;
        return true;
    }

     
    function createByCOO(string serial, uint price, uint openTime) public onlyCOO returns (uint){
        uint currentTime = now;
        return __createNewToken(this, serial, currentTime, price, currentTime, openTime).id;
    }

     
    function updateUnsold(string serial, uint _price, uint _openTime) public onlyCOO returns (bool){
        require(idOfSerial[serial] > 0);
        TokenModel storage token = tokens[idOfSerial[serial]];
        require(token.lastTime == token.createTime);
        token.price = _price;
        token.openTime = _openTime;
        UnsoldUpdate(token.id, token.price, token.openTime);
        return true;
    }

     
    function __createNewToken(address _to, string serial, uint createTime, uint price, uint lastTime, uint openTime) private returns (TokenModel){
        require(price > 0);
        require(idOfSerial[serial] == 0);
        uint id = totalSupply() + 1;
        idOfSerial[serial] = id;
        TokenModel memory s = TokenModel(id, serial, createTime, price, lastTime, openTime);
        tokens[id] = s;
        _mint(_to, id);
        return s;
    }

     
    function getTokenById(uint _id) public view returns (uint id, string serial, uint createTime, uint price, uint lastTime, uint openTime, address owner)
    {
        return (tokens[_id].id, tokens[_id].serial, tokens[_id].createTime, tokens[_id].price, tokens[_id].lastTime, tokens[_id].openTime, ownerOf(_id));
    }

     
    function getCarveUpTokens() public view returns (uint[10]){
        return carveUpTokens;
    }

     
    function withdrawContractEther(uint withdrawAmount) public onlyCFO {
        uint256 balance = this.balance;
        require(balance - carverUpIndex * CARVE_UP_INPUT > withdrawAmount);
        cfoAddress.transfer(withdrawAmount);
    }

     
    function withdrawAbleEther() public view onlyCFO returns (uint){
        return this.balance - carverUpIndex * CARVE_UP_INPUT;
    }
}
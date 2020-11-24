 

pragma solidity ^0.4.13;

contract SplitPayment {
  using SafeMath for uint256;

  uint256 public totalShares = 0;
  uint256 public totalReleased = 0;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;

   
  function SplitPayment(address[] _payees, uint256[] _shares) public payable {
    require(_payees.length == _shares.length);

    for (uint256 i = 0; i < _payees.length; i++) {
      addPayee(_payees[i], _shares[i]);
    }
  }

   
  function () public payable {}

   
  function claim() public {
    address payee = msg.sender;

    require(shares[payee] > 0);

    uint256 totalReceived = this.balance.add(totalReleased);
    uint256 payment = totalReceived.mul(shares[payee]).div(totalShares).sub(released[payee]);

    require(payment != 0);
    require(this.balance >= payment);

    released[payee] = released[payee].add(payment);
    totalReleased = totalReleased.add(payment);

    payee.transfer(payment);
  }

   
  function addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[_payee] == 0);

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
  }
}

interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
	
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract CorsariumAccessControl is SplitPayment {
 
   
    event ContractUpgrade(address newContract);

     
    address public megoAddress = 0x4ab6C984E72CbaB4162429721839d72B188010E3;
    address public publisherAddress = 0x00C0bCa70EAaADF21A158141EC7eA699a17D63ed;
     
    address[] public teamAddresses = [0x4978FaF663A3F1A6c74ACCCCBd63294Efec64624, 0x772009E69B051879E1a5255D9af00723df9A6E04, 0xA464b05832a72a1a47Ace2Be18635E3a4c9a240A, 0xd450fCBfbB75CDAeB65693849A6EFF0c2976026F, 0xd129BBF705dC91F50C5d9B44749507f458a733C8, 0xfDC2ad68fd1EF5341a442d0E2fC8b974E273AC16, 0x4ab6C984E72CbaB4162429721839d72B188010E3];
     

     
    bool public paused = false;

    modifier onlyTeam() {
        require(msg.sender == teamAddresses[0] || msg.sender == teamAddresses[1] || msg.sender == teamAddresses[2] || msg.sender == teamAddresses[3] || msg.sender == teamAddresses[4] || msg.sender == teamAddresses[5] || msg.sender == teamAddresses[6] || msg.sender == teamAddresses[7]);
        _;  
    }

    modifier onlyPublisher() {
        require(msg.sender == publisherAddress);
        _;
    }

    modifier onlyMEGO() {
        require(msg.sender == megoAddress);
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

    function CorsariumAccessControl() public {
        megoAddress = msg.sender;
    }

     
     
    function pause() external onlyTeam whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyMEGO whenPaused {
         
        paused = false;
    }

}

contract CardBase is CorsariumAccessControl, ERC721, ERC721Metadata {

     

     
    event Print(address owner, uint256 cardId);
    
    uint256 lastPrintedCard = 0;
     
    mapping (uint256 => address) public tokenIdToOwner;   
    mapping (address => uint256) public ownerTokenCount;  
    mapping (uint256 => address) public tokenIdToApproved;  
    mapping (uint256 => uint256) public tokenToCardIndex;  
     
     
     

     
     
    
    function _createCard(uint256 _prototypeId, address _owner) internal returns (uint) {

         
         
        require(uint256(1000000) > lastPrintedCard);
        lastPrintedCard++;
        tokenToCardIndex[lastPrintedCard] = _prototypeId;
        _setTokenOwner(lastPrintedCard, _owner);
         
        Transfer(0, _owner, lastPrintedCard);
         
        
         
        

        return lastPrintedCard;
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId) internal {
        _clearTokenApproval(_tokenId);
         
        ownerTokenCount[_from]--;
        _setTokenOwner(_tokenId, _to);
         
    }

    function _ownerOf(uint _tokenId) internal view returns (address _owner) {
        return tokenIdToOwner[_tokenId];
    }

    function _approve(address _to, uint _tokenId) internal {
        tokenIdToApproved[_tokenId] = _to;
    }

    function _getApproved(uint _tokenId) internal view returns (address _approved) {
        return tokenIdToApproved[_tokenId];
    }

    function _clearTokenApproval(uint _tokenId) internal {
        tokenIdToApproved[_tokenId] = address(0);
    }

    function _setTokenOwner(uint _tokenId, address _owner) internal {
        tokenIdToOwner[_tokenId] = _owner;
        ownerTokenCount[_owner]++;
    }

}

contract CardOwnership is CardBase {
     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return ownerTokenCount[_owner];
    }

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = tokenIdToOwner[_tokenId];
        require(_owner != address(0));
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 value = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);

            if (value != bytes4(keccak256("onERC721Received(address,uint256,bytes)"))) {
                revert();
            }
        }
    }
	
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 value = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, "");

            if (value != bytes4(keccak256("onERC721Received(address,uint256,bytes)"))) {
                revert();
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable {
        require(msg.sender == _ownerOf(_tokenId));
        require(msg.sender != _approved);
        
        if (_getApproved(_tokenId) != address(0) || _approved != address(0)) {
            _approve(_approved, _tokenId);
            Approval(msg.sender, _approved, _tokenId);
        }
    }

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external {
        revert();
    }

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address) {
        return _getApproved(_tokenId);
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _owner == _operator;
    }

     
    function name() external pure returns (string _name) {
        return "Dark Winds First Edition Cards";
    }

     
    function symbol() external pure returns (string _symbol) {
        return "DW1ST";
    }

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string _tokenURI) {
        _tokenURI = "https://corsarium.playdarkwinds.com/cards/00000.json";  
        bytes memory tokenUriBytes = bytes(_tokenURI);
        tokenUriBytes[33] = byte(48 + (tokenToCardIndex[_tokenId] / 10000) % 10);
        tokenUriBytes[34] = byte(48 + (tokenToCardIndex[_tokenId] / 1000) % 10);
        tokenUriBytes[35] = byte(48 + (tokenToCardIndex[_tokenId] / 100) % 10);
        tokenUriBytes[36] = byte(48 + (tokenToCardIndex[_tokenId] / 10) % 10);
        tokenUriBytes[37] = byte(48 + (tokenToCardIndex[_tokenId] / 1) % 10);
    }

    function totalSupply() public view returns (uint256 _total) {
        _total = lastPrintedCard;
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { 
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

contract CorsariumCore is CardOwnership {

    uint256 nonce = 1;
    uint256 public cardCost = 1 finney;

    function CorsariumCore(address[] _payees, uint256[] _shares) SplitPayment(_payees, _shares) public {

    }

     
    function () public payable {}

    function changeCardCost(uint256 _newCost) onlyTeam public {
        cardCost = _newCost;
    }

    function getCard(uint _token_id) public view returns (uint256) {
        assert(_token_id <= lastPrintedCard);
        return tokenToCardIndex[_token_id];
    }

    function buyBoosterPack() public payable {
        uint amount = msg.value/cardCost;
        uint blockNumber = block.timestamp;
        for (uint i = 0; i < amount; i++) {
            _createCard(i%5 == 1 ? (uint256(keccak256(i+nonce+blockNumber)) % 50) : (uint256(keccak256(i+nonce+blockNumber)) % 50) + (nonce%50), msg.sender);
        }
        nonce += amount;

    }
    
    function cardsOfOwner(address _owner) external view returns (uint256[] ownerCards) {
        uint256 tokenCount = ownerTokenCount[_owner];

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

             
             
            uint256 cardId;

            for (cardId = 1; cardId <= lastPrintedCard; cardId++) {
                if (tokenIdToOwner[cardId] == _owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] ownerCards) {
        uint256 tokenCount = ownerTokenCount[_owner];

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

             
             
            uint256 cardId;

            for (cardId = 1; cardId <= lastPrintedCard; cardId++) {
                if (tokenIdToOwner[cardId] == _owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function cardSupply() external view returns (uint256[] printedCards) {

        if (totalSupply() == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](100);
             
             

             
             
            uint256 cardId;

            for (cardId = 1; cardId < 1000000; cardId++) {
                result[tokenToCardIndex[cardId]]++;
                 
            }

            return result;
        }
    }
    
}

interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}